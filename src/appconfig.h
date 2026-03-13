#pragma once

#include <QObject>
#include <QString>
#include <QStringList>

class AppConfig : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString username READ username NOTIFY configChanged)
    Q_PROPERTY(QString profileImage READ profileImage NOTIFY configChanged)
    Q_PROPERTY(QString outputName READ outputName NOTIFY configChanged)

public:
    explicit AppConfig(QObject *parent = nullptr);

    QString username() const;
    QString profileImage() const;
    QString outputName() const;

    Q_INVOKABLE void reload();
    Q_INVOKABLE QStringList tasksForDate(const QString &dateKey) const;

signals:
    void configChanged();

private:
    void load();

    QString m_username;
    QString m_profileImage;
    QString m_outputName;
};
