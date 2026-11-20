#include "AppController.h"

#include <QDateTime>
#include <cmath>

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
    m_autoRefreshEnabled = true;
    m_refreshIntervalSec = 120;

    m_refreshTimer.setInterval(m_refreshIntervalSec * 1000);
    connect(&m_refreshTimer, &QTimer::timeout, this, &AppController::refreshDashboard);

    connect(&m_apiClient, &DeyeApiClient::authenticated, this, &AppController::onAuthenticated);
    connect(&m_apiClient, &DeyeApiClient::stationsFetched, this, &AppController::onStationsFetched);
    connect(&m_apiClient, &DeyeApiClient::stationLatestFetched, this, &AppController::onStationLatestFetched);
    connect(&m_apiClient, &DeyeApiClient::stationDevicesFetched, this, &AppController::onStationDevicesFetched);
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
    emit devicesChanged();

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
        return;
    }
    setBusy(true);
    m_apiClient.fetchStationLatest(m_selectedStationId);
    m_apiClient.fetchStationDevices(m_selectedStationId);
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
