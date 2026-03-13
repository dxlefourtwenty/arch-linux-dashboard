#include "systeminfo.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <sys/statvfs.h>
#include <QTimer>

SystemInfo::SystemInfo(QObject *parent)
  : QObject(parent)
{
  setupGpu();

  connect(&timer, &QTimer::timeout, this, [this]() {
      updateCpu();
      updateRam();
      updateDisk();
  });

  timer.start(1000);
}

void SystemInfo::updateCpu()
{
    QFile file("/proc/stat");
    if (!file.open(QIODevice::ReadOnly))
        return;

    QByteArray line = file.readLine();
    QList<QByteArray> parts = line.simplified().split(' ');

    long long user = parts[1].toLongLong();
    long long nice = parts[2].toLongLong();
    long long system = parts[3].toLongLong();
    long long idle = parts[4].toLongLong();

    long long total = user + nice + system + idle;

    long long totalDiff = total - lastTotal;
    long long idleDiff = idle - lastIdle;

    if (totalDiff > 0) {
        int usage = 100 * (totalDiff - idleDiff) / totalDiff;
        if (usage != m_cpu) {
            m_cpu = usage;
            emit cpuUsageChanged();
        }
    }

    lastTotal = total;
    lastIdle = idle;
}

void SystemInfo::updateRam()
{
    QFile file("/proc/meminfo");
    if (!file.open(QIODevice::ReadOnly))
        return;

    const QByteArray content = file.readAll();  // ← read everything at once
    
    long total = 0, available = 0;
    for (const QByteArray &line : content.split('\n')) {
        if (line.startsWith("MemTotal"))
            total = line.split(':')[1].simplified().split(' ')[0].toLong();
        if (line.startsWith("MemAvailable"))
            available = line.split(':')[1].simplified().split(' ')[0].toLong();
    }

    qDebug() << "RAM total:" << total << "available:" << available;
    if (total == 0) return;
    int used = 100 - ((available * 100) / total);
    if (used != m_ram) { m_ram = used; emit ramUsageChanged(); }
}

void SystemInfo::updateDisk()
{
    struct statvfs stat{};
    if (statvfs("/", &stat) != 0)
        return;
    unsigned long total = stat.f_blocks * stat.f_frsize;
    unsigned long free  = stat.f_bavail * stat.f_frsize;
    if (total == 0) return;  // ← guard
    int used = 100 - (free * 100 / total);
    if (used != m_disk) { m_disk = used; emit diskUsageChanged(); }
}

void SystemInfo::setupGpu()
{
    gpuProc.start("intel_gpu_top", {"-J", "-s", "1000"});

    connect(&gpuProc, &QProcess::readyReadStandardOutput, this, [this]() {
        gpuBuffer += gpuProc.readAllStandardOutput();

        // find complete top-level JSON objects by tracking brace depth
        int depth = 0, start = -1;
        for (int i = 0; i < gpuBuffer.size(); i++) {
            if (gpuBuffer[i] == '{') {
                if (depth++ == 0) start = i;
            } else if (gpuBuffer[i] == '}') {
                if (--depth == 0 && start != -1) {
                    QByteArray chunk = gpuBuffer.mid(start, i - start + 1);
                    gpuBuffer = gpuBuffer.mid(i + 1);
                    i = -1; // restart scan

                    auto doc = QJsonDocument::fromJson(chunk);
                    if (!doc.isObject()) continue;

                    auto engines = doc.object()["engines"].toObject();
                    if (!engines.contains("Render/3D")) continue;

                    double usage = engines["Render/3D"]
                                   .toObject()["busy"]
                                   .toDouble();
                    int iUsage = qRound(usage);
                    if (iUsage != m_gpu) {
                        m_gpu = iUsage;
                        emit gpuUsageChanged();
                    }
                }
            }
        }
    });
}
