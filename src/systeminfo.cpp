#include "systeminfo.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfoList>
#include <QRegularExpression>
#include <QProcess>
#include <QTextStream>
#include <QtMath>

#include <sys/statvfs.h>

namespace {
bool hasSignificantDelta(double current, double next)
{
    return qAbs(current - next) >= 0.01;
}

double toGiB(double bytes)
{
    return bytes / (1024.0 * 1024.0 * 1024.0);
}

QString stripPartitionSuffix(const QString &device)
{
    if (device.isEmpty()) {
        return device;
    }

    QString base = device;
    while (!base.isEmpty() && base.back().isDigit()) {
        base.chop(1);
    }

    if (base.endsWith('p') && (device.startsWith("nvme") || device.startsWith("mmcblk"))) {
        base.chop(1);
    }

    return base.isEmpty() ? device : base;
}

QString firstSlaveBlockDevice(const QString &blockDevice)
{
    const QDir slavesDir("/sys/class/block/" + blockDevice + "/slaves");
    const QFileInfoList slaves = slavesDir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    if (slaves.isEmpty()) {
        return "";
    }
    return slaves.first().fileName();
}

QMap<QString, QString> parseLsblkPairs(const QString &line)
{
    QMap<QString, QString> fields;
    static const QRegularExpression pairRe(QStringLiteral("(\\w+)=\"([^\"]*)\""));
    const QRegularExpressionMatchIterator matches = pairRe.globalMatch(line);
    for (QRegularExpressionMatchIterator it = matches; it.hasNext();) {
        const QRegularExpressionMatch match = it.next();
        fields.insert(match.captured(1), match.captured(2));
    }
    return fields;
}

QString driveFromLsblkForMount(const QString &targetMountPoint)
{
    QProcess proc;
    proc.start("/usr/bin/lsblk", {"-P", "-o", "NAME,TYPE,MOUNTPOINTS,PKNAME", "-p"});
    if (!proc.waitForFinished(400) || proc.exitStatus() != QProcess::NormalExit || proc.exitCode() != 0) {
        return "";
    }

    const QStringList lines = QString::fromUtf8(proc.readAllStandardOutput()).split('\n', Qt::SkipEmptyParts);
    for (const QString &line : lines) {
        const QMap<QString, QString> fields = parseLsblkPairs(line);
        if (fields.isEmpty()) {
            continue;
        }

        const QString mountpointsRaw = fields.value("MOUNTPOINTS");
        QString normalizedMounts = mountpointsRaw;
        normalizedMounts.replace("\\x0a", "\n");
        const QStringList mountpoints = normalizedMounts.split('\n', Qt::SkipEmptyParts);
        if (!mountpoints.contains(targetMountPoint)) {
            continue;
        }

        QString candidate = fields.value("NAME");
        const QString type = fields.value("TYPE");
        const QString parent = fields.value("PKNAME");
        if ((type == "part" || type == "lvm") && !parent.isEmpty()) {
            candidate = parent;
        }

        return stripPartitionSuffix(QFileInfo(candidate).fileName());
    }

    return "";
}

QString resolveDriveName(const QString &mountSource)
{
    QString source = mountSource.trimmed();
    if (source.isEmpty()) {
        return "";
    }

    if (source == "/dev/root") {
        const QFileInfo info(source);
        if (info.isSymLink()) {
            const QString target = info.symLinkTarget();
            if (!target.isEmpty()) {
                source = target;
            }
        }
    }

    if (!source.startsWith("/dev/")) {
        return "";
    }

    QString blockDevice = QFileInfo(source).fileName();
    if (blockDevice.isEmpty()) {
        return "";
    }

    if (blockDevice.startsWith("mapper/")) {
        blockDevice = blockDevice.mid(QString("mapper/").size());
    }

    if (blockDevice.startsWith("dm-")) {
        const QString slave = firstSlaveBlockDevice(blockDevice);
        if (!slave.isEmpty()) {
            blockDevice = slave;
        }
    }

    if (source.startsWith("/dev/mapper/")) {
        const QString dmName = QFileInfo(source).fileName();
        const QDir mappedDir("/sys/block");
        const QFileInfoList dmNodes = mappedDir.entryInfoList(QStringList() << "dm-*", QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QFileInfo &node : dmNodes) {
            QFile nameFile(node.absoluteFilePath() + "/dm/name");
            if (!nameFile.open(QIODevice::ReadOnly)) {
                continue;
            }
            const QString mappedName = QString::fromUtf8(nameFile.readAll()).trimmed();
            if (mappedName == dmName) {
                const QString slave = firstSlaveBlockDevice(node.fileName());
                if (!slave.isEmpty()) {
                    blockDevice = slave;
                }
                break;
            }
        }
    }

    return stripPartitionSuffix(blockDevice);
}
}

