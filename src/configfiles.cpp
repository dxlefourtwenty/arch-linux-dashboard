#include "configfiles.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QUrl>

ConfigFiles::ConfigFiles(QQmlEngine *engine, QObject *parent)
    : QObject(parent)
    , m_engine(engine)
{
    reload();
}

QObject *ConfigFiles::theme() const
{
    return m_theme;
}

QObject *ConfigFiles::style() const
{
    return m_style;
}

void ConfigFiles::reload()
{
    const QString configDir = QDir::homePath() + "/.config/dashboard";
    QObject *nextTheme = loadObject(configDir + "/theme.qml", "theme");
    QObject *nextStyle = loadObject(configDir + "/style.qml", "style");

    if (nextTheme) {
        if (m_theme) {
            m_theme->deleteLater();
        }
        m_theme = nextTheme;
        emit themeChanged();
    }

    if (nextStyle) {
        if (m_style) {
            m_style->deleteLater();
        }
        m_style = nextStyle;
        emit styleChanged();
    }
}

QObject *ConfigFiles::loadObject(const QString &path, const char *label)
{
    if (!m_engine) {
        qWarning() << "Missing QQmlEngine for" << label;
        return nullptr;
    }

    const QByteArray source = normalizedSource(path);
    if (source.isEmpty()) {
        qWarning() << "Failed to read" << label << "from" << path;
        return nullptr;
    }

    QQmlComponent component(m_engine);
    component.setData(source, QUrl::fromLocalFile(path));

    if (component.isError()) {
        qWarning() << "Failed to load" << label << "from" << path;
        for (const QQmlError &error : component.errors()) {
            qWarning().noquote() << error.toString();
        }
        return nullptr;
    }

    QObject *object = component.create(m_engine->rootContext());
    if (!object) {
        qWarning() << "Failed to create" << label << "from" << path;
        for (const QQmlError &error : component.errors()) {
            qWarning().noquote() << error.toString();
        }
        return nullptr;
    }

    object->setParent(this);
    return object;
}

QByteArray ConfigFiles::normalizedSource(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }

    QByteArray source = file.readAll();
    const QList<QByteArray> lines = source.split('\n');
    QByteArray normalized;
    bool removedSingleton = false;

    for (const QByteArray &line : lines) {
        if (!removedSingleton && line.trimmed() == "pragma Singleton") {
            removedSingleton = true;
            continue;
        }

        if (!normalized.isEmpty()) {
            normalized += '\n';
        }
        normalized += line;
    }

    return normalized;
}
