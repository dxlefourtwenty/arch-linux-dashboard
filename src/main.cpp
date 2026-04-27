#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QObject>
#include <QScreen>
#include <QWindow>
#include <QFileSystemWatcher>
#include <QTimer>
#include <QDir>
#include <QFile>
#include <QStringList>
#include <QRegion>
#include <QStandardPaths>
#include <QVariant>
#include <algorithm>
#include <atomic>
#include <functional>
#include <csignal>
#include <QQmlContext>
#include <LayerShellQt/window.h>
#include "systeminfo.h"
#include "appconfig.h"
#include "configfiles.h"
#include "mediainfo.h"
#include "audiospectrum.h"
#include "weatherconfig.h"

static QObject *g_root = nullptr;
static std::atomic_bool g_reloadRequested = false;

static QScreen *preferredScreen(QGuiApplication &app, const QString &outputName)
{
    if (!outputName.isEmpty()) {
        for (QScreen *screen : app.screens()) {
            if (screen && screen->name() == outputName) {
                return screen;
            }
        }
    }

    return app.primaryScreen();
}

static int initialTabIndexFromEnvironment()
{
    const QString tab = qEnvironmentVariable("TOPDASH_INITIAL_TAB").trimmed().toLower();

    if (tab == "media") return 1;
    if (tab == "performance") return 2;
    if (tab == "weather") return 3;

    return 0;
}

static bool initialOpenFromEnvironment()
{
    const QString value = qEnvironmentVariable("TOPDASH_START_OPEN").trimmed().toLower();
    return value == "1" || value == "true" || value == "yes";
}

static QString tabCommandPath()
{
    const QString runtimePath = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    if (!runtimePath.isEmpty()) {
        return runtimePath + "/topdash-tab";
    }

    return "/tmp/topdash-tab";
}

static int tabIndexFromFile(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return 0;
    }

    bool ok = false;
    const int index = QString::fromUtf8(file.readAll()).trimmed().toInt(&ok);
    if (!ok) {
        return 0;
    }

    return std::clamp(index, 0, 3);
}

static void toggleDashboardTab(QObject *root)
{
    QMetaObject::invokeMethod(
        root,
        "toggleDashboardTab",
        Qt::QueuedConnection,
        Q_ARG(QVariant, tabIndexFromFile(tabCommandPath()))
    );
}

static void onSigUsr1(int)
{
    if (!g_root) return;

    QMetaObject::invokeMethod(
        g_root,
        "toggle",
        Qt::QueuedConnection
    );
}

static void onSigUsr2(int)
{
    if (!g_root) return;

    QMetaObject::invokeMethod(
        g_root,
        []() {
            if (g_root) {
                toggleDashboardTab(g_root);
            }
        },
        Qt::QueuedConnection
    );
}

static void onSigReload(int)
{
    g_reloadRequested.store(true, std::memory_order_relaxed);
}

static QStringList watchedFileVariants(const QString &path)
{
    QStringList paths;
    if (!path.isEmpty()) {
        paths << path;
    }

    QFileInfo info(path);
    const QString canonical = info.canonicalFilePath();
    if (!canonical.isEmpty()) {
        paths << canonical;
    }

    paths.removeDuplicates();
    return paths;
}

static void reloadDashboard(QObject *root, const std::function<void()> &updateInputMask)
{
    QMetaObject::invokeMethod(
        root,
        "reloadTheme",
        Qt::QueuedConnection
    );

    if (updateInputMask) {
        QMetaObject::invokeMethod(
            root,
            [updateInputMask]() { updateInputMask(); },
            Qt::QueuedConnection
        );
    }
}

