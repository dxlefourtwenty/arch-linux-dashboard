#pragma once

#include <QObject>
#include <QProcess>
#include <QTimer>

class SystemInfo : public QObject {
    Q_OBJECT

    Q_PROPERTY(int cpuUsage READ cpuUsage NOTIFY cpuUsageChanged)
    Q_PROPERTY(int gpuUsage READ gpuUsage NOTIFY gpuUsageChanged)
    Q_PROPERTY(int ramUsage READ ramUsage NOTIFY ramUsageChanged)
    Q_PROPERTY(int diskUsage READ diskUsage NOTIFY diskUsageChanged)

public:
    explicit SystemInfo(QObject *parent = nullptr);

    int cpuUsage() const { return m_cpu; }
    int gpuUsage() const { return m_gpu; }
    int ramUsage() const { return m_ram; }
    int diskUsage() const { return m_disk; }

signals:
    void cpuUsageChanged();
    void gpuUsageChanged();
    void ramUsageChanged();
    void diskUsageChanged();

private:
    void updateCpu();
    void updateRam();
    void updateDisk();
    void setupGpu();

    QTimer timer;
    QProcess gpuProc;
    QByteArray gpuBuffer; 

    int m_cpu = 0;
    int m_gpu = 0;
    int m_ram = 0;
    int m_disk = 0;

    long long lastIdle = 0;
    long long lastTotal = 0;
};
