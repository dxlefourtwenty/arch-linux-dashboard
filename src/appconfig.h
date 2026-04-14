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
    struct TaskRule {
        QString task;
        QString recurrenceType;
        QString recurrenceValue;
        QStringList weeklyDays;
    };

    void load();
    void refreshTasksCache() const;

    QString m_username;
    QString m_profileImage;
    QString m_outputName;
    mutable QVector<TaskRule> m_taskRules;
    mutable QDateTime m_tasksLastModified;
    mutable QString m_tasksPath;
    mutable bool m_tasksCacheLoaded = false;
};
