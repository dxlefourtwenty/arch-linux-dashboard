#include "mediainfo.h"

#include <QDir>
#include <QDateTime>
#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QRegularExpression>
#include <QSet>
#include <QUrl>
#include <QtConcurrent>

namespace {
constexpr const char *kPlayerctlBin = "/usr/bin/playerctl";
constexpr const char *kHyprctlBin = "/usr/bin/hyprctl";
constexpr const char *kAnyPlayer = "%any";
constexpr int kTimeoutMs = 900;
constexpr qint64 kTransientEmptySnapshotGraceMs = 2200;
constexpr char kFieldSeparator = '\x1f';
const QString kStatusFormat = QString("{{playerName}}%1{{status}}").arg(QChar(kFieldSeparator));
const QString kMetadataFormat =
    QString("{{playerName}}%1{{xesam:title}}%1{{mpris:trackid}}%1{{xesam:artist}}%1{{mpris:length}}%1{{mpris:artUrl}}%1{{xesam:url}}")
        .arg(QChar(kFieldSeparator));

struct PlayerEntry {
    QString player;
    QString status;
    QString metadata;
    QString displayName;
};

int mediaSiteRankFromTitle(const QString &titleLower)
{
    if (titleLower.contains("youtube") || titleLower.contains("youtu.be")) {
        return 0;
    }
    if (titleLower.contains("netflix")) {
        return 1;
    }
    if (titleLower.contains("twitch")) {
        return 2;
    }
    if (titleLower.contains("vimeo")) {
        return 3;
    }
    return 4;
}

QHash<QString, QString> parseStatusByPlayer(const QString &rawOutput)
{
    QHash<QString, QString> statusByPlayer;
    const QStringList lines = rawOutput.split('\n', Qt::SkipEmptyParts);
    for (const QString &line : lines) {
        const QStringList fields = line.split(QChar(kFieldSeparator));
        if (fields.size() < 2) {
            continue;
        }

        const QString player = fields.at(0).trimmed();
        if (player.isEmpty()) {
            continue;
        }

        statusByPlayer.insert(player, fields.at(1).trimmed());
    }

    return statusByPlayer;
}

QHash<QString, QString> parseMetadataByPlayer(const QString &rawOutput)
{
    QHash<QString, QString> metadataByPlayer;
    const QStringList lines = rawOutput.split('\n', Qt::SkipEmptyParts);
    for (const QString &line : lines) {
        const QStringList fields = line.split(QChar(kFieldSeparator));
        const QString player = fields.value(0).trimmed();
        if (player.isEmpty()) {
            continue;
        }

        metadataByPlayer.insert(player, line.trimmed());
    }

    return metadataByPlayer;
}
}

MediaInfo::MediaInfo(QObject *parent)
    : QObject(parent)
{
    connect(&m_pollTimer, &QTimer::timeout, this, &MediaInfo::refresh);
    connect(&m_playerEventsProc, &QProcess::readyReadStandardOutput, this, [this]() {
        m_playerEventsProc.readAllStandardOutput();
        if (!m_pollPaused) {
            requestRefreshSoon();
        }
    });
    connect(&m_playerEventsProc, &QProcess::finished, this, [this](int, QProcess::ExitStatus) {
        if (!m_pollPaused) {
            QTimer::singleShot(1000, this, &MediaInfo::startPlayerEventsFollow);
        }
    });
    connect(&m_playerEventsProc, &QProcess::errorOccurred, this, [this](QProcess::ProcessError) {
        if (!m_pollPaused) {
            QTimer::singleShot(1000, this, &MediaInfo::startPlayerEventsFollow);
        }
    });
    connect(&m_refreshWatcher, &QFutureWatcher<Snapshot>::finished, this, [this]() {
        applySnapshot(m_refreshWatcher.result());
        if (m_refreshQueued) {
            m_refreshQueued = false;
            startRefreshTask();
        }
    });

    m_pollTimer.start(1000);
    startPlayerEventsFollow();
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
        if (m_playerEventsProc.state() != QProcess::NotRunning) {
            m_playerEventsProc.kill();
            m_playerEventsProc.waitForFinished();
        }
        return;
    }

    m_pollTimer.start(1000);
    startPlayerEventsFollow();
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

