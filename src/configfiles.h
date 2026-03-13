#pragma once

#include <QObject>
#include <QString>

class QQmlEngine;

class ConfigFiles : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QObject* theme READ theme NOTIFY themeChanged)
    Q_PROPERTY(QObject* style READ style NOTIFY styleChanged)

public:
    explicit ConfigFiles(QQmlEngine *engine, QObject *parent = nullptr);

    QObject *theme() const;
    QObject *style() const;

    Q_INVOKABLE void reload();

signals:
    void themeChanged();
    void styleChanged();

private:
    QObject *loadObject(const QString &path, const char *label);
    static QByteArray normalizedSource(const QString &path);

    QQmlEngine *m_engine;
    QObject *m_theme = nullptr;
    QObject *m_style = nullptr;
};
