#include "appconfig.h"

#include <QDate>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

AppConfig::AppConfig(QObject *parent)
    : QObject(parent)
{
    load();
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

void AppConfig::reload()
{
    load();
    emit configChanged();
}

QStringList AppConfig::tasksForDate(const QString &dateKey) const
{
    QStringList out;

    const QDate date = QDate::fromString(dateKey, "yyyy-MM-dd");
    if (!date.isValid()) {
        return out;
    }

    static const QStringList kWeekdays{
        "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
    };
    const QString weekdayShort = kWeekdays.at(date.dayOfWeek() - 1);

    const QString path =
        QStandardPaths::writableLocation(
            QStandardPaths::HomeLocation)
        + "/.config/dashboard/tasks.json";

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        return out;
    }

    const auto doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isArray()) {
        return out;
    }

    const QJsonArray arr = doc.array();
    for (const auto &v : arr) {
        if (!v.isObject()) {
            continue;
        }

        const QJsonObject obj = v.toObject();
        const QString task = obj.value("task").toString().trimmed();
        if (task.isEmpty()) {
            continue;
        }

        const QString recurrenceType =
            obj.value("recurrence_type").toString();
        const QString recurrenceValue =
            obj.value("recurrence_value").toString();

        bool include = false;
        if (recurrenceType == "daily") {
            include = true;
        } else if (recurrenceType == "weekly") {
            const QStringList weeklyDays =
                recurrenceValue.split(',', Qt::SkipEmptyParts);
            for (const QString &day : weeklyDays) {
                if (day.trimmed() == weekdayShort) {
                    include = true;
                    break;
                }
            }
        } else if (recurrenceType == "date") {
            include = (recurrenceValue == dateKey);
        }

        if (include) {
            out.append(task);
        }
    }

    return out;
}

void AppConfig::load()
{
    QString path =
        QStandardPaths::writableLocation(
            QStandardPaths::HomeLocation)
        + "/.config/dashboard/config.json";

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return;

    auto doc = QJsonDocument::fromJson(file.readAll());
    auto obj = doc.object();

    m_username = obj["username"].toString("user");
    m_profileImage = obj["profileImage"].toString("");
    m_outputName = obj["outputName"].toString("");
}
