#include "mediainfo.h"

#include <QDir>
#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QSet>
#include <QUrl>
#include <QtConcurrent>

namespace {
constexpr const char *kPlayerctlBin = "/usr/bin/playerctl";
constexpr const char *kHyprctlBin = "/usr/bin/hyprctl";
constexpr const char *kAnyPlayer = "%any";
constexpr int kTimeoutMs = 450;
constexpr char kFieldSeparator = '\x1f';

struct PlayerEntry {
    QString player;
    QString status;
    QString metadata;
    QString displayName;
};
}

MediaInfo::MediaInfo(QObject *parent)
    : QObject(parent)
{
    connect(&m_pollTimer, &QTimer::timeout, this, &MediaInfo::refresh);
    connect(&m_refreshWatcher, &QFutureWatcher<Snapshot>::finished, this, [this]() {
        applySnapshot(m_refreshWatcher.result());
        if (m_refreshQueued) {
            m_refreshQueued = false;
            startRefreshTask();
        }
    });

    m_pollTimer.start(1000);
    refresh();
}

void MediaInfo::setPollingPaused(bool paused)
{
    if (m_pollPaused == paused) {
        return;
    }

    m_pollPaused = paused;
    if (m_pollPaused) {
        m_pollTimer.stop();
        m_refreshQueued = false;
        return;
    }

    m_pollTimer.start(1000);
    refresh();
}

void MediaInfo::playPause()
{
    sendPlayerctl({"-p", currentPlayerArg(), "play-pause"});
    requestRefreshSoon();
}

void MediaInfo::next()
{
    sendPlayerctl({"-p", currentPlayerArg(), "next"});
    requestRefreshSoon();
}

void MediaInfo::previous()
{
    sendPlayerctl({"-p", currentPlayerArg(), "previous"});
    requestRefreshSoon();
}

void MediaInfo::seekToRatio(double ratio)
{
    if (!m_hasMedia || m_lengthSeconds <= 0.0) {
        return;
    }

    const double clamped = qBound(0.0, ratio, 1.0);
    const double targetSeconds = clamped * m_lengthSeconds;
    sendPlayerctl({"-p", currentPlayerArg(), "position", QString::number(targetSeconds, 'f', 3)});
    requestRefreshSoon();
}

void MediaInfo::seekRelative(double offsetSeconds)
{
    if (!m_hasMedia || m_lengthSeconds <= 0.0) {
        return;
    }

    const double targetSeconds = qBound(0.0, m_positionSeconds + offsetSeconds, m_lengthSeconds);
    sendPlayerctl({"-p", currentPlayerArg(), "position", QString::number(targetSeconds, 'f', 3)});
    requestRefreshSoon();
}

void MediaInfo::setVolume(double volume)
{
    if (!m_hasMedia) {
        return;
    }

    const double clamped = qBound(0.0, volume, 1.0);
    sendPlayerctl({"-p", currentPlayerArg(), "volume", QString::number(clamped, 'f', 3)});
    requestRefreshSoon();
}

void MediaInfo::selectPlayer(const QString &playerId)
{
    const QString nextPlayer = playerId.trimmed();
    if (nextPlayer.isEmpty() || !m_availablePlayers.contains(nextPlayer) || m_selectedPlayer == nextPlayer) {
        return;
    }

    m_selectedPlayer = nextPlayer;
    m_targetPlayer = nextPlayer;
    requestRefreshSoon();
}

void MediaInfo::selectPlayerAt(int index)
{
    if (index < 0 || index >= m_availablePlayers.size()) {
        return;
    }
    selectPlayer(m_availablePlayers.at(index));
}

void MediaInfo::refresh()
{
    if (m_pollPaused) {
        return;
    }

    if (m_refreshWatcher.isRunning()) {
        m_refreshQueued = true;
        return;
    }

    startRefreshTask();
}

void MediaInfo::startRefreshTask()
{
    const QString preferredSelected = m_selectedPlayer;
    const QString preferredTarget = m_targetPlayer;

    m_refreshWatcher.setFuture(
        QtConcurrent::run([preferredSelected, preferredTarget]() {
            return collectSnapshot(preferredSelected, preferredTarget);
        })
    );
}

