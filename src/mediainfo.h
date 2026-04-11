#pragma once

#include <QObject>
#include <QStringList>
#include <QTimer>

class MediaInfo : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString playerName READ playerName NOTIFY mediaChanged)
    Q_PROPERTY(QStringList availablePlayers READ availablePlayers NOTIFY mediaChanged)
    Q_PROPERTY(QStringList availablePlayerLabels READ availablePlayerLabels NOTIFY mediaChanged)
    Q_PROPERTY(QString selectedPlayer READ selectedPlayer NOTIFY mediaChanged)
    Q_PROPERTY(QString title READ title NOTIFY mediaChanged)
    Q_PROPERTY(QString artist READ artist NOTIFY mediaChanged)
    Q_PROPERTY(QString status READ status NOTIFY mediaChanged)
    Q_PROPERTY(double positionSeconds READ positionSeconds NOTIFY mediaChanged)
    Q_PROPERTY(double lengthSeconds READ lengthSeconds NOTIFY mediaChanged)
    Q_PROPERTY(double volume READ volume NOTIFY mediaChanged)
    Q_PROPERTY(QString artUrl READ artUrl NOTIFY mediaChanged)
    Q_PROPERTY(bool isVideo READ isVideo NOTIFY mediaChanged)
    Q_PROPERTY(bool hasMedia READ hasMedia NOTIFY mediaChanged)

public:
    explicit MediaInfo(QObject *parent = nullptr);

    QString playerName() const { return m_playerName; }
    QStringList availablePlayers() const { return m_availablePlayers; }
    QStringList availablePlayerLabels() const { return m_availablePlayerLabels; }
    QString selectedPlayer() const { return m_selectedPlayer; }
    QString title() const { return m_title; }
    QString artist() const { return m_artist; }
    QString status() const { return m_status; }
    double positionSeconds() const { return m_positionSeconds; }
    double lengthSeconds() const { return m_lengthSeconds; }
    double volume() const { return m_volume; }
    QString artUrl() const { return m_artUrl; }
    bool isVideo() const { return m_isVideo; }
    bool hasMedia() const { return m_hasMedia; }

    Q_INVOKABLE void playPause();
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void seekToRatio(double ratio);
    Q_INVOKABLE void seekRelative(double offsetSeconds);
    Q_INVOKABLE void setVolume(double volume);
    Q_INVOKABLE void selectPlayer(const QString &playerId);
    Q_INVOKABLE void selectPlayerAt(int index);

public slots:
    void refresh();

signals:
    void mediaChanged();

private:
    QString runPlayerctl(const QStringList &args) const;
    void sendPlayerctl(const QStringList &args) const;
    QString currentPlayerArg() const;
    static QString compactValue(const QString &value);
    static QString displayPlayerName(const QString &rawPlayerName, const QString &sourceUrlLower);
    static bool hyprClientsShowYouTubeForBrowser(const QString &rawPlayerName);
    static double parseMicroseconds(const QString &raw);

    QTimer m_pollTimer;

    QString m_targetPlayer;
    QStringList m_availablePlayers;
    QStringList m_availablePlayerLabels;
    QString m_selectedPlayer;
    QString m_playerName;
    QString m_title;
    QString m_artist;
    QString m_status;
    double m_positionSeconds = 0.0;
    double m_lengthSeconds = 0.0;
    double m_volume = 0.0;
    QString m_artUrl;
    bool m_isVideo = false;
    bool m_hasMedia = false;
};
