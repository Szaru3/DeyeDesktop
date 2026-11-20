#pragma once

#include "api/DeyeApiClient.h"
#include "api/DeyeModels.h"

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>

namespace deye {

class InverterSettingsController : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString deviceSn READ deviceSn NOTIFY deviceChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY deviceChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY stateChanged)
    Q_PROPERTY(bool saving READ saving NOTIFY stateChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusChanged)
    Q_PROPERTY(bool statusIsError READ statusIsError NOTIFY statusChanged)
    Q_PROPERTY(QString systemReadNote READ systemReadNote NOTIFY readNotesChanged)
    Q_PROPERTY(QString batteryReadNote READ batteryReadNote NOTIFY readNotesChanged)
    Q_PROPERTY(QString touReadNote READ touReadNote NOTIFY readNotesChanged)

    // System Config
    Q_PROPERTY(QString workMode READ workMode NOTIFY systemConfigChanged)
    Q_PROPERTY(QString energyPattern READ energyPattern NOTIFY systemConfigChanged)
    Q_PROPERTY(bool solarSell READ solarSell NOTIFY systemConfigChanged)
    Q_PROPERTY(QString limitControl READ limitControl NOTIFY systemConfigChanged)
    Q_PROPERTY(int maxSellPower READ maxSellPower NOTIFY systemConfigChanged)
    Q_PROPERTY(int maxSolarPower READ maxSolarPower NOTIFY systemConfigChanged)
    Q_PROPERTY(bool gridPeakShavingEnabled READ gridPeakShavingEnabled NOTIFY systemConfigChanged)
    Q_PROPERTY(int gridPeakShavingPower READ gridPeakShavingPower NOTIFY systemConfigChanged)

    // Battery Config
    Q_PROPERTY(QString batteryType READ batteryType NOTIFY batteryConfigChanged)
    Q_PROPERTY(bool gridChargeEnabled READ gridChargeEnabled NOTIFY batteryConfigChanged)
    Q_PROPERTY(bool genChargeEnabled READ genChargeEnabled NOTIFY batteryConfigChanged)
    Q_PROPERTY(int maxChargeCurrent READ maxChargeCurrent NOTIFY batteryConfigChanged)
    Q_PROPERTY(int maxDischargeCurrent READ maxDischargeCurrent NOTIFY batteryConfigChanged)
    Q_PROPERTY(int gridChargeAmpere READ gridChargeAmpere NOTIFY batteryConfigChanged)
    Q_PROPERTY(int genChargeAmpere READ genChargeAmpere NOTIFY batteryConfigChanged)
    Q_PROPERTY(int batteryCapacityAh READ batteryCapacityAh NOTIFY batteryConfigChanged)
    Q_PROPERTY(int shutdownSoc READ shutdownSoc NOTIFY batteryConfigChanged)
    Q_PROPERTY(int lowBattSoc READ lowBattSoc NOTIFY batteryConfigChanged)
    Q_PROPERTY(int restartSoc READ restartSoc NOTIFY batteryConfigChanged)
    Q_PROPERTY(int gridChargeStartSoc READ gridChargeStartSoc NOTIFY batteryConfigChanged)
    Q_PROPERTY(int genChargeStartSoc READ genChargeStartSoc NOTIFY batteryConfigChanged)
    Q_PROPERTY(double equalizationV READ equalizationV NOTIFY batteryConfigChanged)
    Q_PROPERTY(double absorptionV READ absorptionV NOTIFY batteryConfigChanged)
    Q_PROPERTY(double floatV READ floatV NOTIFY batteryConfigChanged)

    // Time of Use Config
    Q_PROPERTY(bool touEnabled READ touEnabled NOTIFY touConfigChanged)
    Q_PROPERTY(QVariantList touSlots READ touSlots NOTIFY touConfigChanged)

