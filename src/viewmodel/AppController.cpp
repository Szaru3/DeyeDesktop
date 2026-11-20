#include "AppController.h"

#include <QApplication>
#include <QDateTime>
#include <QVariantMap>
#include <cmath>
#include <numbers>

#if defined(DEYE_HAS_DBUS)
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#else
#include <QIcon>
#include <QPainter>
#include <QPixmap>
#include <QSystemTrayIcon>
#endif

namespace deye {

AppController::AppController(QObject *parent)
    : QObject(parent)
    , m_inverterSettings(&m_apiClient, this)
    , m_regions(defaultRegions())
{
    for (const DeyeRegion &region : m_regions) {
        m_regionNames.push_back(region.name);
    }

    m_saved = m_settingsStore.load();
    m_language = m_saved.language;
    m_deviceModel.setCustomNames(m_settingsStore.loadCustomDeviceNames());
    m_autoRefreshEnabled = true;
    m_refreshIntervalSec = 120;

    m_refreshTimer.setInterval(m_refreshIntervalSec * 1000);
    connect(&m_refreshTimer, &QTimer::timeout, this, &AppController::refreshDashboard);

    connect(&m_apiClient, &DeyeApiClient::authenticated, this, &AppController::onAuthenticated);
    connect(&m_apiClient, &DeyeApiClient::stationsFetched, this, &AppController::onStationsFetched);
    connect(&m_apiClient, &DeyeApiClient::stationLatestFetched, this, &AppController::onStationLatestFetched);
    connect(&m_apiClient, &DeyeApiClient::stationDevicesFetched, this, &AppController::onStationDevicesFetched);
    connect(&m_apiClient, &DeyeApiClient::stationAlertsFetched, this, &AppController::onStationAlertsFetched);
    connect(&m_apiClient, &DeyeApiClient::stationPowerProfileFetched, this, &AppController::onStationPowerProfileFetched);
    connect(&m_apiClient, &DeyeApiClient::stationEnergyHistoryFetched, this, &AppController::onStationEnergyHistoryFetched);
    connect(&m_apiClient, &DeyeApiClient::requestFailed, this, &AppController::onRequestFailed);
}

void AppController::setBusy(bool busy)
{
    if (m_busy == busy) {
        return;
    }
    m_busy = busy;
    emit busyChanged();
}

void AppController::setErrorMessage(const QString &msg)
{
    if (m_errorMessage == msg) {
        return;
    }
    m_errorMessage = msg;
    emit errorMessageChanged();
}

void AppController::clearError()
{
    setErrorMessage({});
}

void AppController::setLanguage(const QString &lang)
{
    const QString normalized = (lang.trimmed().toLower() == QStringLiteral("pl"))
        ? QStringLiteral("pl")
        : QStringLiteral("en");
    if (m_language == normalized) {
        return;
    }
    m_language = normalized;
    m_settingsStore.saveLanguage(m_language);
    emit languageChanged();
}

void AppController::setAutoRefreshEnabled(bool enabled)
{
    if (m_autoRefreshEnabled == enabled) {
        return;
    }
    m_autoRefreshEnabled = enabled;
    m_settingsStore.saveRefreshSettings(m_autoRefreshEnabled, m_refreshIntervalSec);
    updateTimerState();
    emit refreshSettingsChanged();
}

void AppController::updateTimerState()
{
    if (m_loggedIn && m_autoRefreshEnabled && m_selectedStationId != 0) {
        m_refreshTimer.setInterval(m_refreshIntervalSec * 1000);
        if (!m_refreshTimer.isActive()) {
            m_refreshTimer.start();
        }
    } else {
        m_refreshTimer.stop();
    }
}

void AppController::login(int regionIndex,
                          const QString &customBaseUrl,
                          const QString &appId,
                          const QString &appSecret,
                          int loginMethod,
                          const QString &email,
                          const QString &countryCode,
                          const QString &mobile,
                          const QString &username,
                          const QString &companyId,
                          const QString &password,
                          bool rememberMe)
{
    clearError();

    QString resolvedUrl;
    if (regionIndex >= 0 && regionIndex < m_regions.size() && !m_regions.at(regionIndex).baseUrl.isEmpty()) {
        resolvedUrl = m_regions.at(regionIndex).baseUrl;
    } else {
        resolvedUrl = customBaseUrl.trimmed();
    }

    DeyeCredentials creds;
    creds.baseUrl = resolvedUrl;
    creds.appId = appId.trimmed();
    creds.appSecret = appSecret.trimmed();
    creds.loginMethod = static_cast<LoginMethod>(std::clamp(loginMethod, 0, 2));
    creds.email = email.trimmed();
    creds.countryCode = countryCode.trimmed();
    creds.mobile = mobile.trimmed();
    creds.username = username.trimmed();
    creds.companyId = companyId.trimmed();
    creds.password = password;

    const QString validationError = creds.validate();
    if (!validationError.isEmpty()) {
        setErrorMessage(validationError);
        return;
    }

    m_saved.regionIndex = regionIndex;
    m_saved.customBaseUrl = customBaseUrl.trimmed();
    m_saved.appId = creds.appId;
    m_saved.appSecret = creds.appSecret;
    m_saved.loginMethod = loginMethod;
    m_saved.email = creds.email;
    m_saved.countryCode = creds.countryCode;
    m_saved.mobile = creds.mobile;
    m_saved.username = creds.username;
    m_saved.companyId = creds.companyId;
    m_saved.password = creds.password;
    m_saved.rememberMe = rememberMe;
    m_settingsStore.saveLoginSettings(m_saved);

    m_demoMode = false;
    setBusy(true);
    m_apiClient.authenticate(creds);
}

void AppController::loginDemo()
{
    clearError();
    m_demoMode = true;
    m_loggedIn = true;
    m_demoTick = 0;
    emit sessionChanged();

    QVector<StationInfo> demoStations;

    StationInfo home;
    home.id = 100001;
    home.name = QStringLiteral("Home Hybrid 10kW (Demo)");
    home.locationAddress = QStringLiteral("Warsaw, PL");
    home.installedCapacityKw = 10.4;
    home.connectionStatus = QStringLiteral("NORMAL");
    home.generationPowerW = 5420.0;
    home.batterySoc = 78.0;
    demoStations.push_back(home);

    StationInfo cabin;
    cabin.id = 100002;
    cabin.name = QStringLiteral("Weekend Cabin 6kW (Demo)");
    cabin.locationAddress = QStringLiteral("Krakow, PL");
    cabin.installedCapacityKw = 6.0;
    cabin.connectionStatus = QStringLiteral("NORMAL");
    cabin.generationPowerW = 1150.0;
    cabin.batterySoc = 42.0;
    demoStations.push_back(cabin);

    m_stationModel.setStations(demoStations);
    selectStationByIndex(0);
    updateTimerState();
}

void AppController::logout()
{
    m_refreshTimer.stop();
    m_apiClient.clearSession();
    m_stationModel.clear();
    m_deviceModel.clear();
    m_alertModel.clear();
    m_notifiedAlertIds.clear();
    m_powerProfilePoints.clear();
    m_energyHistoryItems.clear();
    emit devicesChanged();
    emit alertsChanged();
    emit powerProfileChanged();
    emit energyHistoryChanged();

    m_loggedIn = false;
    m_demoMode = false;
    m_selectedStationIndex = -1;
    m_selectedStationId = 0;
    m_selectedStationName.clear();
    m_selectedStationLocation.clear();
    m_installedCapacityKw = 0.0;
    m_connectionStatus = QStringLiteral("UNKNOWN");
    m_latest = StationLatestData{};
    m_lastUpdateText = QStringLiteral("—");
    setBusy(false);
    clearError();

    emit selectedStationChanged();
    emit telemetryChanged();
    emit sessionChanged();
}

void AppController::selectStationByIndex(int index)
{
    const StationInfo *st = m_stationModel.stationAt(index);
    if (!st) {
        return;
    }

    m_selectedStationIndex = index;
    m_selectedStationId = st->id;
    m_selectedStationName = st->name;
    m_selectedStationLocation = st->locationAddress;
    m_installedCapacityKw = st->installedCapacityKw;
    m_connectionStatus = st->connectionStatus;

    if (!m_demoMode) {
        m_settingsStore.saveLastStationId(m_selectedStationId);
    }

    emit selectedStationChanged();
    refreshDashboard();
    updateTimerState();
}

void AppController::openInverterSettings(const QString &deviceSn, const QString &deviceName)
{
    m_inverterSettings.openForDevice(deviceSn, deviceName, m_demoMode);
}

void AppController::renameDevice(const QString &deviceSn, const QString &newName)
{
    m_settingsStore.saveCustomDeviceName(deviceSn, newName);
    m_deviceModel.setCustomNameForDevice(deviceSn, newName);
}

QString AppController::energyHistoryPeriodText() const
{
    if (m_energyHistoryMode == 0) {
        return m_energyHistoryDate.toString(QStringLiteral("yyyy/MM"));
    }
    if (m_energyHistoryMode == 1) {
        return m_energyHistoryDate.toString(QStringLiteral("yyyy"));
    }
    return QStringLiteral("All Years");
}

void AppController::shiftPowerProfileDate(int deltaDays)
{
    const QDate next = m_powerProfileDate.addDays(deltaDays);
    if (next > QDate::currentDate()) {
        return;
    }
    m_powerProfileDate = next;
    emit powerProfileChanged();
    fetchPowerProfile();
}

void AppController::setEnergyHistoryMode(int mode)
{
    const int clamped = std::clamp(mode, 0, 2);
    if (m_energyHistoryMode == clamped) {
        return;
    }
    m_energyHistoryMode = clamped;
    emit energyHistoryChanged();
    fetchEnergyHistory();
}

void AppController::shiftEnergyHistoryPeriod(int delta)
{
    if (m_energyHistoryMode == 0) {
        const QDate next = m_energyHistoryDate.addMonths(delta);
        if (next.year() > QDate::currentDate().year()
            || (next.year() == QDate::currentDate().year() && next.month() > QDate::currentDate().month())) {
            return;
        }
        m_energyHistoryDate = next;
    } else if (m_energyHistoryMode == 1) {
        const QDate next = m_energyHistoryDate.addYears(delta);
        if (next.year() > QDate::currentDate().year()) {
            return;
        }
        m_energyHistoryDate = next;
    } else {
        return;
    }
    emit energyHistoryChanged();
    fetchEnergyHistory();
}

void AppController::fetchPowerProfile()
{
    if (!m_loggedIn || m_selectedStationId == 0) {
        return;
    }
    if (m_demoMode) {
        applyDemoPowerProfile(m_selectedStationId);
        return;
    }
    m_apiClient.fetchStationPowerProfile(m_selectedStationId, m_powerProfileDate.toString(QStringLiteral("yyyy-MM-dd")));
}

void AppController::fetchEnergyHistory()
{
    if (!m_loggedIn || m_selectedStationId == 0) {
        return;
    }
    if (m_demoMode) {
        applyDemoEnergyHistory(m_selectedStationId);
        return;
    }

    int granularity = 2;
    QString startYmd;
    QString endYmd;
    if (m_energyHistoryMode == 0) {
        granularity = 2; // Daily bars in selected month
        const QDate first(m_energyHistoryDate.year(), m_energyHistoryDate.month(), 1);
        const QDate last(m_energyHistoryDate.year(), m_energyHistoryDate.month(), first.daysInMonth());
        startYmd = first.toString(QStringLiteral("yyyy-MM-dd"));
        endYmd = last.toString(QStringLiteral("yyyy-MM-dd"));
    } else if (m_energyHistoryMode == 1) {
        granularity = 3; // Monthly bars in selected year
        startYmd = QStringLiteral("%1-01").arg(m_energyHistoryDate.year());
        endYmd = QStringLiteral("%1-12").arg(m_energyHistoryDate.year());
    } else {
        granularity = 4; // Yearly totals
        startYmd = QString::number(QDate::currentDate().year() - 5);
        endYmd = QString::number(QDate::currentDate().year());
    }
    m_apiClient.fetchStationEnergyHistory(m_selectedStationId, startYmd, endYmd, granularity);
}

void AppController::refreshStations()
{
    if (!m_loggedIn) {
        return;
    }
    if (m_demoMode) {
        refreshDashboard();
        return;
    }
    clearError();
    setBusy(true);
    m_apiClient.fetchStations();
}

void AppController::refreshDashboard()
{
    if (!m_loggedIn || m_selectedStationId == 0) {
        return;
    }
    if (m_demoMode) {
        applyDemoTelemetry(m_selectedStationId);
        applyDemoDevices(m_selectedStationId);
        applyDemoAlerts(m_selectedStationId);
        applyDemoPowerProfile(m_selectedStationId);
        applyDemoEnergyHistory(m_selectedStationId);
        return;
    }
    setBusy(true);
    m_apiClient.fetchStationLatest(m_selectedStationId);
    m_apiClient.fetchStationDevices(m_selectedStationId);

    const qint64 nowSec = QDateTime::currentSecsSinceEpoch();
    m_apiClient.fetchStationAlerts(m_selectedStationId, nowSec - 7LL * 86400LL, nowSec);
    fetchPowerProfile();
    fetchEnergyHistory();
}

QString AppController::formatPower(double watts) const
{
    const double absW = std::abs(watts);
    if (absW >= 1000.0) {
        return QStringLiteral("%1 kW").arg(absW / 1000.0, 0, 'f', 2);
    }
    return QStringLiteral("%1 W").arg(std::round(absW), 0, 'f', 0);
}

void AppController::applyDemoTelemetry(qint64 stationId)
{
    ++m_demoTick;
    const double wave = std::sin(static_cast<double>(m_demoTick) * 0.7);

    StationLatestData d;
    d.success = true;
    d.hasBatterySoc = true;
    d.lastUpdateTime = QDateTime::currentSecsSinceEpoch();

    if (stationId == 100001) {
        d.generationPowerW = 5400.0 + wave * 350.0;
        d.consumptionPowerW = 1850.0 + wave * 120.0;
        d.batteryPowerW = 2400.0 + wave * 150.0; // Charging
        d.gridPowerW = -(d.generationPowerW - d.consumptionPowerW - d.batteryPowerW); // Exporting
        d.batterySoc = std::clamp(78.0 + m_demoTick * 0.5, 0.0, 100.0);
    } else {
        d.generationPowerW = 1100.0 + wave * 150.0;
        d.consumptionPowerW = 2450.0 - wave * 100.0;
        d.batteryPowerW = -950.0; // Discharging
        d.gridPowerW = d.consumptionPowerW - d.generationPowerW + d.batteryPowerW; // Importing
        d.batterySoc = std::clamp(42.0 - m_demoTick * 0.3, 5.0, 100.0);
    }

    applyTelemetry(d);
}

void AppController::applyDemoDevices(qint64 stationId)
{
    const qint64 now = QDateTime::currentSecsSinceEpoch();
    QVector<DeviceInfo> list;

    if (stationId == 100001) {
        list.push_back({900101, QStringLiteral("2309184421"), QStringLiteral("Main Hybrid Inverter"), QStringLiteral("Inverter"), QStringLiteral("SUN-10K-SG04LP3-EU"), QStringLiteral("NORMAL"), now});
        list.push_back({900104, QStringLiteral("2309184422"), QStringLiteral("Secondary Hybrid Inverter"), QStringLiteral("Inverter"), QStringLiteral("SUN-10K-SG04LP3-EU"), QStringLiteral("NORMAL"), now});
        list.push_back({900102, QStringLiteral("4102883910"), QStringLiteral("Wi-Fi Solarman Logger"), QStringLiteral("Data Logger"), QStringLiteral("LSW-3"), QStringLiteral("NORMAL"), now});
        list.push_back({900103, QStringLiteral("B240119008"), QStringLiteral("LiFePO4 Battery Stack 15kWh"), QStringLiteral("Battery"), QStringLiteral("SE-G5.1 Pro-B"), QStringLiteral("NORMAL"), now});
    } else {
        list.push_back({900201, QStringLiteral("2207119034"), QStringLiteral("Cabin Inverter"), QStringLiteral("Inverter"), QStringLiteral("SUN-6K-SG04LP3-EU"), QStringLiteral("NORMAL"), now});
        list.push_back({900202, QStringLiteral("4091726355"), QStringLiteral("Wi-Fi Logger"), QStringLiteral("Data Logger"), QStringLiteral("LSW-3"), QStringLiteral("NORMAL"), now});
    }

    m_deviceModel.setDevices(list);
    emit devicesChanged();
}

void AppController::onStationDevicesFetched(qint64 stationId, const QVector<DeviceInfo> &devices)
{
    if (stationId != m_selectedStationId) {
        return;
    }
    m_deviceModel.setDevices(devices);
    emit devicesChanged();
}

void AppController::sendDesktopNotification(const QString &title, const QString &body, bool isCritical)
{
    if (!qobject_cast<QApplication *>(QCoreApplication::instance())) {
        return;
    }

#if defined(DEYE_HAS_DBUS)
    QDBusMessage msg = QDBusMessage::createMethodCall(
        QStringLiteral("org.freedesktop.Notifications"),
        QStringLiteral("/org/freedesktop/Notifications"),
        QStringLiteral("org.freedesktop.Notifications"),
        QStringLiteral("Notify"));

    QVariantMap hints;
    // FreeDesktop urgency: 0=Low, 1=Normal, 2=Critical
    hints.insert(QStringLiteral("urgency"), QVariant::fromValue(static_cast<uchar>(isCritical ? 2 : 1)));

    msg << QStringLiteral("DeyeDesktop")                                        // app_name
        << static_cast<quint32>(0)                                              // replaces_id
        << (isCritical ? QStringLiteral("dialog-error") : QStringLiteral("dialog-warning")) // app_icon
        << title                                                                // summary
        << body                                                                 // body
        << QStringList{}                                                        // actions
        << hints                                                                // hints
        << static_cast<qint32>(8000);                                           // expire_timeout (ms)

    QDBusConnection::sessionBus().asyncCall(msg);
#else
    if (!QSystemTrayIcon::isSystemTrayAvailable()) {
        return;
    }
    QPixmap pm(32, 32);
    pm.fill(Qt::transparent);
    QPainter p(&pm);
    p.setRenderHint(QPainter::Antialiasing);
    p.setBrush(QColor(QStringLiteral("#F5C211")));
    p.setPen(Qt::NoPen);
    p.drawEllipse(6, 6, 20, 20);
    p.end();

    auto *tray = new QSystemTrayIcon(QIcon(pm), this);
    tray->show();
    tray->showMessage(title, body, isCritical ? QSystemTrayIcon::Critical : QSystemTrayIcon::Warning, 8000);
    QTimer::singleShot(1500, tray, [tray]() {
        tray->hide();
        tray->deleteLater();
    });
#endif
}

void AppController::notifyNewFaults(const QVector<AlertInfo> &alerts)
{
    for (const AlertInfo &a : alerts) {
        if (!a.isActive) continue;
        if (m_notifiedAlertIds.contains(a.alertId)) continue;
        m_notifiedAlertIds.insert(a.alertId);

        const QString title = QStringLiteral("DeyeDesktop — %1 (%2)").arg(a.level, a.alertCode.isEmpty() ? QStringLiteral("Alert") : a.alertCode);
        const QString body = a.deviceSn.isEmpty()
            ? a.alertMessage
            : QStringLiteral("%1 (SN: %2)").arg(a.alertMessage, a.deviceSn);
        const bool isCritical = (a.level.compare(QStringLiteral("Fault"), Qt::CaseInsensitive) == 0);
        sendDesktopNotification(title, body, isCritical);
    }
}

void AppController::applyDemoAlerts(qint64 stationId)
{
    const qint64 now = QDateTime::currentSecsSinceEpoch();
    QVector<AlertInfo> list;
    if (stationId == 100001) {
        list.push_back({
            QStringLiteral("demo_fault_100001"),
            QStringLiteral("2309184421"),
            QStringLiteral("Inverter"),
            QStringLiteral("F56"),
            QStringLiteral("DC Busbar Voltage Low (Demo Fault)"),
            QStringLiteral("Fault"),
            true,
            now - 420,
            0
        });
        list.push_back({
            QStringLiteral("demo_warn_100001"),
            QStringLiteral("2309184422"),
            QStringLiteral("Inverter"),
            QStringLiteral("W01"),
            QStringLiteral("Grid Voltage High"),
            QStringLiteral("Warning"),
            false,
            now - 18000,
            now - 14400
        });
    } else {
        list.push_back({
            QStringLiteral("demo_fault_100002"),
            QStringLiteral("2207119034"),
            QStringLiteral("Inverter"),
            QStringLiteral("F30"),
            QStringLiteral("Grid Voltage Out of Range (Demo Fault)"),
            QStringLiteral("Fault"),
            true,
            now - 900,
            0
        });
    }

    m_alertModel.setAlerts(list);
    emit alertsChanged();
    notifyNewFaults(list);
}

void AppController::onStationAlertsFetched(qint64 stationId, const QVector<AlertInfo> &alerts)
{
    if (stationId != m_selectedStationId) {
        return;
    }
    m_alertModel.setAlerts(alerts);
    emit alertsChanged();
    notifyNewFaults(alerts);
}

void AppController::applyDemoPowerProfile(qint64 stationId)
{
    QVariantList pts;
    const double scale = (stationId == 100001) ? 1.0 : 0.6;
    const int seed = m_powerProfileDate.day();
    double soc = 45.0;

    for (int m = 0; m < 24 * 60; m += 15) {
        const double h = m / 60.0;
        double pv = 0.0;
        if (h >= 6.5 && h <= 17.5) {
            const double sun = std::sin((h - 6.5) / 11.0 * std::numbers::pi);
            const double cloud = 0.72 + 0.28 * std::sin(h * 2.7 + seed);
            pv = std::max(0.0, 5.2 * scale * sun * cloud);
        }

        double cons = (0.55 + 0.35 * std::sin(h * 0.6) + (h >= 6.5 && h <= 9.0 ? 1.4 : 0.0) + (h >= 17.5 && h <= 21.5 ? 1.8 : 0.0)) * scale;
        double batt = 0.0;
        double grid = 0.0;

        if (h >= 2.0 && h <= 4.5 && soc < 72.0) {
            // Night TOU grid charge spike
            batt = -2.8 * scale;
            grid = cons + 2.8 * scale;
            soc = std::min(100.0, soc + 1.9);
        } else if (pv > cons) {
            const double surplus = pv - cons;
            if (soc < 98.0) {
                batt = -std::min(surplus, 3.8 * scale);
                soc = std::min(100.0, soc + (-batt) * 0.45);
                grid = -(surplus + batt);
            } else {
                grid = -surplus;
            }
        } else {
            const double deficit = cons - pv;
            if (soc > 18.0) {
                batt = std::min(deficit, 3.2 * scale);
                soc = std::max(15.0, soc - batt * 0.45);
                grid = deficit - batt;
            } else {
                grid = deficit;
            }
        }

        QVariantMap map;
        map.insert(QStringLiteral("timeLabel"), QStringLiteral("%1:%2").arg(m / 60, 2, 10, QLatin1Char('0')).arg(m % 60, 2, 10, QLatin1Char('0')));
        map.insert(QStringLiteral("hourOfDay"), h);
        map.insert(QStringLiteral("pvKw"), pv);
        map.insert(QStringLiteral("gridKw"), grid);
        map.insert(QStringLiteral("batteryKw"), batt);
        map.insert(QStringLiteral("consumptionKw"), cons);
        map.insert(QStringLiteral("soc"), soc);
        map.insert(QStringLiteral("hasSoc"), true);
        pts.push_back(map);
    }

    m_powerProfilePoints = pts;
    emit powerProfileChanged();
}

void AppController::onStationPowerProfileFetched(qint64 stationId, const QString &dateYmd, const QVector<PowerProfilePoint> &points)
{
    if (stationId != m_selectedStationId || dateYmd != m_powerProfileDate.toString(QStringLiteral("yyyy-MM-dd"))) {
        return;
    }
    QVariantList list;
    list.reserve(points.size());
    for (const PowerProfilePoint &pt : points) {
        QVariantMap m;
        m.insert(QStringLiteral("timeLabel"), pt.timeLabel);
        m.insert(QStringLiteral("hourOfDay"), pt.hourOfDay);
        m.insert(QStringLiteral("pvKw"), pt.pvKw);
        m.insert(QStringLiteral("gridKw"), pt.gridKw);
        m.insert(QStringLiteral("batteryKw"), pt.batteryKw);
        m.insert(QStringLiteral("consumptionKw"), pt.consumptionKw);
        m.insert(QStringLiteral("soc"), pt.soc);
        m.insert(QStringLiteral("hasSoc"), pt.hasSoc);
        list.push_back(m);
    }
    m_powerProfilePoints = list;
    emit powerProfileChanged();
}

void AppController::applyDemoEnergyHistory(qint64 stationId)
{
    QVariantList items;
    const double scale = (stationId == 100001) ? 1.0 : 0.6;

    if (m_energyHistoryMode == 0) {
        const int days = m_energyHistoryDate.daysInMonth();
        const int maxDay = (m_energyHistoryDate.year() == QDate::currentDate().year()
                            && m_energyHistoryDate.month() == QDate::currentDate().month())
            ? QDate::currentDate().day()
            : days;
        for (int d = 1; d <= days; ++d) {
            QVariantMap m;
            m.insert(QStringLiteral("label"), QString::number(d));
            m.insert(QStringLiteral("fullDate"), QStringLiteral("%1-%2-%3")
                     .arg(m_energyHistoryDate.year())
                     .arg(m_energyHistoryDate.month(), 2, 10, QLatin1Char('0'))
                     .arg(d, 2, 10, QLatin1Char('0')));
            if (d <= maxDay) {
                const double w = 0.5 + 0.5 * std::sin(d * 0.85);
                m.insert(QStringLiteral("productionKwh"), (12.0 + 26.0 * w) * scale);
                m.insert(QStringLiteral("dischargeKwh"), (6.0 + 10.0 * (1.0 - w * 0.4)) * scale);
                m.insert(QStringLiteral("purchasedKwh"), (8.0 + 18.0 * (1.0 - w)) * scale);
                m.insert(QStringLiteral("consumptionKwh"), (22.0 + 18.0 * w) * scale);
                m.insert(QStringLiteral("chargeKwh"), (7.0 + 11.0 * w) * scale);
                m.insert(QStringLiteral("gridFeedInKwh"), (2.0 + 9.0 * w) * scale);
            } else {
                m.insert(QStringLiteral("productionKwh"), 0.0);
                m.insert(QStringLiteral("dischargeKwh"), 0.0);
                m.insert(QStringLiteral("purchasedKwh"), 0.0);
                m.insert(QStringLiteral("consumptionKwh"), 0.0);
                m.insert(QStringLiteral("chargeKwh"), 0.0);
                m.insert(QStringLiteral("gridFeedInKwh"), 0.0);
            }
            items.push_back(m);
        }
    } else if (m_energyHistoryMode == 1) {
        for (int mo = 1; mo <= 12; ++mo) {
            const double summer = 0.35 + 0.65 * std::sin((mo - 1) / 11.0 * std::numbers::pi);
            QVariantMap m;
            m.insert(QStringLiteral("label"), QString::number(mo));
            m.insert(QStringLiteral("fullDate"), QStringLiteral("%1-%2").arg(m_energyHistoryDate.year()).arg(mo, 2, 10, QLatin1Char('0')));
            m.insert(QStringLiteral("productionKwh"), (320.0 + 680.0 * summer) * scale);
            m.insert(QStringLiteral("dischargeKwh"), (180.0 + 140.0 * summer) * scale);
            m.insert(QStringLiteral("purchasedKwh"), (420.0 - 250.0 * summer) * scale);
            m.insert(QStringLiteral("consumptionKwh"), (620.0 + 120.0 * (1.0 - summer)) * scale);
            m.insert(QStringLiteral("chargeKwh"), (200.0 + 150.0 * summer) * scale);
            m.insert(QStringLiteral("gridFeedInKwh"), (80.0 + 340.0 * summer) * scale);
            items.push_back(m);
        }
    } else {
        const int curY = QDate::currentDate().year();
        for (int y = curY - 4; y <= curY; ++y) {
            const double f = 0.85 + 0.05 * (y - (curY - 4));
            QVariantMap m;
            m.insert(QStringLiteral("label"), QString::number(y));
            m.insert(QStringLiteral("fullDate"), QString::number(y));
            m.insert(QStringLiteral("productionKwh"), 8400.0 * f * scale);
            m.insert(QStringLiteral("dischargeKwh"), 2600.0 * f * scale);
            m.insert(QStringLiteral("purchasedKwh"), 2900.0 * scale);
            m.insert(QStringLiteral("consumptionKwh"), 7200.0 * f * scale);
            m.insert(QStringLiteral("chargeKwh"), 2800.0 * f * scale);
            m.insert(QStringLiteral("gridFeedInKwh"), 3100.0 * f * scale);
            items.push_back(m);
        }
    }

    m_energyHistoryItems = items;
    emit energyHistoryChanged();
}

void AppController::onStationEnergyHistoryFetched(qint64 stationId, int granularity, const QVector<EnergyHistoryItem> &items)
{
    const int expectedGran = (m_energyHistoryMode == 0) ? 2 : (m_energyHistoryMode == 1 ? 3 : 4);
    if (stationId != m_selectedStationId || granularity != expectedGran) {
        return;
    }

    auto makeRow = [](const QString &label, const QString &fullDate, const EnergyHistoryItem *it) {
        QVariantMap m;
        m.insert(QStringLiteral("label"), label);
        m.insert(QStringLiteral("fullDate"), fullDate);
        m.insert(QStringLiteral("productionKwh"), it ? it->productionKwh : 0.0);
        m.insert(QStringLiteral("dischargeKwh"), it ? it->dischargeKwh : 0.0);
        m.insert(QStringLiteral("purchasedKwh"), it ? it->purchasedKwh : 0.0);
        m.insert(QStringLiteral("consumptionKwh"), it ? it->consumptionKwh : 0.0);
        m.insert(QStringLiteral("chargeKwh"), it ? it->chargeKwh : 0.0);
        m.insert(QStringLiteral("gridFeedInKwh"), it ? it->gridFeedInKwh : 0.0);
        return m;
    };

    QMap<QString, EnergyHistoryItem> byLabel;
    for (const EnergyHistoryItem &it : items) {
        byLabel.insert(it.label, it);
    }

    QVariantList list;
    if (m_energyHistoryMode == 0) {
        const int days = m_energyHistoryDate.daysInMonth();
        list.reserve(days);
        for (int d = 1; d <= days; ++d) {
            const QString lbl = QString::number(d);
            const QString full = QStringLiteral("%1-%2-%3")
                .arg(m_energyHistoryDate.year())
                .arg(m_energyHistoryDate.month(), 2, 10, QLatin1Char('0'))
                .arg(d, 2, 10, QLatin1Char('0'));
            const auto it = byLabel.constFind(lbl);
            list.push_back(makeRow(lbl, full, it != byLabel.constEnd() ? &it.value() : nullptr));
        }
    } else if (m_energyHistoryMode == 1) {
        list.reserve(12);
        for (int mo = 1; mo <= 12; ++mo) {
            const QString lbl = QString::number(mo);
            const QString full = QStringLiteral("%1-%2").arg(m_energyHistoryDate.year()).arg(mo, 2, 10, QLatin1Char('0'));
            const auto it = byLabel.constFind(lbl);
            list.push_back(makeRow(lbl, full, it != byLabel.constEnd() ? &it.value() : nullptr));
        }
    } else {
        list.reserve(items.size());
        for (const EnergyHistoryItem &it : items) {
            list.push_back(makeRow(it.label, it.fullDate, &it));
        }
    }

    m_energyHistoryItems = list;
    emit energyHistoryChanged();
}

void AppController::applyTelemetry(const StationLatestData &data)
{
    m_latest = data;
    if (data.lastUpdateTime > 0) {
        const QDateTime dt = QDateTime::fromSecsSinceEpoch(data.lastUpdateTime);
        m_lastUpdateText = dt.toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));
    } else {
        m_lastUpdateText = QDateTime::currentDateTime().toString(QStringLiteral("HH:mm:ss"));
    }
    emit telemetryChanged();
}