void MediaInfo::applySnapshot(const Snapshot &snapshot)
{
    const bool mediaIdentityChanged = m_hasMedia != snapshot.hasMedia
        || m_selectedPlayer != snapshot.selectedPlayer
        || m_playerName != snapshot.playerName
        || m_title != snapshot.title
        || m_artist != snapshot.artist
        || m_artUrl != snapshot.artUrl;

    const bool changed = m_availablePlayers != snapshot.availablePlayers
        || m_availablePlayerLabels != snapshot.availablePlayerLabels
        || m_selectedPlayer != snapshot.selectedPlayer
        || m_targetPlayer != snapshot.targetPlayer
        || m_hasMedia != snapshot.hasMedia
        || m_playerName != snapshot.playerName
        || m_title != snapshot.title
        || m_artist != snapshot.artist
        || m_status != snapshot.status
        || !qFuzzyCompare(m_positionSeconds + 1.0, snapshot.positionSeconds + 1.0)
        || !qFuzzyCompare(m_lengthSeconds + 1.0, snapshot.lengthSeconds + 1.0)
        || !qFuzzyCompare(m_volume + 1.0, snapshot.volume + 1.0)
        || m_artUrl != snapshot.artUrl
        || m_isVideo != snapshot.isVideo;

    m_availablePlayers = snapshot.availablePlayers;
    m_availablePlayerLabels = snapshot.availablePlayerLabels;
    m_selectedPlayer = snapshot.selectedPlayer;
    m_targetPlayer = snapshot.targetPlayer;
    m_hasMedia = snapshot.hasMedia;
    m_playerName = snapshot.playerName;
    m_title = snapshot.title;
    m_artist = snapshot.artist;
    m_status = snapshot.status;
    m_positionSeconds = snapshot.positionSeconds;
    m_lengthSeconds = snapshot.lengthSeconds;
    m_volume = snapshot.volume;
    m_artUrl = snapshot.artUrl;
    m_isVideo = snapshot.isVideo;

    if (changed) {
        emit mediaChanged();
    }

    if (!m_pollPaused && snapshot.hasMedia && mediaIdentityChanged) {
        QTimer::singleShot(120, this, &MediaInfo::refresh);
        QTimer::singleShot(360, this, &MediaInfo::refresh);
    }
}

QString MediaInfo::currentPlayerArg() const
{
    if (!m_targetPlayer.isEmpty()) {
        return m_targetPlayer;
    }
    return QString::fromUtf8(kAnyPlayer);
}

void MediaInfo::sendPlayerctl(const QStringList &args) const
{
    QProcess::execute(kPlayerctlBin, args);
}

void MediaInfo::requestRefreshSoon()
{
    QTimer::singleShot(70, this, &MediaInfo::refresh);
}

