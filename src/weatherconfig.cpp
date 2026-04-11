#include "weatherconfig.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <cmath>
#include <limits>

WeatherConfig::WeatherConfig(QObject *parent)
    : QObject(parent)
{
    m_path = QStandardPaths::writableLocation(QStandardPaths::HomeLocation)
        + "/.config/dashboard/weather.json";
    load();
}

QVariantList WeatherConfig::locations() const
{
    return m_locations;
}

int WeatherConfig::selectedIndex() const
{
    return m_selectedIndex;
}

void WeatherConfig::reload()
{
    load();
    emit configChanged();
}

void WeatherConfig::selectIndex(int index)
{
    if (index < 0 || index >= m_locations.size()) {
        return;
    }

    if (m_selectedIndex == index) {
        return;
    }

    m_selectedIndex = index;
    save();
    emit configChanged();
}

QVariantMap WeatherConfig::defaultLocation()
{
    return QVariantMap{
        {"displayName", "Covina, CA"},
        {"latitude", 34.09},
        {"longitude", -117.89}
    };
}

void WeatherConfig::load()
{
    const QString configDir = QDir::homePath() + "/.config/dashboard";
    QDir().mkpath(configDir);

    QFile file(m_path);
    if (!file.exists()) {
        m_locations = QVariantList{defaultLocation()};
        m_selectedIndex = 0;
        save();
        return;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        m_locations = QVariantList{defaultLocation()};
        m_selectedIndex = 0;
        return;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();

    QJsonArray rawLocations;
    int nextSelectedIndex = 0;

    if (doc.isObject()) {
        const QJsonObject obj = doc.object();
        rawLocations = obj.value("locations").toArray();
        nextSelectedIndex = obj.value("selectedIndex").toInt(0);
    } else if (doc.isArray()) {
        rawLocations = doc.array();
    }

    QVariantList nextLocations;
    for (const QJsonValue &value : rawLocations) {
        if (!value.isObject()) {
            continue;
        }

        const QJsonObject entry = value.toObject();
        const QString displayName = entry.value("displayName").toString().trimmed();
        if (displayName.isEmpty()) {
            continue;
        }

        const double latitude = entry.value("latitude").toDouble(std::numeric_limits<double>::quiet_NaN());
        const double longitude = entry.value("longitude").toDouble(std::numeric_limits<double>::quiet_NaN());
        if (!std::isfinite(latitude) || !std::isfinite(longitude)) {
            continue;
        }

        nextLocations.append(QVariantMap{
            {"displayName", displayName},
            {"latitude", latitude},
            {"longitude", longitude}
        });
    }

    if (nextLocations.isEmpty()) {
        nextLocations = QVariantList{defaultLocation()};
        nextSelectedIndex = 0;
    }

    if (nextSelectedIndex < 0 || nextSelectedIndex >= nextLocations.size()) {
        nextSelectedIndex = 0;
    }

    m_locations = nextLocations;
    m_selectedIndex = nextSelectedIndex;
}

void WeatherConfig::save() const
{
    QJsonArray locationsArray;
    for (const QVariant &value : m_locations) {
        const QVariantMap location = value.toMap();
        locationsArray.append(QJsonObject{
            {"displayName", location.value("displayName").toString()},
            {"latitude", location.value("latitude").toDouble()},
            {"longitude", location.value("longitude").toDouble()}
        });
    }

    const QJsonObject root{
        {"selectedIndex", m_selectedIndex},
        {"locations", locationsArray}
    };

    QFile file(m_path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }

    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    file.close();
}
