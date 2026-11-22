#pragma once

#include "api/DeyeApiClient.h"
#include "storage/SettingsStore.h"
#include "viewmodel/AlertListModel.h"
#include "viewmodel/DeviceListModel.h"
#include "viewmodel/InverterSettingsController.h"
#include "viewmodel/StationListModel.h"

#include <QDate>
#include <QObject>
#include <QSet>
#include <QStringList>
#include <QTimer>
#include <QVariantList>

namespace deye {

class AppController : public QObject {
    Q_OBJECT

    // Auth & UI State
    Q_PROPERTY(bool loggedIn READ loggedIn NOTIFY sessionChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool demoMode READ demoMode NOTIFY sessionChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(QStringList regionNames READ regionNames CONSTANT)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)

    // Saved Login Defaults
    Q_PROPERTY(int savedRegionIndex READ savedRegionIndex CONSTANT)
    Q_PROPERTY(QString savedCustomBaseUrl READ savedCustomBaseUrl CONSTANT)
    Q_PROPERTY(QString savedAppId READ savedAppId CONSTANT)
    Q_PROPERTY(QString savedAppSecret READ savedAppSecret CONSTANT)
    Q_PROPERTY(int savedLoginMethod READ savedLoginMethod CONSTANT)
    Q_PROPERTY(QString savedEmail READ savedEmail CONSTANT)
    Q_PROPERTY(QString savedCountryCode READ savedCountryCode CONSTANT)
    Q_PROPERTY(QString savedMobile READ savedMobile CONSTANT)
    Q_PROPERTY(QString savedUsername READ savedUsername CONSTANT)
    Q_PROPERTY(QString savedCompanyId READ savedCompanyId CONSTANT)
    Q_PROPERTY(QString savedPassword READ savedPassword CONSTANT)
    Q_PROPERTY(bool savedRememberMe READ savedRememberMe CONSTANT)

    // Stations, Devices & Alerts
    Q_PROPERTY(deye::StationListModel *stationModel READ stationModel CONSTANT)
    Q_PROPERTY(deye::DeviceListModel *deviceModel READ deviceModel CONSTANT)
    Q_PROPERTY(deye::AlertListModel *alertModel READ alertModel CONSTANT)
    Q_PROPERTY(deye::InverterSettingsController *inverterSettings READ inverterSettings CONSTANT)
    Q_PROPERTY(int deviceCount READ deviceCount NOTIFY devicesChanged)
    Q_PROPERTY(int alertCount READ alertCount NOTIFY alertsChanged)
    Q_PROPERTY(int activeAlertCount READ activeAlertCount NOTIFY alertsChanged)
    Q_PROPERTY(QVariantList batteryTemperatures READ batteryTemperatures NOTIFY batteryTemperaturesChanged)
    Q_PROPERTY(QVariantList otherTempSensors READ otherTempSensors NOTIFY batteryTemperaturesChanged)

    // Charts: Power Profile (Daily) & Generation & Usage History (M/Y/T)
    Q_PROPERTY(QString powerProfileDateText READ powerProfileDateText NOTIFY powerProfileChanged)
    Q_PROPERTY(QVariantList powerProfilePoints READ powerProfilePoints NOTIFY powerProfileChanged)
    Q_PROPERTY(int energyHistoryMode READ energyHistoryMode NOTIFY energyHistoryChanged) // 0=M, 1=Y, 2=T
    Q_PROPERTY(QString energyHistoryPeriodText READ energyHistoryPeriodText NOTIFY energyHistoryChanged)
    Q_PROPERTY(QVariantList energyHistoryItems READ energyHistoryItems NOTIFY energyHistoryChanged)
    Q_PROPERTY(int selectedStationIndex READ selectedStationIndex NOTIFY selectedStationChanged)
    Q_PROPERTY(qint64 selectedStationId READ selectedStationId NOTIFY selectedStationChanged)
    Q_PROPERTY(QString selectedStationName READ selectedStationName NOTIFY selectedStationChanged)
    Q_PROPERTY(QString selectedStationLocation READ selectedStationLocation NOTIFY selectedStationChanged)
    Q_PROPERTY(double installedCapacityKw READ installedCapacityKw NOTIFY selectedStationChanged)
    Q_PROPERTY(QString connectionStatus READ connectionStatus NOTIFY selectedStationChanged)

    // Live Telemetry
    Q_PROPERTY(double generationPowerW READ generationPowerW NOTIFY telemetryChanged)
    Q_PROPERTY(double consumptionPowerW READ consumptionPowerW NOTIFY telemetryChanged)
    Q_PROPERTY(double batteryPowerW READ batteryPowerW NOTIFY telemetryChanged)
    Q_PROPERTY(double batterySoc READ batterySoc NOTIFY telemetryChanged)
    Q_PROPERTY(bool hasBatterySoc READ hasBatterySoc NOTIFY telemetryChanged)
    Q_PROPERTY(double gridPowerW READ gridPowerW NOTIFY telemetryChanged)
    Q_PROPERTY(QString lastUpdateText READ lastUpdateText NOTIFY telemetryChanged)

