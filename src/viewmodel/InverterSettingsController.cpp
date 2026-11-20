#include "InverterSettingsController.h"

#include <QJsonArray>
#include <QVariantMap>

namespace deye {

InverterSettingsController::InverterSettingsController(DeyeApiClient *apiClient, QObject *parent)
    : QObject(parent)
    , m_apiClient(apiClient)
{
    ensureSixTouSlots();

    if (m_apiClient) {
        connect(m_apiClient, &DeyeApiClient::systemConfigFetched, this, [this](const QString &sn, const InverterSystemConfig &cfg) {
            if (sn != m_deviceSn) return;
            m_sys = cfg;
            if (m_pendingLoads > 0) --m_pendingLoads;
            emit systemConfigChanged();
            emit stateChanged();
        });

        connect(m_apiClient, &DeyeApiClient::batteryConfigFetched, this, [this](const QString &sn, const InverterBatteryConfig &cfg) {
            if (sn != m_deviceSn) return;
            m_batt = cfg;
            if (m_pendingLoads > 0) --m_pendingLoads;
            emit batteryConfigChanged();
            emit stateChanged();
        });

        connect(m_apiClient, &DeyeApiClient::touConfigFetched, this, [this](const QString &sn, const InverterTouConfig &cfg) {
            if (sn != m_deviceSn) return;
            m_tou = cfg;
            ensureSixTouSlots();
            if (m_pendingLoads > 0) --m_pendingLoads;
            emit touConfigChanged();
            emit stateChanged();
        });

        connect(m_apiClient, &DeyeApiClient::orderCompleted, this, [this](const QString &desc, const OrderResult &res) {
            m_saving = false;
            emit stateChanged();
            if (res.success) {
                const QString idPart = res.orderId.isEmpty() ? QString() : QStringLiteral(" (Order #%1)").arg(res.orderId);
                setStatus(QStringLiteral("%1 sent to inverter%2.").arg(desc, idPart), false);
            } else {
                const QString err = res.message.isEmpty() ? QStringLiteral("code %1").arg(res.code) : res.message;
                setStatus(QStringLiteral("%1 failed: %2").arg(desc, err), true);
            }
        });

        connect(m_apiClient, &DeyeApiClient::requestFailed, this, [this](const QString &ctx, const QString &msg, bool) {
            if (ctx == QStringLiteral("config_system")) {
                if (m_pendingLoads > 0) --m_pendingLoads;
                m_systemReadNote = QStringLiteral("Could not read current System config from this inverter: %1").arg(msg);
                emit readNotesChanged();
                emit stateChanged();
            } else if (ctx == QStringLiteral("config_battery")) {
                if (m_pendingLoads > 0) --m_pendingLoads;
                m_batteryReadNote = QStringLiteral("Could not read current Battery config from this inverter: %1").arg(msg);
                emit readNotesChanged();
                emit stateChanged();
            } else if (ctx == QStringLiteral("config_tou")) {
                if (m_pendingLoads > 0) --m_pendingLoads;
                m_touReadNote = QStringLiteral("Could not read current Time of Use config from this inverter: %1").arg(msg);
                emit readNotesChanged();
                emit stateChanged();
            }
        });
    }
}

void InverterSettingsController::openForDevice(const QString &deviceSn, const QString &deviceName, bool demoMode)
{
    m_deviceSn = deviceSn;
    m_deviceName = deviceName;
    m_demoMode = demoMode;
    clearStatus();
    emit deviceChanged();
    reload();
}

void InverterSettingsController::reload()
{
    if (m_deviceSn.isEmpty()) {
        return;
    }
    clearStatus();
    m_systemReadNote.clear();
    m_batteryReadNote.clear();
    m_touReadNote.clear();
    emit readNotesChanged();

    if (m_demoMode) {
        loadDemoDefaults();
        return;
    }

    m_pendingLoads = 3;
    emit stateChanged();
    m_apiClient->fetchSystemConfig(m_deviceSn);
    m_apiClient->fetchBatteryConfig(m_deviceSn);
    m_apiClient->fetchTouConfig(m_deviceSn);
}

void InverterSettingsController::clearStatus()
{
    setStatus({}, false);
}

void InverterSettingsController::setStatus(const QString &msg, bool isError)
{
    m_statusMessage = msg;
    m_statusIsError = isError;
    emit statusChanged();
}

void InverterSettingsController::ensureSixTouSlots()
{
    static const char *kDefaultTimes[6] = {"00:00", "04:00", "08:00", "12:00", "16:00", "20:00"};
    while (m_tou.slotsList.size() < 6) {
        TouSlot s;
        s.time = QString::fromLatin1(kDefaultTimes[m_tou.slotsList.size()]);
        s.soc = 50;
        s.power = 3000;
        s.voltage = 0.0;
        s.enableGridCharge = false;
        s.enableGeneration = false;
        m_tou.slotsList.push_back(s);
    }
    if (m_tou.slotsList.size() > 6) {
        m_tou.slotsList.resize(6);
    }
}

void InverterSettingsController::loadDemoDefaults()
{
    m_pendingLoads = 0;
    m_sys = InverterSystemConfig{};
    m_sys.workMode = QStringLiteral("ZERO_EXPORT_TO_CT");
    m_sys.energyPattern = QStringLiteral("LOAD_FIRST");
    m_sys.solarSell = true;
    m_sys.limitControl = QStringLiteral("ZERO_EXPORT_TO_CT");
    m_sys.maxSellPower = 8000;
    m_sys.maxSolarPower = 10400;
    m_sys.gridPeakShavingEnabled = false;
    m_sys.gridPeakShavingPower = 4000;

    m_batt = InverterBatteryConfig{};
    m_batt.batteryType = QStringLiteral("LITHIUM");
    m_batt.gridChargeEnabled = true;
    m_batt.genChargeEnabled = false;
    m_batt.maxChargeCurrent = 80;
    m_batt.maxDischargeCurrent = 100;
    m_batt.gridChargeAmpere = 40;
    m_batt.genChargeAmpere = 30;
    m_batt.batteryCapacityAh = 300;
    m_batt.shutdownSoc = 10;
    m_batt.lowBattSoc = 20;
    m_batt.restartSoc = 30;
    m_batt.gridChargeStartSoc = 20;
    m_batt.genChargeStartSoc = 20;
    m_batt.equalizationV = 57.6;
    m_batt.absorptionV = 57.6;
    m_batt.floatV = 55.2;

    m_tou = InverterTouConfig{};
    m_tou.enabled = true;
    m_tou.slotsList = {
        {QStringLiteral("00:00"), 80, 5000, 0.0, true, false},
        {QStringLiteral("05:00"), 50, 5000, 0.0, false, false},
        {QStringLiteral("09:00"), 100, 8000, 0.0, false, false},
        {QStringLiteral("14:00"), 95, 8000, 0.0, false, false},
        {QStringLiteral("17:00"), 30, 6000, 0.0, false, false},
        {QStringLiteral("22:00"), 60, 5000, 0.0, true, false}
    };

    emit systemConfigChanged();
    emit batteryConfigChanged();
    emit touConfigChanged();
    emit stateChanged();
}

QVariantList InverterSettingsController::touSlots() const
{
    QVariantList out;
    out.reserve(m_tou.slotsList.size());
    for (const TouSlot &s : m_tou.slotsList) {
        QVariantMap m;
        m.insert(QStringLiteral("time"), s.time);
        m.insert(QStringLiteral("soc"), s.soc);
        m.insert(QStringLiteral("power"), s.power);
        m.insert(QStringLiteral("voltage"), s.voltage);
        m.insert(QStringLiteral("enableGridCharge"), s.enableGridCharge);
        m.insert(QStringLiteral("enableGeneration"), s.enableGeneration);
        out.push_back(m);
    }
    return out;
}

void InverterSettingsController::dispatchOrder(const QString &endpointPath, const QJsonObject &payload, const QString &description)
{
    if (m_deviceSn.isEmpty()) {
        return;
    }
    if (m_demoMode) {
        setStatus(QStringLiteral("[Demo] %1 applied locally (would POST %2).").arg(description, endpointPath), false);
        return;
    }

    m_saving = true;
    emit stateChanged();
    m_apiClient->sendOrder(endpointPath, payload, description);
}

// --- System Orders ---

void InverterSettingsController::updateWorkMode(const QString &workMode)
{
    m_sys.workMode = workMode;
    emit systemConfigChanged();

    QJsonObject p;
    p.insert(QStringLiteral("deviceSn"), m_deviceSn);
    p.insert(QStringLiteral("workMode"), workMode);
    dispatchOrder(QStringLiteral("/v1.0/order/sys/workMode/update"), p, QStringLiteral("Work Mode"));
}

void InverterSettingsController::updateEnergyPattern(const QString &energyPattern)
{
    m_sys.energyPattern = energyPattern;
    emit systemConfigChanged();

    QJsonObject p;
    p.insert(QStringLiteral("deviceSn"), m_deviceSn);
    p.insert(QStringLiteral("energyPattern"), energyPattern);
    dispatchOrder(QStringLiteral("/v1.0/order/sys/energyPattern/update"), p, QStringLiteral("Energy Pattern"));
}

void InverterSettingsController::setSolarSell(bool enabled)
{
    m_sys.solarSell = enabled;
    emit systemConfigChanged();

    QJsonObject p;
    p.insert(QStringLiteral("deviceSn"), m_deviceSn);
    p.insert(QStringLiteral("action"), enabled ? QStringLiteral("on") : QStringLiteral("off"));
    dispatchOrder(QStringLiteral("/v1.0/order/sys/solarSell/control"), p, QStringLiteral("Solar Sell"));
}

void InverterSettingsController::updateLimitControl(const QString &limitMode)
{
    m_sys.limitControl = limitMode;
    emit systemConfigChanged();

    QJsonObject p;
    p.insert(QStringLiteral("deviceSn"), m_deviceSn);
    p.insert(QStringLiteral("limitMode"), limitMode);
    dispatchOrder(QStringLiteral("/v1.0/order/sys/limitControl"), p, QStringLiteral("Export Limit Control"));
}

void InverterSettingsController::updatePowerLimit(const QString &powerType, int watts)
{
    if (powerType == QStringLiteral("MAX_SELL_POWER")) {
        m_sys.maxSellPower = watts;
    } else if (powerType == QStringLiteral("MAX_SOLAR_POWER")) {
        m_sys.maxSolarPower = watts;
    }
    emit systemConfigChanged();

    QJsonObject p;
    p.insert(QStringLiteral("deviceSn"), m_deviceSn);
    p.insert(QStringLiteral("type"), powerType);
    p.insert(QStringLiteral("value"), watts);
    dispatchOrder(QStringLiteral("/v1.0/order/sys/power/update"), p, powerType);
}

void InverterSettingsController::updateGridPeakShaving(bool enabled, int powerWatts)
{
    m_sys.gridPeakShavingEnabled = enabled;
    m_sys.gridPeakShavingPower = powerWatts;
    emit systemConfigChanged();

    QJsonObject p;
    p.insert(QStringLiteral("deviceSn"), m_deviceSn);
    p.insert(QStringLiteral("action"), enabled ? QStringLiteral("on") : QStringLiteral("off"));
    p.insert(QStringLiteral("power"), powerWatts);
    dispatchOrder(QStringLiteral("/v1.0/order/gridPeakShaving/control"), p, QStringLiteral("Grid Peak Shaving"));
}

// --- Battery Orders ---

void InverterSettingsController::updateBatteryType(const QString &batteryType)
{
    m_batt.batteryType = batteryType;
    emit batteryConfigChanged();

    QJsonObject p;
    p.insert(QStringLiteral("deviceSn"), m_deviceSn);
    p.insert(QStringLiteral("batteryType"), batteryType);
    dispatchOrder(QStringLiteral("/v1.0/order/battery/type/update"), p, QStringLiteral("Battery Type"));
}

void InverterSettingsController::setBatteryModeControl(const QString &batteryModeType, bool enabled)
{
    if (batteryModeType == QStringLiteral("GRID_CHARGE")) {
        m_batt.gridChargeEnabled = enabled;
    } else if (batteryModeType == QStringLiteral("GEN_CHARGE")) {
        m_batt.genChargeEnabled = enabled;
    }
    emit batteryConfigChanged();

    QJsonObject p;
    p.insert(QStringLiteral("deviceSn"), m_deviceSn);
    p.insert(QStringLiteral("batteryModeType"), batteryModeType);
    p.insert(QStringLiteral("action"), enabled ? QStringLiteral("on") : QStringLiteral("off"));
    dispatchOrder(QStringLiteral("/v1.0/order/battery/modeControl"), p, batteryModeType);
}

void InverterSettingsController::updateBatteryParameter(const QString &parameterType, double value)
{
    if (parameterType == QStringLiteral("MAX_CHARGE_CURRENT")) m_batt.maxChargeCurrent = static_cast<int>(value);
    else if (parameterType == QStringLiteral("MAX_DISCHARGE_CURRENT")) m_batt.maxDischargeCurrent = static_cast<int>(value);
    else if (parameterType == QStringLiteral("GRID_CHARGE_AMPERE")) m_batt.gridChargeAmpere = static_cast<int>(value);
    else if (parameterType == QStringLiteral("GEN_CHARGE_AMPERE")) m_batt.genChargeAmpere = static_cast<int>(value);
    else if (parameterType == QStringLiteral("BATT_CAPACITY")) m_batt.batteryCapacityAh = static_cast<int>(value);
    else if (parameterType == QStringLiteral("SHUTDOWN_SOC")) m_batt.shutdownSoc = static_cast<int>(value);
    else if (parameterType == QStringLiteral("LOW_BATT_SOC")) m_batt.lowBattSoc = static_cast<int>(value);
    else if (parameterType == QStringLiteral("RESTART_SOC")) m_batt.restartSoc = static_cast<int>(value);
    else if (parameterType == QStringLiteral("GRID_CHARGE_START_SOC")) m_batt.gridChargeStartSoc = static_cast<int>(value);
    else if (parameterType == QStringLiteral("GEN_CHARGE_START_SOC")) m_batt.genChargeStartSoc = static_cast<int>(value);
    else if (parameterType == QStringLiteral("EQUALIZATION_V")) m_batt.equalizationV = value;
    else if (parameterType == QStringLiteral("ABSORPTION_V")) m_batt.absorptionV = value;
    else if (parameterType == QStringLiteral("FLOAT_V")) m_batt.floatV = value;
    emit batteryConfigChanged();

    QJsonObject p;
    p.insert(QStringLiteral("deviceSn"), m_deviceSn);
    p.insert(QStringLiteral("parameterType"), parameterType);
    p.insert(QStringLiteral("value"), value);
    dispatchOrder(QStringLiteral("/v1.0/order/battery/parameter/update"), p, parameterType);
}

// --- Time of Use Orders ---

void InverterSettingsController::setTouEnabled(bool enabled)
{
    m_tou.enabled = enabled;
    emit touConfigChanged();

    QJsonObject p;
    p.insert(QStringLiteral("deviceSn"), m_deviceSn);
    p.insert(QStringLiteral("action"), enabled ? QStringLiteral("on") : QStringLiteral("off"));
    dispatchOrder(QStringLiteral("/v1.0/order/sys/tou/switch"), p, QStringLiteral("Time of Use Switch"));
}

void InverterSettingsController::updateTouSlot(int index,
                                               const QString &time,
                                               int soc,
                                               int power,
                                               double voltage,
                                               bool enableGridCharge,
                                               bool enableGeneration)
{
    ensureSixTouSlots();
    if (index < 0 || index >= m_tou.slotsList.size()) {
        return;
    }
    TouSlot &slot = m_tou.slotsList[index];
    QString formattedTime = time.trimmed();
    if (formattedTime.contains(QLatin1Char(':'))) {
        const QStringList parts = formattedTime.split(QLatin1Char(':'));
        bool okH = false, okM = false;
        const int h = parts.value(0).toInt(&okH);
        const int m = parts.value(1).toInt(&okM);
        if (okH && okM) {
            formattedTime = QStringLiteral("%1:%2")
                .arg(std::clamp(h, 0, 23), 2, 10, QLatin1Char('0'))
                .arg(std::clamp(m, 0, 59), 2, 10, QLatin1Char('0'));
        }
    } else {
        bool okNum = false;
        const int raw = formattedTime.toInt(&okNum);
        if (okNum) {
            formattedTime = QStringLiteral("%1:%2")
                .arg(std::clamp(raw / 100, 0, 23), 2, 10, QLatin1Char('0'))
                .arg(std::clamp(raw % 100, 0, 59), 2, 10, QLatin1Char('0'));
        }
    }
    slot.time = formattedTime;
    slot.soc = std::clamp(soc, 0, 100);
    slot.power = std::max(0, power);
    slot.voltage = std::max(0.0, voltage);
    slot.enableGridCharge = enableGridCharge;
    slot.enableGeneration = enableGeneration;
    emit touConfigChanged();
}

void InverterSettingsController::applyTouSchedule()
{
    ensureSixTouSlots();
    QJsonArray items;
    for (const TouSlot &s : m_tou.slotsList) {
        items.append(s.toJson());
    }

    QJsonObject p;
    p.insert(QStringLiteral("deviceSn"), m_deviceSn);
    p.insert(QStringLiteral("timeUseSettingItems"), items);
    dispatchOrder(QStringLiteral("/v1.0/order/sys/tou/update"), p, QStringLiteral("Time of Use Schedule"));
}

// --- Advanced Custom Control ---

void InverterSettingsController::sendCustomControl(const QString &hexContent)
{
    const QString cleaned = hexContent.trimmed();
    if (cleaned.isEmpty()) {
        setStatus(QStringLiteral("Please enter a hex command frame."), true);
        return;
    }

    QJsonObject p;
    p.insert(QStringLiteral("deviceSn"), m_deviceSn);
    p.insert(QStringLiteral("content"), cleaned);
    dispatchOrder(QStringLiteral("/v1.0/order/customControl"), p, QStringLiteral("Custom Modbus Command"));
}

} // namespace deye
