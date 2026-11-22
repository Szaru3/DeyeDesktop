#include "viewmodel/AppController.h"

#include <QApplication>
#include <QIcon>
#include <QPalette>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QStyleHints>

#include <functional>
#include <memory>
#include <optional>

#if !defined(Q_OS_WIN) && !defined(Q_OS_MACOS) && defined(DEYE_HAS_DBUS)
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusVariant>
#endif

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

#if defined(DEYE_HAS_DBUS)
std::optional<quint32> unwrapPortalUint(QVariant value)
{
    while (value.metaType() == QMetaType::fromType<QDBusVariant>()) {
        value = value.value<QDBusVariant>().variant();
    }
    bool ok = false;
    const quint32 result = value.toUInt(&ok);
    return ok ? std::optional<quint32>(result) : std::nullopt;
}

std::optional<bool> queryPortalDarkMode()
{
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) {
        return std::nullopt;
    }

    auto callMethod = [&](const QString &method) -> std::optional<quint32> {
        QDBusMessage msg = QDBusMessage::createMethodCall(
            QStringLiteral("org.freedesktop.portal.Desktop"),
            QStringLiteral("/org/freedesktop/portal/desktop"),
            QStringLiteral("org.freedesktop.portal.Settings"),
            method);
        msg << QStringLiteral("org.freedesktop.appearance")
            << QStringLiteral("color-scheme");
        const QDBusMessage reply = bus.call(msg, QDBus::Block, 500);
        if (reply.type() != QDBusMessage::ReplyMessage || reply.arguments().isEmpty()) {
            return std::nullopt;
        }
        return unwrapPortalUint(reply.arguments().constFirst());
    };

    // Portal Settings v2 uses ReadOne; fall back to v1 Read for older portals.
    std::optional<quint32> scheme = callMethod(QStringLiteral("ReadOne"));
    if (!scheme.has_value()) {
        scheme = callMethod(QStringLiteral("Read"));
    }
    if (!scheme.has_value()) {
        return std::nullopt;
    }

    // Freedesktop spec: 0 = no preference, 1 = prefer dark, 2 = prefer light.
    if (*scheme == 1U) {
        return true;
    }
    if (*scheme == 2U) {
        return false;
    }
    return std::nullopt;
}
#endif

bool detectInitialDarkMode()
{
#if defined(DEYE_HAS_DBUS)
    if (const std::optional<bool> portalDark = queryPortalDarkMode(); portalDark.has_value()) {
        return *portalDark;
    }
#endif
    const Qt::ColorScheme scheme = QGuiApplication::styleHints()->colorScheme();
    if (scheme == Qt::ColorScheme::Dark) {
        return true;
    }
    if (scheme == Qt::ColorScheme::Light) {
        return false;
    }
    return qEnvironmentVariable("GTK_THEME").contains(QStringLiteral("dark"), Qt::CaseInsensitive);
}
#endif

} // namespace

#if !defined(Q_OS_WIN) && !defined(Q_OS_MACOS) && defined(DEYE_HAS_DBUS)
class PortalThemeWatcher : public QObject {
    Q_OBJECT

public:
    explicit PortalThemeWatcher(std::function<void(std::optional<bool>)> callback,
                                QObject *parent = nullptr)
        : QObject(parent)
        , m_callback(std::move(callback))
    {
        QDBusConnection::sessionBus().connect(
            QStringLiteral("org.freedesktop.portal.Desktop"),
            QStringLiteral("/org/freedesktop/portal/desktop"),
            QStringLiteral("org.freedesktop.portal.Settings"),
            QStringLiteral("SettingChanged"),
            this,
            SLOT(onSettingChanged(QString,QString,QDBusVariant)));
    }

private slots:
    void onSettingChanged(const QString &ns, const QString &key, const QDBusVariant &value)
    {
        if (ns != QStringLiteral("org.freedesktop.appearance")
            || key != QStringLiteral("color-scheme")) {
            return;
        }
        const std::optional<quint32> scheme = unwrapPortalUint(value.variant());
        if (!scheme.has_value()) {
            return;
        }
        if (*scheme == 1U) {
            m_callback(true);
        } else if (*scheme == 2U) {
            m_callback(false);
        } else {
            m_callback(std::nullopt);
        }
    }

private:
    std::function<void(std::optional<bool>)> m_callback;
};
#endif

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

            auto lastAppliedDark = std::make_shared<std::optional<bool>>();
            auto applyAdwaitaPalette = [lastAppliedDark](bool useDark) {
                if (lastAppliedDark->has_value() && **lastAppliedDark == useDark) {
                    return;
                }
                *lastAppliedDark = useDark;
                QApplication::setPalette(buildAdwaitaPalette(useDark));
            };

            applyAdwaitaPalette(detectInitialDarkMode());

            QObject::connect(QGuiApplication::styleHints(),
                             &QStyleHints::colorSchemeChanged,
                             &app,
                             [applyAdwaitaPalette](Qt::ColorScheme scheme) {
                                 if (scheme == Qt::ColorScheme::Dark) {
                                     applyAdwaitaPalette(true);
                                 } else if (scheme == Qt::ColorScheme::Light) {
                                     applyAdwaitaPalette(false);
                                 }
                             });
#if defined(DEYE_HAS_DBUS)
            new PortalThemeWatcher(
                [applyAdwaitaPalette](std::optional<bool> portalDark) {
                    if (portalDark.has_value()) {
                        applyAdwaitaPalette(*portalDark);
                    } else {
                        const auto scheme = QGuiApplication::styleHints()->colorScheme();
                        applyAdwaitaPalette(scheme == Qt::ColorScheme::Dark);
                    }
                },
                &app);
#endif
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

#if !defined(Q_OS_WIN) && !defined(Q_OS_MACOS) && defined(DEYE_HAS_DBUS)
#include "main.moc"
#endif
