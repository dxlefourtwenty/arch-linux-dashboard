#include "appconfig.h"

#include <QDate>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

AppConfig::AppConfig(QObject *parent)
    : QObject(parent)
{
    m_path = QStandardPaths::writableLocation(
        QStandardPaths::HomeLocation)
        + "/.config/dashboard/config.json";
    load();
    refreshTasksCache();
}

QString AppConfig::username() const
{
    return m_username;
}

QString AppConfig::profileImage() const
{
    return m_profileImage;
}

QString AppConfig::outputName() const
{
    return m_outputName;
}

bool AppConfig::use24Hour() const
{
    return m_use24Hour;
}

void AppConfig::reload()
{
    load();
    emit configChanged();
}

void AppConfig::setUse24Hour(bool enabled)
{
    if (m_use24Hour == enabled) {
        return;
    }

    m_use24Hour = enabled;
    save();
    emit configChanged();
}

QStringList AppConfig::tasksForDate(const QString &dateKey) const
{
    refreshTasksCache();

    QStringList out;

    const QDate date = QDate::fromString(dateKey, "yyyy-MM-dd");
    if (!date.isValid()) {
        return out;
    }

    static const QStringList kWeekdays{
        "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
    };
    const QString weekdayShort = kWeekdays.at(date.dayOfWeek() - 1);

    for (const TaskRule &rule : m_taskRules) {
        bool include = false;
        if (rule.recurrenceType == "daily") {
            include = true;
        } else if (rule.recurrenceType == "weekly") {
            for (const QString &day : rule.weeklyDays) {
                if (day == weekdayShort) {
                    include = true;
                    break;
                }
            }
        } else if (rule.recurrenceType == "date") {
            include = (rule.recurrenceValue == dateKey);
        }

        if (include) {
            out.append(rule.task);
        }
    }

    return out;
}

void AppConfig::refreshTasksCache() const
{
    const QString path =
        QStandardPaths::writableLocation(
            QStandardPaths::HomeLocation)
        + "/.config/dashboard/tasks.json";

    const QFileInfo info(path);
    const QDateTime lastModified = info.exists()
        ? info.lastModified()
        : QDateTime();

    if (m_tasksCacheLoaded
        && m_tasksPath == path
        && m_tasksLastModified == lastModified) {
        return;
    }

    m_taskRules.clear();
    m_tasksPath = path;
    m_tasksLastModified = lastModified;
    m_tasksCacheLoaded = true;

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        return;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isArray()) {
        return;
    }

    const QJsonArray arr = doc.array();
    m_taskRules.reserve(arr.size());
    for (const QJsonValue &v : arr) {
        if (!v.isObject()) {
            continue;
        }

        const QJsonObject obj = v.toObject();
        const QString task = obj.value("task").toString().trimmed();
        if (task.isEmpty()) {
            continue;
        }

        TaskRule rule;
        rule.task = task;
        rule.recurrenceType = obj.value("recurrence_type").toString();
        rule.recurrenceValue = obj.value("recurrence_value").toString();

        if (rule.recurrenceType == "weekly" && !rule.recurrenceValue.isEmpty()) {
            const QStringList weeklyDays = rule.recurrenceValue.split(',', Qt::SkipEmptyParts);
            for (const QString &day : weeklyDays) {
                const QString trimmed = day.trimmed();
                if (!trimmed.isEmpty()) {
                    rule.weeklyDays.append(trimmed);
                }
            }
        }

        m_taskRules.append(rule);
    }
}

void AppConfig::load()
{
    QFile file(m_path);
    if (!file.open(QIODevice::ReadOnly)) {
        m_username = "user";
        m_profileImage = "";
        m_outputName = "";
        m_use24Hour = false;
        return;
    }

    auto doc = QJsonDocument::fromJson(file.readAll());
    auto obj = doc.object();

    m_username = obj["username"].toString("user");
    m_profileImage = obj["profileImage"].toString("");
    m_outputName = obj["outputName"].toString("");
    m_use24Hour = obj["use24Hour"].toBool(false);
}

void AppConfig::save() const
{
    const QString configDir = QFileInfo(m_path).absolutePath();
    if (!configDir.isEmpty()) {
        QDir().mkpath(configDir);
    }

    QJsonObject obj;
    QFile inputFile(m_path);
    if (inputFile.open(QIODevice::ReadOnly)) {
        const QJsonDocument inputDoc = QJsonDocument::fromJson(inputFile.readAll());
        if (inputDoc.isObject()) {
            obj = inputDoc.object();
        }
    }

    obj.insert("username", m_username);
    obj.insert("profileImage", m_profileImage);
    obj.insert("outputName", m_outputName);
    obj.insert("use24Hour", m_use24Hour);

    QFile file(m_path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }

    file.write(QJsonDocument(obj).toJson(QJsonDocument::Indented));
}
