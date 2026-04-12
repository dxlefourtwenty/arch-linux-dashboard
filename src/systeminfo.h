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
    Q_PROPERTY(QString cpuName READ cpuName NOTIFY cpuNameChanged)
    Q_PROPERTY(QString gpuName READ gpuName NOTIFY gpuNameChanged)
    Q_PROPERTY(double ramUsedGiB READ ramUsedGiB NOTIFY ramTotalsChanged)
    Q_PROPERTY(double ramTotalGiB READ ramTotalGiB NOTIFY ramTotalsChanged)
    Q_PROPERTY(double diskUsedGiB READ diskUsedGiB NOTIFY diskTotalsChanged)
    Q_PROPERTY(double diskTotalGiB READ diskTotalGiB NOTIFY diskTotalsChanged)
    Q_PROPERTY(QString diskName READ diskName NOTIFY diskNameChanged)
    Q_PROPERTY(double networkDownBps READ networkDownBps NOTIFY networkChanged)
    Q_PROPERTY(double networkUpBps READ networkUpBps NOTIFY networkChanged)
    Q_PROPERTY(int batteryPercent READ batteryPercent NOTIFY batteryPercentChanged)
    Q_PROPERTY(QString osName READ osName NOTIFY osNameChanged)
    Q_PROPERTY(QString deName READ deName NOTIFY deNameChanged)
    Q_PROPERTY(QString themeName READ themeName NOTIFY themeNameChanged)
    Q_PROPERTY(QString uptimeText READ uptimeText NOTIFY uptimeTextChanged)

public:
    explicit SystemInfo(QObject *parent = nullptr);

    int cpuUsage() const { return m_cpu; }
    int gpuUsage() const { return m_gpu; }
    int ramUsage() const { return m_ram; }
    int diskUsage() const { return m_disk; }
    QString cpuName() const { return m_cpuName; }
    QString gpuName() const { return m_gpuName; }
    double ramUsedGiB() const { return m_ramUsedGiB; }
    double ramTotalGiB() const { return m_ramTotalGiB; }
    double diskUsedGiB() const { return m_diskUsedGiB; }
    double diskTotalGiB() const { return m_diskTotalGiB; }
    QString diskName() const { return m_diskName; }
    double networkDownBps() const { return m_networkDownBps; }
    double networkUpBps() const { return m_networkUpBps; }
    int batteryPercent() const { return m_batteryPercent; }
    QString osName() const { return m_osName; }
    QString deName() const { return m_deName; }
    QString themeName() const { return m_themeName; }
    QString uptimeText() const { return m_uptimeText; }

signals:
    void cpuUsageChanged();
    void gpuUsageChanged();
    void ramUsageChanged();
    void diskUsageChanged();
    void cpuNameChanged();
    void gpuNameChanged();
    void ramTotalsChanged();
    void diskTotalsChanged();
    void diskNameChanged();
    void networkChanged();
    void batteryPercentChanged();
    void osNameChanged();
    void deNameChanged();
    void themeNameChanged();
    void uptimeTextChanged();

private:
    void updateCpu();
    void updateGpu();
    void updateRam();
    void updateDisk();
    void updateNetwork();
    void updateBattery();
    void updateDesktopEnvironment();
    void updateThemeName();
    void updateUptime();
    QString primaryNetworkInterface() const;
    bool readInterfaceBytes(const QString &iface, quint64 &rxBytes, quint64 &txBytes) const;
    void setupGpu();
    void loadCpuName();
    void loadGpuName();
    void loadOsName();
    void loadDiskName();

    QTimer timer;
    QProcess gpuProc;

    int m_cpu = 0;
    int m_gpu = 0;
    int m_ram = 0;
    int m_disk = 0;
    QString m_cpuName = "Unknown CPU";
    QString m_gpuName = "Unknown GPU";
    double m_ramUsedGiB = 0.0;
    double m_ramTotalGiB = 0.0;
    double m_diskUsedGiB = 0.0;
    double m_diskTotalGiB = 0.0;
    QString m_diskName = "";
    double m_networkDownBps = 0.0;
    double m_networkUpBps = 0.0;
    int m_batteryPercent = -1;
    QString m_osName = "Linux";
    QString m_deName = "Unknown";
    QString m_themeName = "Unknown";
    QString m_uptimeText = "0m";

    long long lastIdle = 0;
    long long lastTotal = 0;
    quint64 m_lastRxBytes = 0;
    quint64 m_lastTxBytes = 0;
    qint64 m_lastNetSampleMs = 0;
};