public:
    explicit InverterSettingsController(DeyeApiClient *apiClient, QObject *parent = nullptr);

    void openForDevice(const QString &deviceSn, const QString &deviceName, bool demoMode);

    [[nodiscard]] QString deviceSn() const { return m_deviceSn; }
    [[nodiscard]] QString deviceName() const { return m_deviceName; }
    [[nodiscard]] bool loading() const { return m_pendingLoads > 0; }
    [[nodiscard]] bool saving() const { return m_saving; }
    [[nodiscard]] QString statusMessage() const { return m_statusMessage; }
    [[nodiscard]] bool statusIsError() const { return m_statusIsError; }
    [[nodiscard]] QString systemReadNote() const { return m_systemReadNote; }
    [[nodiscard]] QString batteryReadNote() const { return m_batteryReadNote; }
    [[nodiscard]] QString touReadNote() const { return m_touReadNote; }

    [[nodiscard]] QString workMode() const { return m_sys.workMode; }
    [[nodiscard]] QString energyPattern() const { return m_sys.energyPattern; }
    [[nodiscard]] bool solarSell() const { return m_sys.solarSell; }
    [[nodiscard]] QString limitControl() const { return m_sys.limitControl; }
    [[nodiscard]] int maxSellPower() const { return m_sys.maxSellPower; }
    [[nodiscard]] int maxSolarPower() const { return m_sys.maxSolarPower; }
    [[nodiscard]] bool gridPeakShavingEnabled() const { return m_sys.gridPeakShavingEnabled; }
    [[nodiscard]] int gridPeakShavingPower() const { return m_sys.gridPeakShavingPower; }

    [[nodiscard]] QString batteryType() const { return m_batt.batteryType; }
    [[nodiscard]] bool gridChargeEnabled() const { return m_batt.gridChargeEnabled; }
    [[nodiscard]] bool genChargeEnabled() const { return m_batt.genChargeEnabled; }
    [[nodiscard]] int maxChargeCurrent() const { return m_batt.maxChargeCurrent; }
    [[nodiscard]] int maxDischargeCurrent() const { return m_batt.maxDischargeCurrent; }
    [[nodiscard]] int gridChargeAmpere() const { return m_batt.gridChargeAmpere; }
    [[nodiscard]] int genChargeAmpere() const { return m_batt.genChargeAmpere; }
    [[nodiscard]] int batteryCapacityAh() const { return m_batt.batteryCapacityAh; }
    [[nodiscard]] int shutdownSoc() const { return m_batt.shutdownSoc; }
    [[nodiscard]] int lowBattSoc() const { return m_batt.lowBattSoc; }
    [[nodiscard]] int restartSoc() const { return m_batt.restartSoc; }
    [[nodiscard]] int gridChargeStartSoc() const { return m_batt.gridChargeStartSoc; }
    [[nodiscard]] int genChargeStartSoc() const { return m_batt.genChargeStartSoc; }
    [[nodiscard]] double equalizationV() const { return m_batt.equalizationV; }
    [[nodiscard]] double absorptionV() const { return m_batt.absorptionV; }
    [[nodiscard]] double floatV() const { return m_batt.floatV; }

    [[nodiscard]] bool touEnabled() const { return m_tou.enabled; }
    [[nodiscard]] QVariantList touSlots() const;

    Q_INVOKABLE void reload();
    Q_INVOKABLE void clearStatus();

    // System Orders
    Q_INVOKABLE void updateWorkMode(const QString &workMode);
    Q_INVOKABLE void updateEnergyPattern(const QString &energyPattern);
    Q_INVOKABLE void setSolarSell(bool enabled);
    Q_INVOKABLE void updateLimitControl(const QString &limitMode);
    Q_INVOKABLE void updatePowerLimit(const QString &powerType, int watts);
    Q_INVOKABLE void updateGridPeakShaving(bool enabled, int powerWatts);

    // Battery Orders
    Q_INVOKABLE void updateBatteryType(const QString &batteryType);
    Q_INVOKABLE void setBatteryModeControl(const QString &batteryModeType, bool enabled);
    Q_INVOKABLE void updateBatteryParameter(const QString &parameterType, double value);

    // TOU Orders
    Q_INVOKABLE void setTouEnabled(bool enabled);
    Q_INVOKABLE void updateTouSlot(int index, const QString &time, int soc, int power, double voltage, bool enableGridCharge, bool enableGeneration);
    Q_INVOKABLE void applyTouSchedule();

    // Advanced Custom Modbus Order
    Q_INVOKABLE void sendCustomControl(const QString &hexContent);

signals:
    void deviceChanged();
    void stateChanged();
    void statusChanged();
    void readNotesChanged();
    void systemConfigChanged();
    void batteryConfigChanged();
    void touConfigChanged();

private:
    void setStatus(const QString &msg, bool isError);
    void dispatchOrder(const QString &endpointPath, const QJsonObject &payload, const QString &description);
    void ensureSixTouSlots();
    void loadDemoDefaults();

    DeyeApiClient *m_apiClient = nullptr;
    QString m_deviceSn;
    QString m_deviceName;
    bool m_demoMode = false;
    int m_pendingLoads = 0;
    bool m_saving = false;
    QString m_statusMessage;
    bool m_statusIsError = false;
    QString m_systemReadNote;
    QString m_batteryReadNote;
    QString m_touReadNote;

    InverterSystemConfig m_sys;
    InverterBatteryConfig m_batt;
    InverterTouConfig m_tou;
};

} // namespace deye