void AppController::onAuthenticated(const DeyeAuthResult &result)
{
    Q_UNUSED(result)
    m_loggedIn = true;
    emit sessionChanged();
    m_apiClient.fetchStations();
}

void AppController::onStationsFetched(const QVector<StationInfo> &stations)
{
    setBusy(false);
    m_stationModel.setStations(stations);

    if (stations.isEmpty()) {
        m_selectedStationIndex = -1;
        m_selectedStationId = 0;
        m_selectedStationName = QStringLiteral("No stations found");
        m_selectedStationLocation.clear();
        m_installedCapacityKw = 0.0;
        m_connectionStatus = QStringLiteral("UNKNOWN");
        emit selectedStationChanged();
        setErrorMessage(QStringLiteral("No solar stations were found on this Deye Cloud account."));
        return;
    }

    int targetIndex = 0;
    if (m_selectedStationId != 0) {
        const int existing = m_stationModel.indexOfStationId(m_selectedStationId);
        if (existing >= 0) {
            targetIndex = existing;
        }
    } else if (m_saved.lastStationId != 0) {
        const int savedIdx = m_stationModel.indexOfStationId(m_saved.lastStationId);
        if (savedIdx >= 0) {
            targetIndex = savedIdx;
        }
    }

    selectStationByIndex(targetIndex);
}

void AppController::onStationLatestFetched(qint64 stationId, const StationLatestData &data)
{
    setBusy(false);
    if (stationId != m_selectedStationId) {
        return;
    }
    clearError();
    applyTelemetry(data);
}

void AppController::onRequestFailed(const QString &context, const QString &message, bool authExpired)
{
    if (authExpired && m_loggedIn) {
        setBusy(false);
        logout();
        setErrorMessage(QStringLiteral("Session expired. Please sign in again. (%1)").arg(message));
        return;
    }
    // Inverter settings dialog handles its own config/order errors
    if (context == QStringLiteral("config_system")
        || context == QStringLiteral("config_battery")
        || context == QStringLiteral("config_tou")
        || context == QStringLiteral("order")) {
        return;
    }
    setBusy(false);
    if (context == QStringLiteral("auth")) {
        setErrorMessage(message);
    } else {
        setErrorMessage(QStringLiteral("[%1] %2").arg(context, message));
    }
}

} // namespace deye
