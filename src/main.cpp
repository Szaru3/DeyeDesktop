#include "viewmodel/AppController.h"

#include <QApplication>
#include <QIcon>
#include <QPalette>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QStyleHints>

namespace {

#if !defined(Q_OS_WIN) && !defined(Q_OS_MACOS)
QPalette buildAdwaitaPalette(bool dark)
{
    QPalette pal;
    if (dark) {
        const QColor window(QStringLiteral("#242424"));
        const QColor base(QStringLiteral("#1E1E1E"));
        const QColor altBase(QStringLiteral("#303030"));
        const QColor button(QStringLiteral("#383838"));
        const QColor text(QStringLiteral("#FFFFFF"));
        const QColor disabledText(QStringLiteral("#808080"));
        const QColor accent(QStringLiteral("#3584E4"));

        pal.setColor(QPalette::Window, window);
        pal.setColor(QPalette::WindowText, text);
        pal.setColor(QPalette::Base, base);
        pal.setColor(QPalette::AlternateBase, altBase);
        pal.setColor(QPalette::ToolTipBase, altBase);
        pal.setColor(QPalette::ToolTipText, text);
        pal.setColor(QPalette::Text, text);
        pal.setColor(QPalette::PlaceholderText, QColor(QStringLiteral("#8C8C8C")));
        pal.setColor(QPalette::Button, button);
        pal.setColor(QPalette::ButtonText, text);
        pal.setColor(QPalette::BrightText, QColor(QStringLiteral("#FF7B63")));
        pal.setColor(QPalette::Highlight, accent);
        pal.setColor(QPalette::HighlightedText, text);
        pal.setColor(QPalette::Link, QColor(QStringLiteral("#78AEED")));
        pal.setColor(QPalette::Mid, QColor(QStringLiteral("#3F3F3F")));
        pal.setColor(QPalette::Dark, QColor(QStringLiteral("#1A1A1A")));
        pal.setColor(QPalette::Light, QColor(QStringLiteral("#454545")));

        pal.setColor(QPalette::Disabled, QPalette::WindowText, disabledText);
        pal.setColor(QPalette::Disabled, QPalette::Text, disabledText);
        pal.setColor(QPalette::Disabled, QPalette::ButtonText, disabledText);
    } else {
        const QColor window(QStringLiteral("#FAFAFA"));
        const QColor base(QStringLiteral("#FFFFFF"));
        const QColor altBase(QStringLiteral("#F2F2F2"));
        const QColor button(QStringLiteral("#EBEBEB"));
        const QColor text(QStringLiteral("#2E3436"));
        const QColor disabledText(QStringLiteral("#9A9996"));
        const QColor accent(QStringLiteral("#3584E4"));

        pal.setColor(QPalette::Window, window);
        pal.setColor(QPalette::WindowText, text);
        pal.setColor(QPalette::Base, base);
        pal.setColor(QPalette::AlternateBase, altBase);
        pal.setColor(QPalette::ToolTipBase, base);
        pal.setColor(QPalette::ToolTipText, text);
        pal.setColor(QPalette::Text, text);
        pal.setColor(QPalette::PlaceholderText, QColor(QStringLiteral("#77767B")));
        pal.setColor(QPalette::Button, button);
        pal.setColor(QPalette::ButtonText, text);
        pal.setColor(QPalette::BrightText, QColor(QStringLiteral("#C01C28")));
        pal.setColor(QPalette::Highlight, accent);
        pal.setColor(QPalette::HighlightedText, QColor(QStringLiteral("#FFFFFF")));
        pal.setColor(QPalette::Link, accent);

        pal.setColor(QPalette::Disabled, QPalette::WindowText, disabledText);
        pal.setColor(QPalette::Disabled, QPalette::Text, disabledText);
        pal.setColor(QPalette::Disabled, QPalette::ButtonText, disabledText);
    }
    return pal;
}
#endif

} // namespace

int main(int argc, char *argv[])
{
    // QApplication enables native QStyle integration (required by KDE's org.kde.desktop style)
    QApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("DeyeDesktop"));
    app.setApplicationName(QStringLiteral("DeyeDesktop"));
    app.setApplicationVersion(QStringLiteral("0.1.0"));
    app.setDesktopFileName(QStringLiteral("deye-desktop"));
    app.setWindowIcon(QIcon(QStringLiteral(":/qt/qml/DeyeDesktop/assets/icon.png")));

    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
#if defined(Q_OS_WIN)
        QQuickStyle::setStyle(QStringLiteral("FluentWinUI3"));
#elif defined(Q_OS_MACOS)
        QQuickStyle::setStyle(QStringLiteral("macOS"));
#else
        const bool isKde = qEnvironmentVariable("XDG_CURRENT_DESKTOP")
                               .contains(QStringLiteral("KDE"), Qt::CaseInsensitive);
        if (isKde) {
            QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
        } else {
            // On GNOME and other non-KDE Linux desktops, use Fusion with an Adwaita palette
            // synced to the XDG Desktop Portal dark/light color scheme.
            QApplication::setStyle(QStringLiteral("Fusion"));
            QQuickStyle::setStyle(QStringLiteral("Fusion"));

            auto applyPortalPalette = []() {
                const auto scheme = QGuiApplication::styleHints()->colorScheme();
                const bool useDark = (scheme == Qt::ColorScheme::Dark);
                QApplication::setPalette(buildAdwaitaPalette(useDark));
            };
            applyPortalPalette();
            QObject::connect(QGuiApplication::styleHints(),
                             &QStyleHints::colorSchemeChanged,
                             &app,
                             [applyPortalPalette](Qt::ColorScheme) { applyPortalPalette(); });
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
