#pragma once

#include <QByteArray>
#include <QProcess>
#include <QTemporaryFile>
#include <QTimer>
#include <QVariantList>
#include <QObject>

#include <memory>

class AudioSpectrum : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList levels READ levels NOTIFY levelsChanged)
    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)
    Q_PROPERTY(int barCount READ barCount WRITE setBarCount NOTIFY barCountChanged)
    Q_PROPERTY(int frameRate READ frameRate WRITE setFrameRate NOTIFY frameRateChanged)
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)

public:
    explicit AudioSpectrum(QObject *parent = nullptr);

    QVariantList levels() const { return m_levels; }
    bool running() const { return m_running; }
    int barCount() const { return m_barCount; }
    int frameRate() const { return m_frameRate; }
    bool available() const { return m_available; }

public slots:
    void setRunning(bool running);
    void setBarCount(int count);
    void setFrameRate(int rate);

signals:
    void levelsChanged();
    void runningChanged();
    void barCountChanged();
    void frameRateChanged();
    void availableChanged();

private:
    void start();
    void stop();
    void restart();
    void scheduleRestart(int delayMs);
    void resetLevels();
    void handleReadyRead();
    void applyFrame(const char *frameData, int frameSize);
    QString resolveCavaPath() const;
    QString writeConfigFile();

    QVariantList m_levels;
    QProcess m_process;
    QTimer m_restartTimer;
    std::unique_ptr<QTemporaryFile> m_configFile;
    QByteArray m_outputBuffer;

    QString m_cavaPath;
    bool m_running = false;
    int m_barCount = 32;
    int m_frameRate = 60;
    bool m_available = false;
};