    // Refresh
    Q_PROPERTY(bool autoRefreshEnabled READ autoRefreshEnabled WRITE setAutoRefreshEnabled NOTIFY refreshSettingsChanged)
    Q_PROPERTY(int refreshIntervalSec READ refreshIntervalSec NOTIFY refreshSettingsChanged)

public:
    explicit AppController(QObject *parent = nullptr);

    [[nodiscard]] bool loggedIn() const { return m_loggedIn; }
    [[nodiscard]] bool busy() const { return m_busy; }
    [[nodiscard]] bool demoMode() const { return m_demoMode; }
    [[nodiscard]] QString errorMessage() const { return m_errorMessage; }
    [[nodiscard]] QStringList regionNames() const { return m_regionNames; }
    [[nodiscard]] QString language() const { return m_language; }
    void setLanguage(const QString &lang);

    [[nodiscard]] int savedRegionIndex() const { return m_saved.regionIndex; }
    [[nodiscard]] QString savedCustomBaseUrl() const { return m_saved.customBaseUrl; }
    [[nodiscard]] QString savedAppId() const { return m_saved.appId; }
    [[nodiscard]] QString savedAppSecret() const { return m_saved.appSecret; }
    [[nodiscard]] int savedLoginMethod() const { return m_saved.loginMethod; }
    [[nodiscard]] QString savedEmail() const { return m_saved.email; }
    [[nodiscard]] QString savedCountryCode() const { return m_saved.countryCode; }
    [[nodiscard]] QString savedMobile() const { return m_saved.mobile; }
    [[nodiscard]] QString savedUsername() const { return m_saved.username; }
    [[nodiscard]] QString savedCompanyId() const { return m_saved.companyId; }
    [[nodiscard]] QString savedPassword() const { return m_saved.password; }
    [[nodiscard]] bool savedRememberMe() const { return m_saved.rememberMe; }

    [[nodiscard]] StationListModel *stationModel() { return &m_stationModel; }
    [[nodiscard]] DeviceListModel *deviceModel() { return &m_deviceModel; }
    [[nodiscard]] AlertListModel *alertModel() { return &m_alertModel; }
    [[nodiscard]] InverterSettingsController *inverterSettings() { return &m_inverterSettings; }
    [[nodiscard]] int deviceCount() const { return m_deviceModel.rowCount(); }
    [[nodiscard]] int alertCount() const { return m_alertModel.rowCount(); }
    [[nodiscard]] int activeAlertCount() const { return m_alertModel.activeCount(); }
    [[nodiscard]] QVariantList batteryTemperatures() const { return m_batteryTemperatures; }
    [[nodiscard]] QVariantList otherTempSensors() const { return m_otherTempSensors; }

    [[nodiscard]] QString powerProfileDateText() const { return m_powerProfileDate.toString(QStringLiteral("yyyy/MM/dd")); }
    [[nodiscard]] QVariantList powerProfilePoints() const { return m_powerProfilePoints; }
    [[nodiscard]] int energyHistoryMode() const { return m_energyHistoryMode; }
    [[nodiscard]] QString energyHistoryPeriodText() const;
    [[nodiscard]] QVariantList energyHistoryItems() const { return m_energyHistoryItems; }
    [[nodiscard]] int selectedStationIndex() const { return m_selectedStationIndex; }
    [[nodiscard]] qint64 selectedStationId() const { return m_selectedStationId; }
    [[nodiscard]] QString selectedStationName() const { return m_selectedStationName; }
    [[nodiscard]] QString selectedStationLocation() const { return m_selectedStationLocation; }
    [[nodiscard]] double installedCapacityKw() const { return m_installedCapacityKw; }
    [[nodiscard]] QString connectionStatus() const { return m_connectionStatus; }

    [[nodiscard]] double generationPowerW() const { return m_latest.generationPowerW; }
    [[nodiscard]] double consumptionPowerW() const { return m_latest.consumptionPowerW; }
    [[nodiscard]] double batteryPowerW() const { return m_latest.batteryPowerW; }
    [[nodiscard]] double batterySoc() const { return m_latest.batterySoc; }
    [[nodiscard]] bool hasBatterySoc() const { return m_latest.hasBatterySoc; }
    [[nodiscard]] double gridPowerW() const { return m_latest.gridPowerW; }
    [[nodiscard]] QString lastUpdateText() const { return m_lastUpdateText; }