MediaInfo::Snapshot MediaInfo::collectSnapshot(const QString &preferredSelected, const QString &preferredTarget)
{
    Snapshot snapshot;

    const QString playersOut = runPlayerctl({"-l"});
    QStringList listedPlayers = playersOut.split('\n', Qt::SkipEmptyParts);
    for (QString &player : listedPlayers) {
        player = player.trimmed();
    }
    listedPlayers.removeAll(QString());
    listedPlayers.removeDuplicates();

    if (listedPlayers.isEmpty()) {
        return snapshot;
    }

    QList<PlayerEntry> entries;
    entries.reserve(listedPlayers.size());

    const QStringList youtubeBrowserClasses = browserClassesWithYouTubeTitle();
    for (const QString &player : listedPlayers) {
        const QString playerStatus = runPlayerctl({"-p", player, "status"});
        if (playerStatus.isEmpty()) {
            continue;
        }

        const QString metadata = runPlayerctl({
            "-p", player,
            "metadata",
            "--format",
            QString("{{playerName}}%1{{xesam:title}}%1{{xesam:artist}}%1{{mpris:length}}%1{{mpris:artUrl}}%1{{xesam:url}}")
                .arg(QChar(kFieldSeparator))
        });

        const QStringList fields = metadata.split(QChar(kFieldSeparator));
        const QString rawPlayerName = fields.value(0).trimmed();
        const QString title = compactValue(fields.value(1));
        const QString sourceUrl = compactValue(fields.value(5)).toLower();
        const QString titleLower = title.toLower();
        const QString playerLower = rawPlayerName.toLower();
        const QString classNeedle = playerLower.contains("brave")
            ? "brave"
            : (playerLower.contains("firefox")
                ? "firefox"
                : ((playerLower.contains("chromium") || playerLower.contains("chrome")) ? "chrom" : ""));

        const bool looksLikeYoutube = sourceUrl.contains("youtube.com")
            || sourceUrl.contains("youtu.be")
            || titleLower.contains("youtube")
            || titleLower.endsWith(" - youtube")
            || titleLower.startsWith("youtube -")
            || titleLower.contains(" youtu.be")
            || (!classNeedle.isEmpty() && youtubeBrowserClasses.contains(classNeedle));

        QString displayName = displayPlayerName(rawPlayerName, looksLikeYoutube, sourceUrl);
        if (displayName.isEmpty()) {
            displayName = player;
        }

        entries.append(PlayerEntry{player, playerStatus, metadata, displayName});
    }

    if (entries.isEmpty()) {
        return snapshot;
    }

    QStringList players;
    QStringList labels;
    players.reserve(entries.size());
    labels.reserve(entries.size());

    QHash<QString, int> totalLabelCounts;
    for (const PlayerEntry &entry : entries) {
        players.append(entry.player);
        totalLabelCounts[entry.displayName] += 1;
    }

    QHash<QString, int> seenLabelCounts;
    for (const PlayerEntry &entry : entries) {
        if (totalLabelCounts.value(entry.displayName) > 1) {
            const int instanceNumber = seenLabelCounts.value(entry.displayName) + 1;
            seenLabelCounts.insert(entry.displayName, instanceNumber);
            labels.append(QString("%1 - %2").arg(entry.displayName, QString::number(instanceNumber)));
        } else {
            labels.append(entry.displayName);
        }
    }

    snapshot.availablePlayers = players;
    snapshot.availablePlayerLabels = labels;

    QString firstPlayingPlayer;
    for (const PlayerEntry &entry : entries) {
        if (entry.status == "Playing") {
            firstPlayingPlayer = entry.player;
            break;
        }
    }

    QString selectedPlayer;
    bool preferredSelectedIsPlaying = false;
    if (players.contains(preferredSelected)) {
        selectedPlayer = preferredSelected;
        for (const PlayerEntry &entry : entries) {
            if (entry.player == preferredSelected) {
                preferredSelectedIsPlaying = (entry.status == "Playing");
                break;
            }
        }
    }

    if (!firstPlayingPlayer.isEmpty() && !preferredSelectedIsPlaying) {
        selectedPlayer = firstPlayingPlayer;
    }

    if (selectedPlayer.isEmpty()) {
        if (players.contains(preferredTarget)) {
            selectedPlayer = preferredTarget;
        } else {
            selectedPlayer = players.first();
        }
    }

    snapshot.selectedPlayer = selectedPlayer;
    snapshot.targetPlayer = selectedPlayer;

    int selectedIndex = -1;
    for (int i = 0; i < entries.size(); ++i) {
        if (entries.at(i).player == selectedPlayer) {
            selectedIndex = i;
            break;
        }
    }
    if (selectedIndex < 0) {
        return snapshot;
    }

    const PlayerEntry selectedEntry = entries.at(selectedIndex);
    const QString statusOut = selectedEntry.status;
    if (statusOut.isEmpty()) {
        return snapshot;
    }

    const QString posOut = runPlayerctl({"-p", selectedPlayer, "position"});
    const QString volumeOut = runPlayerctl({"-p", selectedPlayer, "volume"});

    const QStringList fields = selectedEntry.metadata.split(QChar(kFieldSeparator));
    const QString rawPlayerName = fields.value(0).trimmed();
    const QString title = compactValue(fields.value(1));
    const QString artist = compactValue(fields.value(2));
    const double lengthSeconds = parseMicroseconds(fields.value(3));
    const QString artUrl = compactValue(fields.value(4));
    const QString sourceUrl = compactValue(fields.value(5)).toLower();
    const QString titleLower = title.toLower();
    const QString lowerPlayerName = rawPlayerName.toLower();
    const bool looksLikeNetflix = titleLower.contains("netflix");
    const QString classNeedle = lowerPlayerName.contains("brave")
        ? "brave"
        : (lowerPlayerName.contains("firefox")
            ? "firefox"
            : ((lowerPlayerName.contains("chromium") || lowerPlayerName.contains("chrome")) ? "chrom" : ""));

    const bool looksLikeYoutube = sourceUrl.contains("youtube.com")
        || sourceUrl.contains("youtu.be")
        || titleLower.contains("youtube")
        || titleLower.endsWith(" - youtube")
        || titleLower.startsWith("youtube -")
        || titleLower.contains(" youtu.be")
        || (!classNeedle.isEmpty() && youtubeBrowserClasses.contains(classNeedle));
    const bool applyNetflixBranding = looksLikeNetflix && !looksLikeYoutube;

    snapshot.playerName = displayPlayerName(rawPlayerName, looksLikeYoutube, sourceUrl);
    snapshot.title = title;
    snapshot.artist = applyNetflixBranding ? "Netflix" : artist;
    snapshot.status = statusOut;
    snapshot.positionSeconds = qMax(0.0, posOut.toDouble());
    snapshot.lengthSeconds = lengthSeconds;
    snapshot.volume = qBound(0.0, volumeOut.toDouble(), 1.0);
    snapshot.artUrl = applyNetflixBranding
        ? QUrl::fromLocalFile(QDir::homePath() + "/.local/share/icons/netflix.png").toString()
        : artUrl;
    snapshot.isVideo = lowerPlayerName.contains("vlc")
        || lowerPlayerName.contains("mpv")
        || looksLikeYoutube
        || sourceUrl.contains("vimeo.com")
        || sourceUrl.contains("twitch.tv")
        || sourceUrl.endsWith(".mp4")
        || sourceUrl.endsWith(".webm")
        || sourceUrl.endsWith(".mkv");
    snapshot.hasMedia = true;

    return snapshot;
}