SystemInfo::SystemInfo(QObject *parent)
    : QObject(parent)
{
    loadCpuName();
    loadGpuName();
    loadOsName();
    loadDiskName();
    updateDesktopEnvironment();
    updateThemeName();
    updateUptime();

    setupGpu();
    updateCpu();
    updateRam();
    updateDisk();
    updateNetwork();
    updateBattery();

    connect(&timer, &QTimer::timeout, this, [this]() {
        updateCpu();
        updateGpu();
        updateRam();
        updateDisk();
        updateNetwork();
        updateBattery();
        updateDesktopEnvironment();
        updateThemeName();
        updateUptime();
    });

    timer.start(1000);
}

void SystemInfo::loadOsName()
{
    QFile file("/etc/os-release");
    if (!file.open(QIODevice::ReadOnly)) {
        return;
    }

    const QList<QByteArray> lines = file.readAll().split('\n');
    for (const QByteArray &line : lines) {
        if (!line.startsWith("PRETTY_NAME=")) {
            continue;
        }

        QString value = QString::fromUtf8(line.mid(12)).trimmed();
        if (value.startsWith('"') && value.endsWith('"') && value.size() >= 2) {
            value = value.mid(1, value.size() - 2);
        }

        if (value != m_osName) {
            m_osName = value;
            emit osNameChanged();
        }
        return;
    }
}

void SystemInfo::loadDiskName()
{
    const QString fromHome = driveFromLsblkForMount("/home");
    if (!fromHome.isEmpty()) {
        if (fromHome != m_diskName) {
            m_diskName = fromHome;
            emit diskNameChanged();
        }
        return;
    }

    const QString fromRoot = driveFromLsblkForMount("/");
    if (!fromRoot.isEmpty()) {
        if (fromRoot != m_diskName) {
            m_diskName = fromRoot;
            emit diskNameChanged();
        }
        return;
    }

    QFile file("/proc/self/mounts");
    if (!file.open(QIODevice::ReadOnly)) {
        return;
    }

    QTextStream stream(&file);
    while (!stream.atEnd()) {
        const QString line = stream.readLine().trimmed();
        if (line.isEmpty()) {
            continue;
        }

        const QStringList fields = line.split(' ', Qt::SkipEmptyParts);
        if (fields.size() < 2 || fields[1] != "/") {
            continue;
        }

        const QString driveName = resolveDriveName(fields[0]);
        if (driveName.isEmpty()) {
            return;
        }

        if (driveName != m_diskName) {
            m_diskName = driveName;
            emit diskNameChanged();
        }
        return;
    }
}

void SystemInfo::updateDesktopEnvironment()
{
    QString de = QString::fromUtf8(qgetenv("XDG_CURRENT_DESKTOP")).trimmed();
    if (de.isEmpty()) {
        de = QString::fromUtf8(qgetenv("DESKTOP_SESSION")).trimmed();
    }
    if (de.isEmpty()) {
        de = "Unknown";
    }

    if (de != m_deName) {
        m_deName = de;
        emit deNameChanged();
    }
}

void SystemInfo::updateThemeName()
{
    const QString currentThemePath = QDir::homePath() + "/.config/themes/current";
    const QFileInfo linkInfo(currentThemePath);

    QString theme = "Unknown";
    if (linkInfo.isSymLink()) {
        const QString targetPath = linkInfo.symLinkTarget();
        if (!targetPath.isEmpty()) {
            const QString targetName = QFileInfo(targetPath).fileName().trimmed();
            if (!targetName.isEmpty()) {
                theme = targetName;
            }
        }
    } else if (linkInfo.exists()) {
        const QString fallbackName = linkInfo.fileName().trimmed();
        if (!fallbackName.isEmpty()) {
            theme = fallbackName;
        }
    }

    if (theme != m_themeName) {
        m_themeName = theme;
        emit themeNameChanged();
    }
}

void SystemInfo::updateUptime()
{
    QFile file("/proc/uptime");
    if (!file.open(QIODevice::ReadOnly)) {
        return;
    }

    const QByteArray raw = file.readLine().trimmed();
    if (raw.isEmpty()) {
        return;
    }

    const QList<QByteArray> parts = raw.split(' ');
    if (parts.isEmpty()) {
        return;
    }

    bool ok = false;
    const double totalSeconds = parts.first().toDouble(&ok);
    if (!ok || totalSeconds < 0) {
        return;
    }

    const int seconds = static_cast<int>(totalSeconds);
    const int days = seconds / 86400;
    const int hours = (seconds % 86400) / 3600;
    const int minutes = (seconds % 3600) / 60;

    QString uptime;
    if (days > 0) {
        uptime = QString::number(days) + "d " + QString::number(hours) + "h " + QString::number(minutes) + "m";
    } else if (hours > 0) {
        uptime = QString::number(hours) + "h " + QString::number(minutes) + "m";
    } else {
        uptime = QString::number(minutes) + "m";
    }

    if (uptime != m_uptimeText) {
        m_uptimeText = uptime;
        emit uptimeTextChanged();
    }
}

