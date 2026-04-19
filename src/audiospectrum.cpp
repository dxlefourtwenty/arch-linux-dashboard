#include "audiospectrum.h"

#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QTemporaryFile>
#include <QTextStream>

#include <cmath>

namespace {
constexpr const char *kCavaBin = "/usr/bin/cava";
constexpr int kMinBars = 4;
constexpr int kMaxBars = 256;
constexpr int kMinFrameRate = 20;
constexpr int kMaxFrameRate = 120;
constexpr int kRestartDelayMs = 900;
constexpr int kFrameByteRange = 255;
constexpr double kLevelEpsilon = 0.003;
}

AudioSpectrum::AudioSpectrum(QObject *parent)
    : QObject(parent)
{
    m_cavaPath = resolveCavaPath();
    m_available = !m_cavaPath.isEmpty();

    m_restartTimer.setSingleShot(true);
    connect(&m_restartTimer, &QTimer::timeout, this, [this]() {
        start();
    });

    connect(&m_process, &QProcess::readyReadStandardOutput, this, &AudioSpectrum::handleReadyRead);
    connect(&m_process, &QProcess::readyReadStandardError, this, [this]() {
        m_process.readAllStandardError();
    });
    connect(&m_process, &QProcess::finished, this, [this](int, QProcess::ExitStatus) {
        scheduleRestart(kRestartDelayMs);
    });
    connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            const bool wasAvailable = m_available;
            m_cavaPath.clear();
            m_available = false;
            if (wasAvailable != m_available) {
                emit availableChanged();
            }
        }
        scheduleRestart(kRestartDelayMs);
    });

    resetLevels();
}

void AudioSpectrum::setRunning(bool running)
{
    if (m_running == running) {
        return;
    }

    m_running = running;
    emit runningChanged();

    if (m_running) {
        start();
        return;
    }

    stop();
}

void AudioSpectrum::setBarCount(int count)
{
    const int nextBarCount = qBound(kMinBars, count, kMaxBars);
    if (m_barCount == nextBarCount) {
        return;
    }

    m_barCount = nextBarCount;
    emit barCountChanged();
    resetLevels();
    restart();
}

void AudioSpectrum::setFrameRate(int rate)
{
    const int nextFrameRate = qBound(kMinFrameRate, rate, kMaxFrameRate);
    if (m_frameRate == nextFrameRate) {
        return;
    }

    m_frameRate = nextFrameRate;
    emit frameRateChanged();
    restart();
}

void AudioSpectrum::start()
{
    if (!m_running || !m_available) {
        return;
    }

    if (m_process.state() != QProcess::NotRunning) {
        return;
    }

    if (m_cavaPath.isEmpty()) {
        m_cavaPath = resolveCavaPath();
        const bool nextAvailable = !m_cavaPath.isEmpty();
        if (m_available != nextAvailable) {
            m_available = nextAvailable;
            emit availableChanged();
        }
        if (!m_available) {
            return;
        }
    }

    const QString configPath = writeConfigFile();
    if (configPath.isEmpty()) {
        return;
    }

    m_outputBuffer.clear();
    m_process.setProgram(m_cavaPath);
    m_process.setArguments({"-p", configPath});
    m_process.start(QIODevice::ReadOnly);
}

void AudioSpectrum::stop()
{
    m_restartTimer.stop();
    m_outputBuffer.clear();

    if (m_process.state() != QProcess::NotRunning) {
        m_process.terminate();
        if (!m_process.waitForFinished(120)) {
            m_process.kill();
            m_process.waitForFinished(120);
        }
    }

    resetLevels();
}

void AudioSpectrum::restart()
{
    if (!m_running) {
        return;
    }

    stop();
    start();
}

void AudioSpectrum::scheduleRestart(int delayMs)
{
    if (!m_running || !m_available) {
        return;
    }

    m_restartTimer.start(qMax(0, delayMs));
}

void AudioSpectrum::resetLevels()
{
    const int targetSize = qMax(kMinBars, m_barCount);
    bool changed = m_levels.size() != targetSize;

    if (m_levels.size() != targetSize) {
        m_levels = QVariantList(targetSize, 0.0);
        emit levelsChanged();
        return;
    }

    for (int i = 0; i < targetSize; ++i) {
        if (m_levels.at(i).toDouble() != 0.0) {
            m_levels[i] = 0.0;
            changed = true;
        }
    }

    if (changed) {
        emit levelsChanged();
    }
}

void AudioSpectrum::handleReadyRead()
{
    if (m_barCount <= 0) {
        m_process.readAllStandardOutput();
        return;
    }

    m_outputBuffer.append(m_process.readAllStandardOutput());

    const int frameSize = m_barCount;
    const int fullFrameBytes = (m_outputBuffer.size() / frameSize) * frameSize;
    if (fullFrameBytes < frameSize) {
        return;
    }

    const int lastFrameStart = fullFrameBytes - frameSize;
    applyFrame(m_outputBuffer.constData() + lastFrameStart, frameSize);
    m_outputBuffer.remove(0, fullFrameBytes);
}

void AudioSpectrum::applyFrame(const char *frameData, int frameSize)
{
    if (frameData == nullptr || frameSize <= 0) {
        return;
    }

    if (m_levels.size() != frameSize) {
        m_levels = QVariantList(frameSize, 0.0);
    }

    bool changed = false;
    for (int i = 0; i < frameSize; ++i) {
        const unsigned char raw = static_cast<unsigned char>(frameData[i]);
        const double normalized = static_cast<double>(raw) / static_cast<double>(kFrameByteRange);
        const double previous = m_levels.at(i).toDouble();
        if (std::abs(previous - normalized) < kLevelEpsilon) {
            continue;
        }

        m_levels[i] = normalized;
        changed = true;
    }

    if (changed) {
        emit levelsChanged();
    }
}

QString AudioSpectrum::resolveCavaPath() const
{
    if (QFileInfo::exists(kCavaBin) && QFileInfo(kCavaBin).isExecutable()) {
        return QString::fromUtf8(kCavaBin);
    }

    return QStandardPaths::findExecutable("cava");
}

QString AudioSpectrum::writeConfigFile()
{
    auto file = std::make_unique<QTemporaryFile>(QDir::tempPath() + "/topdash-cava-XXXXXX.conf");
    if (!file->open()) {
        return {};
    }

    QTextStream out(file.get());
    out << "[general]\n";
    out << "bars = " << m_barCount << "\n";
    out << "framerate = " << m_frameRate << "\n";
    out << "autosens = 1\n";
    out << "sensitivity = 100\n\n";

    out << "[input]\n";
    out << "method = pulse\n";
    out << "source = auto\n\n";

    out << "[output]\n";
    out << "method = raw\n";
    out << "raw_target = /dev/stdout\n";
    out << "data_format = binary\n";
    out << "bit_format = 8bit\n";
    out << "channels = mono\n";
    out.flush();

    const QString path = file->fileName();
    file->close();
    m_configFile = std::move(file);
    return path;
}
