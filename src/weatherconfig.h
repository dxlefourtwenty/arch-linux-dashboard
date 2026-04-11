#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QString>

class WeatherConfig : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList locations READ locations NOTIFY configChanged)
    Q_PROPERTY(int selectedIndex READ selectedIndex NOTIFY configChanged)

public:
    explicit WeatherConfig(QObject *parent = nullptr);

    QVariantList locations() const;
    int selectedIndex() const;

    Q_INVOKABLE void reload();
    Q_INVOKABLE void selectIndex(int index);

signals:
    void configChanged();

private:
    void load();
    void save() const;
    static QVariantMap defaultLocation();

    QString m_path;
    QVariantList m_locations;
    int m_selectedIndex = 0;
};
