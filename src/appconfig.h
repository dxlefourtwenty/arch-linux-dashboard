#pragma once

#include <QObject>
#include <QDateTime>
#include <QString>
#include <QStringList>
#include <QVector>

class AppConfig : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString username READ username NOTIFY configChanged)
    Q_PROPERTY(QString profileImage READ profileImage NOTIFY configChanged)
    Q_PROPERTY(QString outputName READ outputName NOTIFY configChanged)
    Q_PROPERTY(bool use24Hour READ use24Hour NOTIFY configChanged)

public:
    explicit AppConfig(QObject *parent = nullptr);

    QString username() const;
    QString profileImage() const;
    QString outputName() const;
    bool use24Hour() const;

    Q_INVOKABLE void reload();
    Q_INVOKABLE void setUse24Hour(bool enabled);
    Q_INVOKABLE QStringList tasksForDate(const QString &dateKey) const;

signals:
    void configChanged();

private:
    struct TaskRule {
        QString task;
        QString recurrenceType;
        QString recurrenceValue;
        QStringList weeklyDays;
    };

    void load();
    void save() const;
    void refreshTasksCache() const;

    QString m_path;
    QString m_username;
    QString m_profileImage;
    QString m_outputName;
    bool m_use24Hour = false;
    mutable QVector<TaskRule> m_taskRules;
    mutable QDateTime m_tasksLastModified;
    mutable QString m_tasksPath;
    mutable bool m_tasksCacheLoaded = false;
};