void SystemInfo::updateCpu()
{
    QFile file("/proc/stat");
    if (!file.open(QIODevice::ReadOnly))
        return;

    QByteArray line = file.readLine();
    QList<QByteArray> parts = line.simplified().split(' ');

    if (parts.size() < 5) {
        return;
    }

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

    const QByteArray content = file.readAll();

    long total = 0;
    long available = 0;
    for (const QByteArray &line : content.split('\n')) {
        if (line.startsWith("MemTotal")) {
            total = line.split(':')[1].simplified().split(' ')[0].toLong();
        }
        if (line.startsWith("MemAvailable")) {
            available = line.split(':')[1].simplified().split(' ')[0].toLong();
        }
    }

    if (total == 0) {
        return;
    }

    int used = 100 - ((available * 100) / total);
    if (used != m_ram) {
        m_ram = used;
        emit ramUsageChanged();
    }

    const double totalGiB = total / (1024.0 * 1024.0);
    const double usedGiB = (total - available) / (1024.0 * 1024.0);
    if (hasSignificantDelta(m_ramTotalGiB, totalGiB) || hasSignificantDelta(m_ramUsedGiB, usedGiB)) {
        m_ramTotalGiB = totalGiB;
        m_ramUsedGiB = usedGiB;
        emit ramTotalsChanged();
    }
}

void SystemInfo::updateDisk()
{
    struct statvfs stat {};
    if (statvfs("/", &stat) != 0)
        return;

    unsigned long total = stat.f_blocks * stat.f_frsize;
    unsigned long free = stat.f_bavail * stat.f_frsize;
    if (total == 0)
        return;

    int used = 100 - (free * 100 / total);
    if (used != m_disk) {
        m_disk = used;
        emit diskUsageChanged();
    }

    const double totalGiB = toGiB(total);
    const double usedGiB = toGiB(total - free);
    if (hasSignificantDelta(m_diskTotalGiB, totalGiB) || hasSignificantDelta(m_diskUsedGiB, usedGiB)) {
        m_diskTotalGiB = totalGiB;
        m_diskUsedGiB = usedGiB;
        emit diskTotalsChanged();
    }
}

void SystemInfo::updateNetwork()
{
    quint64 rxBytes = 0;
    quint64 txBytes = 0;
    bool hasInterfaceBytes = false;

    const QString preferredIface = primaryNetworkInterface();
    if (!preferredIface.isEmpty() && preferredIface != "lo") {
        hasInterfaceBytes = readInterfaceBytes(preferredIface, rxBytes, txBytes);
    }

    if (!hasInterfaceBytes) {
        const QFileInfoList interfaces = QDir("/sys/class/net").entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QFileInfo &entry : interfaces) {
            const QString iface = entry.fileName();
            if (iface == "lo") {
                continue;
            }

            quint64 ifaceRx = 0;
            quint64 ifaceTx = 0;
            if (!readInterfaceBytes(iface, ifaceRx, ifaceTx)) {
                continue;
            }
            rxBytes += ifaceRx;
            txBytes += ifaceTx;
            hasInterfaceBytes = true;
        }
    }

    if (!hasInterfaceBytes) {
        return;
    }

    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
    if (m_lastNetSampleMs == 0 || nowMs <= m_lastNetSampleMs || rxBytes < m_lastRxBytes || txBytes < m_lastTxBytes) {
        m_lastRxBytes = rxBytes;
        m_lastTxBytes = txBytes;
        m_lastNetSampleMs = nowMs;
        return;
    }

    const double elapsedSeconds = (nowMs - m_lastNetSampleMs) / 1000.0;
    if (elapsedSeconds <= 0) {
        return;
    }

    const double downBps = (rxBytes - m_lastRxBytes) / elapsedSeconds;
    const double upBps = (txBytes - m_lastTxBytes) / elapsedSeconds;

    m_lastRxBytes = rxBytes;
    m_lastTxBytes = txBytes;
    m_lastNetSampleMs = nowMs;

    if (hasSignificantDelta(m_networkDownBps, downBps) || hasSignificantDelta(m_networkUpBps, upBps)) {
        m_networkDownBps = downBps;
        m_networkUpBps = upBps;
        emit networkChanged();
    }
}