int main(int argc, char *argv[])
{
    qputenv("QML_XHR_ALLOW_FILE_READ", "1");

    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    SystemInfo sys;
    MediaInfo media;
    AudioSpectrum audioSpectrum;
    AppConfig cfg;
    ConfigFiles configFiles(&engine);
    WeatherConfig weatherConfig;
    const bool initialOpen = initialOpenFromEnvironment();

    engine.rootContext()->setContextProperty("SystemInfo", &sys);
    engine.rootContext()->setContextProperty("MediaInfo", &media);
    engine.rootContext()->setContextProperty("AudioSpectrum", &audioSpectrum);
    engine.rootContext()->setContextProperty("AppConfig", &cfg);
    engine.rootContext()->setContextProperty("ConfigFiles", &configFiles);
    engine.rootContext()->setContextProperty("WeatherConfig", &weatherConfig);
    engine.rootContext()->setContextProperty("InitialTabIndex", initialTabIndexFromEnvironment());
    engine.rootContext()->setContextProperty("InitialOpen", initialOpen);
    engine.loadFromModule("TopDash", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    QObject *root = engine.rootObjects().first();
    g_root = root;
    std::function<void()> updateInputMask;

    if (auto *window = qobject_cast<QWindow *>(root)) {
        if (QScreen *screen = preferredScreen(app, cfg.outputName())) {
            window->setScreen(screen);
            if (auto *layerShellWindow = LayerShellQt::Window::get(window)) {
                layerShellWindow->setScreen(screen);
            }
        }

        updateInputMask = [root, window]() {
            const bool enabled = root->property("inputMaskEnabled").toBool();
            if (!enabled) {
                window->setMask(QRegion());
                return;
            }

            const int windowWidth = window->width();
            const int windowHeight = window->height();
            const int topInset = std::clamp(root->property("inputMaskTop").toInt(), 0, windowHeight);
            const int maskHeight = std::clamp(root->property("inputMaskHeight").toInt(), 0, windowHeight - topInset);

            if (windowWidth <= 0 || maskHeight <= 0) {
                window->setMask(QRegion());
                return;
            }

            window->setMask(QRegion(0, topInset, windowWidth, maskHeight));
        };

        QObject::connect(window, &QWindow::widthChanged, root, updateInputMask);
        QObject::connect(window, &QWindow::heightChanged, root, updateInputMask);
        updateInputMask();
    }

    if (initialOpen) {
        QMetaObject::invokeMethod(root, "openDashboard", Qt::QueuedConnection);
    }

    std::signal(SIGUSR1, onSigUsr1);
    std::signal(SIGUSR2, onSigUsr2);
    std::signal(SIGWINCH, onSigReload);

    QString themePath = QDir::homePath() + "/.config/dashboard/theme.qml";
    QString stylePath = QDir::homePath() + "/.config/dashboard/style.qml";
    QString tasksPath = QDir::homePath() + "/.config/dashboard/tasks.json";
    QString tasksDirPath = QDir::homePath() + "/.config/dashboard";

    QDir().mkpath(tasksDirPath);
    if (!QFileInfo::exists(tasksPath)) {
        QFile tasksFile(tasksPath);
        if (tasksFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            tasksFile.write("[]\n");
            tasksFile.close();
        }
    }

    QStringList watchedPaths = watchedFileVariants(themePath);
    watchedPaths.append(watchedFileVariants(stylePath));
    watchedPaths.removeDuplicates();

    QFileSystemWatcher *watcher = new QFileSystemWatcher(watchedPaths);

    // debounce timer (important for symlink swaps)
    QTimer *reloadTimer = new QTimer;
    reloadTimer->setSingleShot(true);

    QTimer *signalReloadTimer = new QTimer;
    signalReloadTimer->setInterval(50);
    QObject::connect(
        signalReloadTimer,
        &QTimer::timeout,
        [root, updateInputMask]() {
            if (!g_reloadRequested.exchange(false, std::memory_order_relaxed)) {
                return;
            }

            reloadDashboard(root, updateInputMask);
        }
    );
    signalReloadTimer->start();

    QObject::connect(
        watcher,
        &QFileSystemWatcher::fileChanged,
        [watcher, themePath, stylePath, reloadTimer]() {
            QStringList latestPaths = watchedFileVariants(themePath);
            latestPaths.append(watchedFileVariants(stylePath));
            latestPaths.removeDuplicates();

            for (const QString &path : latestPaths) {
                if (!watcher->files().contains(path)) {
                    watcher->addPath(path); // reattach watcher
                }
            }
            reloadTimer->start(80);
        }
    );

    QObject::connect(
        reloadTimer,
        &QTimer::timeout,
        [root, updateInputMask]() {
            reloadDashboard(root, updateInputMask);
        }
    );

    QFileInfo tasksInfo(tasksPath);
    QString watchedTasksPath = tasksInfo.canonicalFilePath();
    if (watchedTasksPath.isEmpty()) {
        watchedTasksPath = tasksPath;
    }

    QFileSystemWatcher *tasksWatcher = new QFileSystemWatcher(
        QStringList{watchedTasksPath, tasksDirPath}
    );

    QTimer *tasksReloadTimer = new QTimer;
    tasksReloadTimer->setSingleShot(true);

    QObject::connect(
        tasksWatcher,
        &QFileSystemWatcher::fileChanged,
        [tasksWatcher, tasksPath, tasksDirPath, tasksReloadTimer]() {
            QFileInfo info(tasksPath);
            QString pathToWatch = info.canonicalFilePath();
            if (pathToWatch.isEmpty()) {
                pathToWatch = tasksPath;
            }

            if (!tasksWatcher->files().contains(pathToWatch)) {
                tasksWatcher->addPath(pathToWatch);
            }
            if (!tasksWatcher->directories().contains(tasksDirPath)) {
                tasksWatcher->addPath(tasksDirPath);
            }

            tasksReloadTimer->start(60);
        }
    );

    QObject::connect(
        tasksWatcher,
        &QFileSystemWatcher::directoryChanged,
        [tasksWatcher, tasksPath, tasksReloadTimer]() {
            QFileInfo info(tasksPath);
            QString pathToWatch = info.canonicalFilePath();
            if (pathToWatch.isEmpty()) {
                pathToWatch = tasksPath;
            }

            if (!tasksWatcher->files().contains(pathToWatch)
                && QFileInfo::exists(tasksPath)) {
                tasksWatcher->addPath(pathToWatch);
            }
            tasksReloadTimer->start(60);
        }
    );

    QObject::connect(
        tasksReloadTimer,
        &QTimer::timeout,
        [root]() {
            QMetaObject::invokeMethod(
                root,
                "reloadTasks",
                Qt::QueuedConnection
            );
        }
    );

    return app.exec();
}
