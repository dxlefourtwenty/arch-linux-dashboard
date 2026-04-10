#include "mediainfo.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>

namespace {
constexpr const char *kPlayerctlBin = "/usr/bin/playerctl";
constexpr const char *kHyprctlBin = "/usr/bin/hyprctl";
constexpr const char *kAnyPlayer = "%any";
constexpr int kTimeoutMs = 400;
constexpr char kFieldSeparator = '\x1f';
}

MediaInfo::MediaInfo(QObject *parent)
    : QObject(parent)
{
    connect(&m_pollTimer, &QTimer::timeout, this, &MediaInfo::refresh);
    m_pollTimer.start(1000);
    refresh();
}

void MediaInfo::playPause()
{
    sendPlayerctl({"-p", currentPlayerArg(), "play-pause"});
    refresh();
}

void MediaInfo::next()
{
    sendPlayerctl({"-p", currentPlayerArg(), "next"});
    refresh();
}

void MediaInfo::previous()
{
    sendPlayerctl({"-p", currentPlayerArg(), "previous"});
    refresh();
}

void MediaInfo::seekToRatio(double ratio)
{
    if (!m_hasMedia || m_lengthSeconds <= 0.0) {
        return;
    }

    const double clamped = qBound(0.0, ratio, 1.0);
    const double targetSeconds = clamped * m_lengthSeconds;
    sendPlayerctl({"-p", currentPlayerArg(), "position", QString::number(targetSeconds, 'f', 3)});
    refresh();
}

void MediaInfo::seekRelative(double offsetSeconds)
{
    if (!m_hasMedia || m_lengthSeconds <= 0.0) {
        return;
    }

    const double targetSeconds = qBound(0.0, m_positionSeconds + offsetSeconds, m_lengthSeconds);
    sendPlayerctl({"-p", currentPlayerArg(), "position", QString::number(targetSeconds, 'f', 3)});
    refresh();
}

void MediaInfo::setVolume(double volume)
{
    if (!m_hasMedia) {
        return;
    }

    const double clamped = qBound(0.0, volume, 1.0);
    sendPlayerctl({"-p", currentPlayerArg(), "volume", QString::number(clamped, 'f', 3)});
    refresh();
}

void MediaInfo::refresh()
{
    const QString playersOut = runPlayerctl({"-l"});
    QStringList players = playersOut.split('\n', Qt::SkipEmptyParts);
    for (QString &player : players) {
        player = player.trimmed();
    }
    players.removeAll(QString());
    players.removeDuplicates();

    if (players.isEmpty()) {
        const bool changed = m_hasMedia || !m_playerName.isEmpty() || !m_title.isEmpty()
            || !m_artist.isEmpty() || !m_status.isEmpty() || m_positionSeconds != 0.0
            || m_lengthSeconds != 0.0 || m_volume != 0.0 || !m_artUrl.isEmpty() || m_isVideo;

        m_targetPlayer.clear();
        m_hasMedia = false;
        m_playerName.clear();
        m_title.clear();
        m_artist.clear();
        m_status.clear();
        m_positionSeconds = 0.0;
        m_lengthSeconds = 0.0;
        m_volume = 0.0;
        m_artUrl.clear();
        m_isVideo = false;

        if (changed) {
            emit mediaChanged();
        }
        return;
    }

    QString selectedPlayer;
    for (const QString &player : players) {
        const QString playerStatus = runPlayerctl({"-p", player, "status"});
        if (playerStatus == "Playing") {
            selectedPlayer = player;
            break;
        }
    }

    if (selectedPlayer.isEmpty()) {
        if (players.contains(m_targetPlayer)) {
            selectedPlayer = m_targetPlayer;
        } else {
            selectedPlayer = players.first();
        }
    }
    m_targetPlayer = selectedPlayer;

    const QString statusOut = runPlayerctl({"-p", m_targetPlayer, "status"});
    if (statusOut.isEmpty()) {
        m_hasMedia = false;
        m_playerName.clear();
        m_title.clear();
        m_artist.clear();
        m_status.clear();
        m_positionSeconds = 0.0;
        m_lengthSeconds = 0.0;
        m_volume = 0.0;
        m_artUrl.clear();
        m_isVideo = false;
        emit mediaChanged();
        return;
    }

    const QString metaOut = runPlayerctl({
        "-p", m_targetPlayer,
        "metadata",
        "--format",
        QString("{{playerName}}%1{{xesam:title}}%1{{xesam:artist}}%1{{mpris:length}}%1{{mpris:artUrl}}%1{{xesam:url}}")
            .arg(QChar(kFieldSeparator))
    });

    const QString posOut = runPlayerctl({"-p", m_targetPlayer, "position"});
    const QString volumeOut = runPlayerctl({"-p", m_targetPlayer, "volume"});

    const QStringList fields = metaOut.split(QChar(kFieldSeparator));
    const QString rawPlayerName = fields.value(0).trimmed();
    const QString title = compactValue(fields.value(1));
    const QString artist = compactValue(fields.value(2));
    const double lengthSeconds = parseMicroseconds(fields.value(3));
    const QString artUrl = compactValue(fields.value(4));
    const QString sourceUrl = compactValue(fields.value(5)).toLower();
    const QString titleLower = title.toLower();
    const bool looksLikeYoutube = sourceUrl.contains("youtube.com")
        || sourceUrl.contains("youtu.be")
        || titleLower.contains("youtube")
        || titleLower.endsWith(" - youtube")
        || titleLower.startsWith("youtube -")
        || titleLower.contains(" youtu.be")
        || hyprClientsShowYouTubeForBrowser(rawPlayerName);
    const QString playerName = displayPlayerName(rawPlayerName, looksLikeYoutube ? QStringLiteral("youtube.com") : sourceUrl);
    const double volume = qBound(0.0, volumeOut.toDouble(), 1.0);
    const double positionSeconds = qMax(0.0, posOut.toDouble());
    const QString lowerPlayerName = rawPlayerName.toLower();
    const bool isVideo = lowerPlayerName.contains("vlc")
        || lowerPlayerName.contains("mpv")
        || looksLikeYoutube
        || sourceUrl.contains("vimeo.com")
        || sourceUrl.contains("twitch.tv")
        || sourceUrl.endsWith(".mp4")
        || sourceUrl.endsWith(".webm")
        || sourceUrl.endsWith(".mkv");

    const bool changed = !m_hasMedia
        || m_playerName != playerName
        || m_title != title
        || m_artist != artist
        || m_status != statusOut
        || !qFuzzyCompare(m_positionSeconds + 1.0, positionSeconds + 1.0)
        || !qFuzzyCompare(m_lengthSeconds + 1.0, lengthSeconds + 1.0)
        || !qFuzzyCompare(m_volume + 1.0, volume + 1.0)
        || m_artUrl != artUrl
        || m_isVideo != isVideo;

    m_hasMedia = true;
    m_playerName = playerName;
    m_title = title;
    m_artist = artist;
    m_status = statusOut;
    m_positionSeconds = positionSeconds;
    m_lengthSeconds = lengthSeconds;
    m_volume = volume;
    m_artUrl = artUrl;
    m_isVideo = isVideo;

    if (changed) {
        emit mediaChanged();
    }
}

