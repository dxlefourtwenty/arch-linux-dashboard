#include "configfiles.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QMetaProperty>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QStringList>
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
        if (updateInPlace(m_theme, nextTheme)) {
            nextTheme->deleteLater();
        } else {
            if (m_theme) {
                m_theme->deleteLater();
            }
            m_theme = nextTheme;
            emit themeChanged();
        }
    }

    if (nextStyle) {
        if (updateInPlace(m_style, nextStyle)) {
            nextStyle->deleteLater();
        } else {
            if (m_style) {
                m_style->deleteLater();
            }
            m_style = nextStyle;
            emit styleChanged();
        }
    }
}

bool ConfigFiles::canUpdateInPlace(QObject *current, QObject *next)
{
    return current
        && next
        && hasSameConfigProperties(current, next);
}

bool ConfigFiles::updateInPlace(QObject *current, QObject *next)
{
    if (!canUpdateInPlace(current, next)) {
        return false;
    }

    const QMetaObject *nextMeta = next->metaObject();
    for (const QString &name : configPropertyNames(next)) {
        const int nextIndex = nextMeta->indexOfProperty(name.toUtf8().constData());
        if (nextIndex < 0) {
            continue;
        }

        current->setProperty(
            name.toUtf8().constData(),
            nextMeta->property(nextIndex).read(next)
        );
    }

    return true;
}

bool ConfigFiles::hasSameConfigProperties(QObject *current, QObject *next)
{
    QStringList currentNames = configPropertyNames(current);
    QStringList nextNames = configPropertyNames(next);
    currentNames.sort();
    nextNames.sort();

    if (currentNames != nextNames) {
        return false;
    }

    const QMetaObject *currentMeta = current->metaObject();
    const QMetaObject *nextMeta = next->metaObject();
    for (const QString &name : nextNames) {
        const int currentIndex = currentMeta->indexOfProperty(name.toUtf8().constData());
        const int nextIndex = nextMeta->indexOfProperty(name.toUtf8().constData());
        if (currentIndex < 0 || nextIndex < 0) {
            return false;
        }

        const QMetaProperty currentProperty = currentMeta->property(currentIndex);
        const QMetaProperty nextProperty = nextMeta->property(nextIndex);
        if (!currentProperty.isWritable()
            || currentProperty.metaType() != nextProperty.metaType()) {
            return false;
        }
    }

    return true;
}

QStringList ConfigFiles::configPropertyNames(QObject *object)
{
    QStringList names;
    if (!object) {
        return names;
    }

    const QMetaObject *meta = object->metaObject();
    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        const QMetaProperty property = meta->property(i);
        if (property.isWritable()) {
            names << QString::fromUtf8(property.name());
        }
    }

    return names;
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
