#include "viewmodel/AppController.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("DeyeDesktop"));
    app.setApplicationName(QStringLiteral("DeyeDesktop"));
    app.setApplicationVersion(QStringLiteral("0.1.0"));

    // Use Basic style so custom Theme tokens render identically on Linux and Windows
    QQuickStyle::setStyle(QStringLiteral("Basic"));

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
