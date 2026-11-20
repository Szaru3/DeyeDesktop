#include "viewmodel/AppController.h"

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

int main(int argc, char *argv[])
{
    // QApplication enables native QStyle integration (required by KDE's org.kde.desktop style)
    QApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("DeyeDesktop"));
    app.setApplicationName(QStringLiteral("DeyeDesktop"));
    app.setApplicationVersion(QStringLiteral("0.1.0"));

    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
#if defined(Q_OS_WIN)
        QQuickStyle::setStyle(QStringLiteral("FluentWinUI3"));
#else
        if (qEnvironmentVariable("XDG_CURRENT_DESKTOP").contains(QStringLiteral("KDE"), Qt::CaseInsensitive)) {
            QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
        }
#endif
        QQuickStyle::setFallbackStyle(QStringLiteral("Fusion"));
    }

    deye::AppController controller;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("appController"), &controller);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule(QStringLiteral("DeyeDesktop"), QStringLiteral("Main"));

    return app.exec();
}