    [[nodiscard]] bool autoRefreshEnabled() const { return m_autoRefreshEnabled; }
    [[nodiscard]] int refreshIntervalSec() const { return m_refreshIntervalSec; }
    void setAutoRefreshEnabled(bool enabled);

    Q_INVOKABLE void login(int regionIndex,
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
                           bool rememberMe);
    Q_INVOKABLE void loginDemo();
    Q_INVOKABLE void logout();
    Q_INVOKABLE void selectStationByIndex(int index);
    Q_INVOKABLE void openInverterSettings(const QString &deviceSn, const QString &deviceName);
    Q_INVOKABLE void renameDevice(const QString &deviceSn, const QString &newName);
    Q_INVOKABLE void shiftPowerProfileDate(int deltaDays);
    Q_INVOKABLE void setEnergyHistoryMode(int mode);
    Q_INVOKABLE void shiftEnergyHistoryPeriod(int delta);
    Q_INVOKABLE void refreshStations();
    Q_INVOKABLE void refreshDashboard();
    Q_INVOKABLE void clearError();
    Q_INVOKABLE QString formatPower(double watts) const;

signals:
    void sessionChanged();
    void busyChanged();
    void errorMessageChanged();
    void languageChanged();
    void selectedStationChanged();
    void devicesChanged();
    void alertsChanged();
    void batteryTemperaturesChanged();
    void powerProfileChanged();
    void energyHistoryChanged();
    void telemetryChanged();
    void refreshSettingsChanged();

private:
    void setBusy(bool busy);
    void setErrorMessage(const QString &msg);
    void updateTimerState();
    void applyDemoTelemetry(qint64 stationId);
    void applyDemoDevices(qint64 stationId);
    void applyDemoBatteryTemps(qint64 stationId);
    void applyDemoAlerts(qint64 stationId);
    void applyDemoPowerProfile(qint64 stationId);
    void applyDemoEnergyHistory(qint64 stationId);
    void rebuildBatteryTemperatureList();
    void fetchPowerProfile();
    void fetchEnergyHistory();
    void notifyNewFaults(const QVector<AlertInfo> &alerts);
    void sendDesktopNotification(const QString &title, const QString &body, bool isCritical);
    void applyTelemetry(const StationLatestData &data);
    void onAuthenticated(const DeyeAuthResult &result);
    void onStationsFetched(const QVector<StationInfo> &stations);
    void onStationLatestFetched(qint64 stationId, const StationLatestData &data);
    void onStationDevicesFetched(qint64 stationId, const QVector<DeviceInfo> &devices);
    void onDeviceBatteryTempsFetched(qint64 stationId, const QVector<BatteryTempReading> &readings);
    void onStationAlertsFetched(qint64 stationId, const QVector<AlertInfo> &alerts);
    void onStationPowerProfileFetched(qint64 stationId, const QString &dateYmd, const QVector<PowerProfilePoint> &points);
    void onStationEnergyHistoryFetched(qint64 stationId, int granularity, const QVector<EnergyHistoryItem> &items);
    void onRequestFailed(const QString &context, const QString &message, bool authExpired);

    DeyeApiClient m_apiClient;
    SettingsStore m_settingsStore;
    StationListModel m_stationModel;
    DeviceListModel m_deviceModel;
    AlertListModel m_alertModel;
    InverterSettingsController m_inverterSettings;
    QSet<QString> m_notifiedAlertIds;
    QTimer m_refreshTimer;

    QDate m_powerProfileDate = QDate::currentDate();
    QVariantList m_powerProfilePoints;
    QMap<QString, QString> m_deviceDisplayNames;
    QVector<BatteryTempReading> m_batteryTempReadings;
    QVariantList m_batteryTemperatures;
    QVariantList m_otherTempSensors;
    int m_energyHistoryMode = 0; // 0=M (granularity 2), 1=Y (granularity 3), 2=T (granularity 4)
    QDate m_energyHistoryDate = QDate::currentDate();
    QVariantList m_energyHistoryItems;

    QVector<DeyeRegion> m_regions;
    QStringList m_regionNames;
    SavedSettings m_saved;

    bool m_loggedIn = false;
    bool m_busy = false;
    bool m_demoMode = false;
    QString m_errorMessage;
    QString m_language = QStringLiteral("en");

    int m_selectedStationIndex = -1;
    qint64 m_selectedStationId = 0;
    QString m_selectedStationName;
    QString m_selectedStationLocation;
    double m_installedCapacityKw = 0.0;
    QString m_connectionStatus = QStringLiteral("UNKNOWN");

    StationLatestData m_latest;
    QString m_lastUpdateText = QStringLiteral("—");
    int m_demoTick = 0;

    bool m_autoRefreshEnabled = true;
    int m_refreshIntervalSec = 120;
};

} // namespace deye