void MediaInfo::startPlayerEventsFollow()
{
    if (m_playerEventsProc.state() != QProcess::NotRunning) {
        return;
    }
    m_playerEventsProc.start(kPlayerctlBin, {
        "--all-players",
        "metadata",
        "--follow",
        "--format", "{{playerName}}"
    });
}

void MediaInfo::applySnapshot(const Snapshot &rawSnapshot)
{
    Snapshot snapshot = rawSnapshot;
    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();

    if (snapshot.hasMedia) {
        m_lastStableSnapshotMs = nowMs;
    } else if (m_hasMedia) {
        const bool looksLikeTransientEmptySnapshot = snapshot.availablePlayers.isEmpty()
            && snapshot.availablePlayerLabels.isEmpty()
            && snapshot.selectedPlayer.isEmpty()
            && snapshot.targetPlayer.isEmpty()
            && snapshot.playerName.isEmpty()
            && snapshot.title.isEmpty()
            && snapshot.trackId.isEmpty()
            && snapshot.artist.isEmpty()
            && snapshot.status.isEmpty()
            && snapshot.artUrl.isEmpty()
            && snapshot.sourceUrl.isEmpty()
            && snapshot.browserVideoToken.isEmpty();
        if (looksLikeTransientEmptySnapshot && (nowMs - m_lastStableSnapshotMs) < kTransientEmptySnapshotGraceMs) {
            return;
        }
    }

    const bool activeBrowserVideoChanged = m_hasMedia
        && snapshot.hasMedia
        && snapshot.isVideo
        && m_selectedPlayer == snapshot.selectedPlayer
        && !snapshot.browserVideoToken.isEmpty()
        && snapshot.browserVideoToken != m_browserVideoToken;
    const QString browserTokenTitle = tokenTitlePart(snapshot.browserVideoToken);
    const bool likelyBrowserTokenMetadataLag = m_hasMedia
        && snapshot.hasMedia
        && snapshot.isVideo
        && m_selectedPlayer == snapshot.selectedPlayer
        && snapshot.playerName == "YouTube"
        && !browserTokenTitle.isEmpty()
        && !snapshot.title.isEmpty()
        && snapshot.title.toLower() != browserTokenTitle
        && snapshot.positionSeconds > 2.0;
    const bool likelyBrowserMetadataLag = m_hasMedia
        && snapshot.hasMedia
        && m_selectedPlayer == snapshot.selectedPlayer
        && snapshot.isVideo
        && (snapshot.positionSeconds + 4.0) < m_positionSeconds
        && snapshot.lengthSeconds > 0.0
        && qAbs(snapshot.lengthSeconds - m_lengthSeconds) < 0.001
        && snapshot.title == m_title
        && snapshot.sourceUrl == m_sourceUrl;
    const bool videoTrackChanged = snapshot.hasMedia
        && snapshot.isVideo
        && !snapshot.trackId.isEmpty()
        && snapshot.trackId != m_trackId;
    const bool likelyTrackDurationLag = videoTrackChanged
        && snapshot.positionSeconds < 5.0
        && snapshot.lengthSeconds > 0.0
        && qAbs(snapshot.lengthSeconds - m_lengthSeconds) < 0.001;
    const bool mediaIdentityChanged = m_hasMedia != snapshot.hasMedia
        || m_selectedPlayer != snapshot.selectedPlayer
        || m_playerName != snapshot.playerName
        || m_title != snapshot.title
        || m_trackId != snapshot.trackId
        || m_artist != snapshot.artist
        || m_artUrl != snapshot.artUrl
        || m_sourceUrl != snapshot.sourceUrl
        || m_browserVideoToken != snapshot.browserVideoToken
        || activeBrowserVideoChanged
        || likelyBrowserTokenMetadataLag
        || likelyBrowserMetadataLag
        || likelyTrackDurationLag;

    const bool changed = m_availablePlayers != snapshot.availablePlayers
        || m_availablePlayerLabels != snapshot.availablePlayerLabels
        || m_selectedPlayer != snapshot.selectedPlayer
        || m_targetPlayer != snapshot.targetPlayer
        || m_hasMedia != snapshot.hasMedia
        || m_playerName != snapshot.playerName
        || m_title != snapshot.title
        || m_trackId != snapshot.trackId
        || m_artist != snapshot.artist
        || m_status != snapshot.status
        || !qFuzzyCompare(m_positionSeconds + 1.0, snapshot.positionSeconds + 1.0)
        || !qFuzzyCompare(m_lengthSeconds + 1.0, snapshot.lengthSeconds + 1.0)
        || !qFuzzyCompare(m_volume + 1.0, snapshot.volume + 1.0)
        || m_artUrl != snapshot.artUrl
        || m_browserVideoToken != snapshot.browserVideoToken
        || m_isVideo != snapshot.isVideo;

    m_availablePlayers = snapshot.availablePlayers;
    m_availablePlayerLabels = snapshot.availablePlayerLabels;
    m_selectedPlayer = snapshot.selectedPlayer;
    m_targetPlayer = snapshot.targetPlayer;
    m_hasMedia = snapshot.hasMedia;
    m_playerName = snapshot.playerName;
    m_title = snapshot.title;
    m_trackId = snapshot.trackId;
    m_artist = snapshot.artist;
    m_status = snapshot.status;
    m_positionSeconds = snapshot.positionSeconds;
    m_lengthSeconds = snapshot.lengthSeconds;
    m_volume = snapshot.volume;
    m_artUrl = snapshot.artUrl;
    m_sourceUrl = snapshot.sourceUrl;
    m_browserVideoToken = snapshot.browserVideoToken;
    m_isVideo = snapshot.isVideo;

    if (changed) {
        emit mediaChanged();
    }

    if (!m_pollPaused && snapshot.hasMedia && mediaIdentityChanged) {
        QTimer::singleShot(80, this, &MediaInfo::refresh);
        QTimer::singleShot(120, this, &MediaInfo::refresh);
        QTimer::singleShot(180, this, &MediaInfo::refresh);
        QTimer::singleShot(360, this, &MediaInfo::refresh);
        QTimer::singleShot(760, this, &MediaInfo::refresh);
        QTimer::singleShot(1300, this, &MediaInfo::refresh);
    }

    const bool shouldBurstRefreshMetadata = !m_pollPaused
        && snapshot.hasMedia
        && snapshot.isVideo
        && (activeBrowserVideoChanged || likelyBrowserTokenMetadataLag || likelyBrowserMetadataLag || likelyTrackDurationLag);
    if (shouldBurstRefreshMetadata) {
        QTimer::singleShot(70, this, &MediaInfo::refresh);
        QTimer::singleShot(150, this, &MediaInfo::refresh);
        QTimer::singleShot(280, this, &MediaInfo::refresh);
        QTimer::singleShot(520, this, &MediaInfo::refresh);
        QTimer::singleShot(900, this, &MediaInfo::refresh);
        QTimer::singleShot(1500, this, &MediaInfo::refresh);
        QTimer::singleShot(2300, this, &MediaInfo::refresh);
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

    const QHash<QString, QString> statusesByPlayer =
        parseStatusByPlayer(runPlayerctl({"--all-players", "status", "--format", kStatusFormat}));
    const QHash<QString, QString> metadataByPlayer =
        parseMetadataByPlayer(runPlayerctl({"--all-players", "metadata", "--format", kMetadataFormat}));

    QStringList youtubeBrowserClasses;
    bool youtubeBrowserClassesLoaded = false;
    auto ensureYouTubeBrowserClasses = [&youtubeBrowserClasses, &youtubeBrowserClassesLoaded]() {
        if (!youtubeBrowserClassesLoaded) {
            youtubeBrowserClasses = browserClassesWithYouTubeTitle();
            youtubeBrowserClassesLoaded = true;
        }
    };

    for (const QString &player : listedPlayers) {
        QString playerStatus = statusesByPlayer.value(player);
        if (playerStatus.isEmpty()) {
            playerStatus = runPlayerctl({"-p", player, "status"});
        }
        if (playerStatus.isEmpty()) {
            continue;
        }

        QString metadata = metadataByPlayer.value(player);
        if (metadata.isEmpty()) {
            metadata = runPlayerctl({
                "-p", player,
                "metadata",
                "--format", kMetadataFormat
            });
        }

        const QStringList fields = metadata.split(QChar(kFieldSeparator));
        const QString rawPlayerName = fields.value(0).trimmed();
        const QString title = compactValue(fields.value(1));
        const QString sourceUrl = compactValue(fields.value(6)).toLower();
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
            || ([&]() -> bool {
                if (classNeedle.isEmpty()) {
                    return false;
                }
                ensureYouTubeBrowserClasses();
                return youtubeBrowserClasses.contains(classNeedle);
            })();
        const bool looksLikeNetflix = sourceUrl.contains("netflix.com")
            || titleLower.contains("netflix")
            || titleLower.endsWith(" - netflix")
            || titleLower.startsWith("netflix -");

        QString displayName = displayPlayerName(rawPlayerName, looksLikeYoutube, looksLikeNetflix, sourceUrl);
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

    QString selectedMetadataOut = selectedEntry.metadata;
    if (selectedMetadataOut.isEmpty()) {
        selectedMetadataOut = runPlayerctl({
            "-p", selectedPlayer,
            "metadata",
            "--format", kMetadataFormat
        });
    }
    const QString posOut = runPlayerctl({"-p", selectedPlayer, "position"});
    const QString volumeOut = runPlayerctl({"-p", selectedPlayer, "volume"});

    const QString metadata = selectedMetadataOut.isEmpty() ? selectedEntry.metadata : selectedMetadataOut;
    const QStringList fields = metadata.split(QChar(kFieldSeparator));
    const QString rawPlayerName = fields.value(0).trimmed();
    const QString title = compactValue(fields.value(1));
    const QString trackId = compactValue(fields.value(2));
    const QString artist = compactValue(fields.value(3));
    const double lengthSeconds = parseMicroseconds(fields.value(4));
    const QString artUrl = compactValue(fields.value(5));
    const QString sourceUrl = compactValue(fields.value(6)).toLower();
    const QString titleLower = title.toLower();
    const QString lowerPlayerName = rawPlayerName.toLower();
    const bool looksLikeNetflix = sourceUrl.contains("netflix.com")
        || titleLower.contains("netflix")
        || titleLower.endsWith(" - netflix")
        || titleLower.startsWith("netflix -");
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
        || ([&]() -> bool {
            if (classNeedle.isEmpty()) {
                return false;
            }
            ensureYouTubeBrowserClasses();
            return youtubeBrowserClasses.contains(classNeedle);
        })();
    const bool applyNetflixBranding = looksLikeNetflix && !looksLikeYoutube;

    snapshot.playerName = displayPlayerName(rawPlayerName, looksLikeYoutube, looksLikeNetflix, sourceUrl);
    snapshot.title = title;
    snapshot.trackId = trackId;
    snapshot.artist = applyNetflixBranding ? "Netflix" : artist;
    snapshot.status = statusOut;
    snapshot.positionSeconds = qMax(0.0, posOut.toDouble());
    snapshot.lengthSeconds = lengthSeconds;
    if (!classNeedle.isEmpty() && looksLikeYoutube) {
        const BrowserPlaybackTimes browserTimes = browserPlaybackTimesForClass(classNeedle);
        const bool mprisPositionLooksStale = snapshot.positionSeconds <= 0.05 && browserTimes.hasPosition && browserTimes.positionSeconds > 0.5;
        const bool mprisLengthMissing = snapshot.lengthSeconds <= 0.0 && browserTimes.hasLength && browserTimes.lengthSeconds > 0.0;
        if (mprisPositionLooksStale) {
            snapshot.positionSeconds = browserTimes.positionSeconds;
        }
        if (mprisLengthMissing) {
            snapshot.lengthSeconds = browserTimes.lengthSeconds;
        }
    }
    snapshot.volume = qBound(0.0, volumeOut.toDouble(), 1.0);
    snapshot.artUrl = applyNetflixBranding
        ? QUrl::fromLocalFile(QDir::homePath() + "/.local/share/icons/netflix.png").toString()
        : artUrl;
    snapshot.sourceUrl = sourceUrl;
    snapshot.isVideo = lowerPlayerName.contains("vlc")
        || lowerPlayerName.contains("mpv")
        || looksLikeYoutube
        || sourceUrl.contains("vimeo.com")
        || sourceUrl.contains("twitch.tv")
        || sourceUrl.endsWith(".mp4")
        || sourceUrl.endsWith(".webm")
        || sourceUrl.endsWith(".mkv");
    if (!classNeedle.isEmpty() && snapshot.isVideo) {
        QString activeBrowserToken = browserVideoTokenForClass(classNeedle);
        if (activeBrowserToken.isEmpty()) {
            activeBrowserToken = activeBrowserVideoToken();
        }
        const QString prefix = classNeedle + "|";
        if (activeBrowserToken.startsWith(prefix)) {
            snapshot.browserVideoToken = activeBrowserToken;
        }
    }
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

QString MediaInfo::displayPlayerName(const QString &rawPlayerName, bool looksLikeYoutube, bool looksLikeNetflix, const QString &sourceUrlLower)
{
    if (looksLikeYoutube || sourceUrlLower.contains("youtube.com") || sourceUrlLower.contains("youtu.be")) {
        return "YouTube";
    }
    if (looksLikeNetflix || sourceUrlLower.contains("netflix.com")) {
        return "Netflix";
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

QString MediaInfo::normalizeBrowserWindowTitle(const QString &rawTitle)
{
    QString title = compactValue(rawTitle);
    if (title.isEmpty()) {
        return {};
    }

    auto stripSuffix = [&title](const QString &suffix) {
        if (title.endsWith(suffix, Qt::CaseInsensitive)) {
            title.chop(suffix.size());
            title = title.trimmed();
        }
    };
    stripSuffix(" - Brave");
    stripSuffix(" - Chromium");
    stripSuffix(" - Google Chrome");
    stripSuffix(" - Mozilla Firefox");
    stripSuffix(" - YouTube");
    stripSuffix(" - Netflix");
    stripSuffix(" - Twitch");
    stripSuffix(" - Vimeo");
    if (title.isEmpty()) {
        return {};
    }

    static const QRegularExpression leadingPlaybackTimes(
        R"(^\s*(?:(?:\d{1,2}:)?\d{1,2}:\d{2}\s*/\s*(?:\d{1,2}:)?\d{1,2}:\d{2}|(?:\d{1,2}:)?\d{1,2}:\d{2}|LIVE)\s*[\-|:]\s*)",
        QRegularExpression::CaseInsensitiveOption
    );
    title.remove(leadingPlaybackTimes);

    static const QRegularExpression leadingDecorators(R"(^[\s\-\|:]+)");
    title.remove(leadingDecorators);
    title = title.trimmed();
    if (title.isEmpty()) {
        return {};
    }

    return title.toLower();
}

QString MediaInfo::browserVideoTokenForClass(const QString &classNeedle)
{
    if (classNeedle.isEmpty()) {
        return {};
    }

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

    const QJsonDocument doc = QJsonDocument::fromJson(proc.readAllStandardOutput());
    if (!doc.isArray()) {
        return {};
    }

    const QJsonArray clients = doc.array();
    QString bestToken;
    int bestSiteRank = 99;
    int bestFocusRank = 1000000;
    for (const QJsonValue &entry : clients) {
        if (!entry.isObject()) {
            continue;
        }

        const QJsonObject obj = entry.toObject();
        const QString windowClass = obj.value("class").toString().toLower();
        if (!windowClass.contains(classNeedle)) {
            continue;
        }

        const QString normalizedTitle = normalizeBrowserWindowTitle(obj.value("title").toString());
        if (normalizedTitle.isEmpty()) {
            continue;
        }

        const int siteRank = mediaSiteRankFromTitle(normalizedTitle);

        int focusRank = 1000000;
        const QJsonValue focusHistoryValue = obj.value("focusHistoryID");
        if (focusHistoryValue.isDouble()) {
            const int parsed = focusHistoryValue.toInt();
            if (parsed >= 0) {
                focusRank = parsed;
            }
        } else if (obj.value("focused").toBool(false)) {
            focusRank = 0;
        }

        if (siteRank < bestSiteRank || (siteRank == bestSiteRank && focusRank < bestFocusRank)) {
            bestSiteRank = siteRank;
            bestFocusRank = focusRank;
            bestToken = classNeedle + "|" + normalizedTitle;
        }
    }

    return bestToken;
}

MediaInfo::BrowserPlaybackTimes MediaInfo::parseBrowserPlaybackTimesFromTitle(const QString &rawTitle)
{
    BrowserPlaybackTimes times;
    const QString title = compactValue(rawTitle);
    if (title.isEmpty()) {
        return times;
    }

    static const QRegularExpression fullPattern(
        R"(^\s*((?:\d{1,2}:)?\d{1,2}:\d{2})\s*/\s*((?:\d{1,2}:)?\d{1,2}:\d{2}))"
    );
    const QRegularExpressionMatch fullMatch = fullPattern.match(title);
    if (fullMatch.hasMatch()) {
        const double parsedPosition = parseTimecodeSeconds(fullMatch.captured(1));
        const double parsedLength = parseTimecodeSeconds(fullMatch.captured(2));
        if (parsedPosition >= 0.0) {
            times.positionSeconds = parsedPosition;
            times.hasPosition = true;
        }
        if (parsedLength > 0.0) {
            times.lengthSeconds = parsedLength;
            times.hasLength = true;
        }
        return times;
    }

    static const QRegularExpression shortPattern(
        R"(^\s*((?:\d{1,2}:)?\d{1,2}:\d{2})\s*[\-|:]\s*)",
        QRegularExpression::CaseInsensitiveOption
    );
    const QRegularExpressionMatch shortMatch = shortPattern.match(title);
    if (shortMatch.hasMatch()) {
        const double parsedPosition = parseTimecodeSeconds(shortMatch.captured(1));
        if (parsedPosition >= 0.0) {
            times.positionSeconds = parsedPosition;
            times.hasPosition = true;
        }
    }
    return times;
}

double MediaInfo::parseTimecodeSeconds(const QString &rawTimecode)
{
    const QStringList parts = rawTimecode.split(':');
    if (parts.size() != 2 && parts.size() != 3) {
        return -1.0;
    }

    bool ok = false;
    int hours = 0;
    int minutes = 0;
    int seconds = 0;

    if (parts.size() == 2) {
        minutes = parts.at(0).toInt(&ok);
        if (!ok) {
            return -1.0;
        }
        seconds = parts.at(1).toInt(&ok);
        if (!ok) {
            return -1.0;
        }
    } else {
        hours = parts.at(0).toInt(&ok);
        if (!ok) {
            return -1.0;
        }
        minutes = parts.at(1).toInt(&ok);
        if (!ok) {
            return -1.0;
        }
        seconds = parts.at(2).toInt(&ok);
        if (!ok) {
            return -1.0;
        }
    }

    if (hours < 0 || minutes < 0 || seconds < 0 || minutes > 59 || seconds > 59) {
        return -1.0;
    }

    return static_cast<double>(hours * 3600 + minutes * 60 + seconds);
}

MediaInfo::BrowserPlaybackTimes MediaInfo::browserPlaybackTimesForClass(const QString &classNeedle)
{
    BrowserPlaybackTimes bestTimes;
    if (classNeedle.isEmpty()) {
        return bestTimes;
    }

    QProcess proc;
    proc.start(QString::fromUtf8(kHyprctlBin), {"-j", "clients"});
    if (!proc.waitForStarted(kTimeoutMs)) {
        return bestTimes;
    }
    if (!proc.waitForFinished(kTimeoutMs)) {
        proc.kill();
        proc.waitForFinished();
        return bestTimes;
    }
    if (proc.exitStatus() != QProcess::NormalExit || proc.exitCode() != 0) {
        return bestTimes;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(proc.readAllStandardOutput());
    if (!doc.isArray()) {
        return bestTimes;
    }

    int bestSiteRank = 99;
    int bestFocusRank = 1000000;
    const QJsonArray clients = doc.array();
    for (const QJsonValue &entry : clients) {
        if (!entry.isObject()) {
            continue;
        }

        const QJsonObject obj = entry.toObject();
        const QString windowClass = obj.value("class").toString().toLower();
        if (!windowClass.contains(classNeedle)) {
            continue;
        }

        const QString rawTitle = obj.value("title").toString();
        const QString titleLower = rawTitle.toLower();
        const BrowserPlaybackTimes parsedTimes = parseBrowserPlaybackTimesFromTitle(rawTitle);
        if (!parsedTimes.hasPosition && !parsedTimes.hasLength) {
            continue;
        }

        const int siteRank = mediaSiteRankFromTitle(titleLower);
        int focusRank = 1000000;
        const QJsonValue focusHistoryValue = obj.value("focusHistoryID");
        if (focusHistoryValue.isDouble()) {
            const int parsed = focusHistoryValue.toInt();
            if (parsed >= 0) {
                focusRank = parsed;
            }
        } else if (obj.value("focused").toBool(false)) {
            focusRank = 0;
        }

        if (siteRank < bestSiteRank || (siteRank == bestSiteRank && focusRank < bestFocusRank)) {
            bestSiteRank = siteRank;
            bestFocusRank = focusRank;
            bestTimes = parsedTimes;
        }
    }

    return bestTimes;
}

QString MediaInfo::tokenTitlePart(const QString &token)
{
    const int separatorIndex = token.indexOf('|');
    if (separatorIndex < 0 || separatorIndex >= (token.size() - 1)) {
        return {};
    }
    return token.mid(separatorIndex + 1).trimmed();
}

QString MediaInfo::activeBrowserVideoToken()
{
    QProcess proc;
    proc.start(QString::fromUtf8(kHyprctlBin), {"-j", "activewindow"});
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

    const QJsonDocument doc = QJsonDocument::fromJson(proc.readAllStandardOutput());
    if (!doc.isObject()) {
        return {};
    }

    const QJsonObject obj = doc.object();
    const QString windowClass = obj.value("class").toString().toLower();
    QString classKey;
    if (windowClass.contains("brave")) {
        classKey = "brave";
    } else if (windowClass.contains("firefox")) {
        classKey = "firefox";
    } else if (windowClass.contains("chrom")) {
        classKey = "chrom";
    } else {
        return {};
    }

    const QString normalizedTitle = normalizeBrowserWindowTitle(obj.value("title").toString());
    if (normalizedTitle.isEmpty()) {
        return {};
    }
    return classKey + "|" + normalizedTitle;
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