QString MediaInfo::currentPlayerArg() const
{
    if (!m_targetPlayer.isEmpty()) {
        return m_targetPlayer;
    }
    return QString::fromUtf8(kAnyPlayer);
}

QString MediaInfo::runPlayerctl(const QStringList &args) const
{
    QProcess proc;
    proc.start(kPlayerctlBin, args);
    if (!proc.waitForStarted(kTimeoutMs)) {
        return QString();
    }
    if (!proc.waitForFinished(kTimeoutMs)) {
        proc.kill();
        proc.waitForFinished();
        return QString();
    }
    if (proc.exitStatus() != QProcess::NormalExit || proc.exitCode() != 0) {
        return QString();
    }

    return QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
}

void MediaInfo::sendPlayerctl(const QStringList &args) const
{
    QProcess::execute(kPlayerctlBin, args);
}

QString MediaInfo::compactValue(const QString &value)
{
    QString out = value;
    out.replace('\n', ' ');
    return out.trimmed();
}

QString MediaInfo::displayPlayerName(const QString &rawPlayerName, const QString &sourceUrlLower)
{
    if (sourceUrlLower.contains("youtube.com") || sourceUrlLower.contains("youtu.be")) {
        return "YouTube";
    }

    const QString lower = rawPlayerName.toLower();
    if (lower.contains("spotify")) return "Spotify";
    if (lower.contains("firefox")) return "Firefox";
    if (lower.contains("chromium")) return "Chromium";
    if (lower.contains("brave")) return "Brave";
    if (lower.contains("vlc")) return "VLC";
    if (lower.contains("mpv")) return "MPV";

    if (rawPlayerName.isEmpty()) {
        return rawPlayerName;
    }

    QString out = rawPlayerName;
    out[0] = out.at(0).toUpper();
    return out;
}

bool MediaInfo::hyprClientsShowYouTubeForBrowser(const QString &rawPlayerName)
{
    const QString playerLower = rawPlayerName.toLower();
    QString classNeedle;
    if (playerLower.contains("brave")) {
        classNeedle = "brave";
    } else if (playerLower.contains("firefox")) {
        classNeedle = "firefox";
    } else if (playerLower.contains("chromium") || playerLower.contains("chrome")) {
        classNeedle = "chrom";
    } else {
        return false;
    }

    QProcess proc;
    proc.start(QString::fromUtf8(kHyprctlBin), {"-j", "clients"});
    if (!proc.waitForStarted(kTimeoutMs)) {
        return false;
    }
    if (!proc.waitForFinished(kTimeoutMs)) {
        proc.kill();
        proc.waitForFinished();
        return false;
    }
    if (proc.exitStatus() != QProcess::NormalExit || proc.exitCode() != 0) {
        return false;
    }

    const QByteArray payload = proc.readAllStandardOutput();
    const QJsonDocument doc = QJsonDocument::fromJson(payload);
    if (!doc.isArray()) {
        return false;
    }

    const QJsonArray clients = doc.array();
    for (const QJsonValue &entry : clients) {
        if (!entry.isObject()) {
            continue;
        }
        const QJsonObject obj = entry.toObject();
        const QString cls = obj.value("class").toString().toLower();
        if (!cls.contains(classNeedle)) {
            continue;
        }
        const QString title = obj.value("title").toString().toLower();
        if (title.contains("youtube") || title.contains("youtu.be")) {
            return true;
        }
    }

    return false;
}

double MediaInfo::parseMicroseconds(const QString &raw)
{
    bool ok = false;
    const qlonglong micros = raw.toLongLong(&ok);
    if (!ok || micros <= 0) {
        return 0.0;
    }
    return static_cast<double>(micros) / 1000000.0;
}
