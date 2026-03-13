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
#include <csignal>
#include <QQmlContext>
#include <LayerShellQt/window.h>
#include "systeminfo.h"
#include "appconfig.h"

static QObject *g_root = nullptr;

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

static void onSigUsr1(int)
{
    if (!g_root) return;

    QMetaObject::invokeMethod(
        g_root,
        "toggle",
        Qt::QueuedConnection
    );
}

int main(int argc, char *argv[])
{
    qputenv("QML_XHR_ALLOW_FILE_READ", "1");

    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    SystemInfo sys;
    AppConfig cfg;

    engine.rootContext()->setContextProperty("SystemInfo", &sys);
    engine.rootContext()->setContextProperty("AppConfig", &cfg);
    engine.loadFromModule("TopDash", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    QObject *root = engine.rootObjects().first();
    g_root = root;

    if (auto *window = qobject_cast<QWindow *>(root)) {
        if (QScreen *screen = preferredScreen(app, cfg.outputName())) {
            window->setScreen(screen);
            if (auto *layerShellWindow = LayerShellQt::Window::get(window)) {
                layerShellWindow->setScreen(screen);
            }
        }
    }

    std::signal(SIGUSR1, onSigUsr1);

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

    auto canonicalOrOriginal = [](const QString &path) {
        QFileInfo info(path);
        QString real = info.canonicalFilePath();
        return real.isEmpty() ? path : real;
    };

    QStringList watchedPaths{
        canonicalOrOriginal(themePath),
        canonicalOrOriginal(stylePath)
    };
    watchedPaths.removeDuplicates();

    QFileSystemWatcher *watcher = new QFileSystemWatcher(watchedPaths);

    // debounce timer (important for symlink swaps)
    QTimer *reloadTimer = new QTimer;
    reloadTimer->setSingleShot(true);

    QObject::connect(
        watcher,
        &QFileSystemWatcher::fileChanged,
        [watcher, themePath, stylePath, reloadTimer, canonicalOrOriginal]() {
            QStringList latestPaths{
                canonicalOrOriginal(themePath),
                canonicalOrOriginal(stylePath)
            };
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
        [root]() {
            QMetaObject::invokeMethod(
                root,
                "reloadTheme",
                Qt::QueuedConnection
            );
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