QString SystemInfo::primaryNetworkInterface() const
{
    QFile file("/proc/net/route");
    if (!file.open(QIODevice::ReadOnly)) {
        return "";
    }

    QTextStream stream(&file);
    bool skippedHeader = false;
    while (!stream.atEnd()) {
        const QString line = stream.readLine().trimmed();
        if (!skippedHeader) {
            skippedHeader = true;
            continue;
        }
        if (line.isEmpty()) {
            continue;
        }

        const QStringList fields = line.simplified().split(' ');
        if (fields.size() < 2) {
            continue;
        }

        if (fields[1] == "00000000") {
            return fields[0];
        }
    }

    return "";
}

bool SystemInfo::readInterfaceBytes(const QString &iface, quint64 &rxBytes, quint64 &txBytes) const
{
    QFile rxFile("/sys/class/net/" + iface + "/statistics/rx_bytes");
    QFile txFile("/sys/class/net/" + iface + "/statistics/tx_bytes");
    if (!rxFile.open(QIODevice::ReadOnly) || !txFile.open(QIODevice::ReadOnly)) {
        return false;
    }

    bool rxOk = false;
    bool txOk = false;
    const quint64 rx = QString::fromUtf8(rxFile.readAll()).trimmed().toULongLong(&rxOk);
    const quint64 tx = QString::fromUtf8(txFile.readAll()).trimmed().toULongLong(&txOk);
    if (!rxOk || !txOk) {
        return false;
    }

    rxBytes = rx;
    txBytes = tx;
    return true;
}

void SystemInfo::updateBattery()
{
    const QFileInfoList entries = QDir("/sys/class/power_supply").entryInfoList(
        QDir::Dirs | QDir::NoDotAndDotDot
    );

    for (const QFileInfo &entry : entries) {
        const QString name = entry.fileName();
        if (!name.startsWith("BAT")) {
            continue;
        }

        QFile capFile(entry.absoluteFilePath() + "/capacity");
        if (!capFile.open(QIODevice::ReadOnly)) {
            continue;
        }

        bool ok = false;
        const int percent = QString::fromUtf8(capFile.readAll()).trimmed().toInt(&ok);
        if (!ok) {
            continue;
        }

        if (percent != m_batteryPercent) {
            m_batteryPercent = percent;
            emit batteryPercentChanged();
        }
        return;
    }

    if (m_batteryPercent != -1) {
        m_batteryPercent = -1;
        emit batteryPercentChanged();
    }
}

void SystemInfo::setupGpu()
{
    connect(&gpuProc, &QProcess::finished, this, [this](int exitCode, QProcess::ExitStatus exitStatus) {
        if (exitStatus != QProcess::NormalExit || exitCode != 0) {
            return;
        }

        const QList<QByteArray> lines = gpuProc.readAllStandardOutput().trimmed().split('\n');
        if (lines.isEmpty()) {
            return;
        }

        bool ok = false;
        const int usage = lines.first().trimmed().toInt(&ok);
        if (!ok) {
            return;
        }

        if (usage != m_gpu) {
            m_gpu = usage;
            emit gpuUsageChanged();
        }
    });

    updateGpu();
}

void SystemInfo::updateGpu()
{
    if (gpuProc.state() != QProcess::NotRunning) {
        return;
    }

    gpuProc.start("nvidia-smi", {"--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"});
}

void SystemInfo::loadCpuName()
{
    QFile file("/proc/cpuinfo");
    if (!file.open(QIODevice::ReadOnly)) {
        return;
    }

    const QList<QByteArray> lines = file.readAll().split('\n');
    for (const QByteArray &line : lines) {
        if (!line.startsWith("model name")) {
            continue;
        }

        const int colon = line.indexOf(':');
        if (colon < 0 || colon + 1 >= line.size()) {
            continue;
        }

        const QString cpu = QString::fromUtf8(line.mid(colon + 1)).trimmed();
        if (!cpu.isEmpty() && cpu != m_cpuName) {
            m_cpuName = cpu;
            emit cpuNameChanged();
        }
        return;
    }
}

void SystemInfo::loadGpuName()
{
    QProcess proc;
    proc.start("nvidia-smi", {"--query-gpu=name", "--format=csv,noheader"});
    if (!proc.waitForFinished(250) || proc.exitStatus() != QProcess::NormalExit || proc.exitCode() != 0) {
        return;
    }

    const QString gpu = QString::fromUtf8(proc.readAllStandardOutput()).split('\n').first().trimmed();
    if (!gpu.isEmpty() && gpu != m_gpuName) {
        m_gpuName = gpu;
        emit gpuNameChanged();
    }
}