QString MediaInfo::runPlayerctl(const QStringList &args)
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

QString MediaInfo::compactValue(const QString &value)
{
    QString out = value;
    out.replace('\n', ' ');
    return out.trimmed();
}

QString MediaInfo::displayPlayerName(const QString &rawPlayerName, bool looksLikeYoutube, const QString &sourceUrlLower)
{
    if (looksLikeYoutube || sourceUrlLower.contains("youtube.com") || sourceUrlLower.contains("youtu.be")) {
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

QStringList MediaInfo::browserClassesWithYouTubeTitle()
{
    QProcess proc;
    proc.start(QString::fromUtf8(kHyprctlBin), {"-j", "clients"});
    if (!proc.waitForStarted(kTimeoutMs)) {
        return {};
    }
    if (!proc.waitForFinished(kTimeoutMs)) {
        proc.kill();
        proc.waitForFinished();
        return {};
    }
    if (proc.exitStatus() != QProcess::NormalExit || proc.exitCode() != 0) {
        return {};
    }

    const QByteArray payload = proc.readAllStandardOutput();
    const QJsonDocument doc = QJsonDocument::fromJson(payload);
    if (!doc.isArray()) {
        return {};
    }

    QSet<QString> matches;
    const QJsonArray clients = doc.array();
    for (const QJsonValue &entry : clients) {
        if (!entry.isObject()) {
            continue;
        }
        const QJsonObject obj = entry.toObject();
        const QString cls = obj.value("class").toString().toLower();
        const QString title = obj.value("title").toString().toLower();
        if (title.contains("youtube") || title.contains("youtu.be")) {
            if (cls.contains("brave")) {
                matches.insert("brave");
            }
            if (cls.contains("firefox")) {
                matches.insert("firefox");
            }
            if (cls.contains("chrom")) {
                matches.insert("chrom");
            }
        }
    }

    return matches.values();
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
