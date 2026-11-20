#pragma once

#include <QDateTime>
#include <QJsonObject>
#include <QString>
#include <QVector>
#include <QtGlobal>

namespace deye {

enum class LoginMethod : int {
    Email = 0,
    Phone = 1,
    Username = 2
};

struct DeyeRegion {
    QString name;
    QString baseUrl;
};

QVector<DeyeRegion> defaultRegions();

struct DeyeCredentials {
    QString baseUrl;
    QString appId;
    QString appSecret;
    LoginMethod loginMethod = LoginMethod::Email;
    QString email;
    QString countryCode;
    QString mobile;
    QString username;
    QString companyId; // Optional: for business/installer accounts
    QString password;

    [[nodiscard]] QString normalizedBaseUrl() const;
    [[nodiscard]] QString sha256PasswordHex() const;
    [[nodiscard]] QJsonObject toTokenRequestJson() const;
    [[nodiscard]] QString validate() const;
};

struct DeyeAuthResult {
    bool success = false;
    QString code;
    QString message;
    QString accessToken;
    QString refreshToken;
    QString tokenType = QStringLiteral("Bearer");
    qint64 expiresInSeconds = 0;

    static DeyeAuthResult fromJson(const QJsonObject &root);
};

struct StationInfo {
    qint64 id = 0;
    QString name;
    QString locationAddress;
    double installedCapacityKw = 0.0;
    QString connectionStatus = QStringLiteral("UNKNOWN");
    double generationPowerW = 0.0;
    double batterySoc = 0.0;
    qint64 lastUpdateTime = 0;

    static StationInfo fromJson(const QJsonObject &obj);
};

struct StationListResult {
    bool success = false;
    QString code;
    QString message;
    int total = 0;
    QVector<StationInfo> stations;

    static StationListResult fromJson(const QJsonObject &root);
};

struct DeviceInfo {
    qint64 deviceId = 0;
    QString deviceSn;
    QString deviceName;
    QString deviceType;
    QString productId;
    QString connectionStatus = QStringLiteral("UNKNOWN");
    qint64 collectionTime = 0; // Unix seconds

    static DeviceInfo fromJson(const QJsonObject &obj);
};

struct DeviceListResult {
    bool success = false;
    QString code;
    QString message;
    int total = 0;
    QVector<DeviceInfo> devices;

    static DeviceListResult fromJson(const QJsonObject &root);
};

struct InverterSystemConfig {
    bool success = false;
    QString code;
    QString message;
    QString workMode = QStringLiteral("ZERO_EXPORT_TO_CT");
    QString energyPattern = QStringLiteral("LOAD_FIRST");
    bool solarSell = false;
    QString limitControl = QStringLiteral("ZERO_EXPORT_TO_CT");
    int maxSellPower = 0;
    int maxSolarPower = 0;
    bool gridPeakShavingEnabled = false;
    int gridPeakShavingPower = 0;

    static InverterSystemConfig fromJson(const QJsonObject &root);
};

struct InverterBatteryConfig {
    bool success = false;
    QString code;
    QString message;
    QString batteryType = QStringLiteral("LITHIUM");
    bool gridChargeEnabled = false;
    bool genChargeEnabled = false;
    int maxChargeCurrent = 40;
    int maxDischargeCurrent = 40;
    int gridChargeAmpere = 30;
    int genChargeAmpere = 30;
    int batteryCapacityAh = 200;
    int shutdownSoc = 10;
    int lowBattSoc = 20;
    int restartSoc = 30;
    int gridChargeStartSoc = 20;
    int genChargeStartSoc = 20;
    double equalizationV = 57.6;
    double absorptionV = 57.6;
    double floatV = 55.2;

    static InverterBatteryConfig fromJson(const QJsonObject &root);
};

struct TouSlot {
    QString time = QStringLiteral("00:00");
    int soc = 50;
    int power = 3000;
    double voltage = 0.0;
    bool enableGridCharge = false;
    bool enableGeneration = false;

    [[nodiscard]] QJsonObject toJson() const;
    static TouSlot fromJson(const QJsonObject &obj);
};

struct InverterTouConfig {
    bool success = false;
    QString code;
    QString message;
    bool enabled = false;
    QVector<TouSlot> slotsList;

    static InverterTouConfig fromJson(const QJsonObject &root);
};

struct OrderResult {
    bool success = false;
    QString code;
    QString message;
    QString orderId;

    static OrderResult fromJson(const QJsonObject &root);
};

// Normalized live telemetry for a station:
// - generationPowerW: >= 0 (PV solar production in Watts)
// - consumptionPowerW: >= 0 (Home load in Watts)
// - batteryPowerW: > 0 charging, < 0 discharging, 0 idle
// - gridPowerW: > 0 importing from grid, < 0 exporting to grid, 0 idle
struct StationLatestData {
    bool success = false;
    QString code;
    QString message;
    double generationPowerW = 0.0;
    double consumptionPowerW = 0.0;
    double batteryPowerW = 0.0;
    double batterySoc = 0.0;
    bool hasBatterySoc = false;
    double gridPowerW = 0.0;
    qint64 lastUpdateTime = 0;

    static StationLatestData fromJson(const QJsonObject &root);
};

bool isApiSuccess(const QJsonObject &root, QString *outCode = nullptr, QString *outMsg = nullptr);

} // namespace deye
