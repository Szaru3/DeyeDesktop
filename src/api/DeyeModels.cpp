#include "DeyeModels.h"

#include <QCryptographicHash>
#include <QJsonArray>
#include <QJsonValue>
#include <cmath>

namespace deye {

namespace {

bool readOptionalDouble(const QJsonObject &obj, const QString &key, double &outValue)
{
    if (!obj.contains(key)) {
        return false;
    }
    const QJsonValue val = obj.value(key);
    if (val.isNull() || val.isUndefined()) {
        return false;
    }
    if (val.isDouble()) {
        outValue = val.toDouble();
        return true;
    }
    if (val.isString()) {
        bool ok = false;
        const double parsed = val.toString().toDouble(&ok);
        if (ok) {
            outValue = parsed;
            return true;
        }
    }
    return false;
}

qint64 readInt64(const QJsonObject &obj, const QString &key, qint64 fallback = 0)
{
    if (!obj.contains(key)) {
        return fallback;
    }
    const QJsonValue val = obj.value(key);
    if (val.isDouble()) {
        return static_cast<qint64>(val.toDouble());
    }
    if (val.isString()) {
        bool ok = false;
        const qint64 parsed = val.toString().toLongLong(&ok);
        return ok ? parsed : fallback;
    }
    return fallback;
}

QString normalizeConnectionStatus(const QJsonObject &obj)
{
    const QJsonValue connVal = obj.value(QStringLiteral("connectionStatus"));
    if (connVal.isString() && !connVal.toString().trimmed().isEmpty()) {
        return connVal.toString().trimmed().toUpper();
    }
    if (obj.contains(QStringLiteral("status"))) {
        const QJsonValue st = obj.value(QStringLiteral("status"));
        if (st.isDouble()) {
            const int code = st.toInt();
            if (code == 1) {
                return QStringLiteral("NORMAL");
            }
            if (code == 2) {
                return QStringLiteral("PARTIAL_OFFLINE");
            }
            if (code == 3 || code == 0) {
                return QStringLiteral("ALL_OFFLINE");
            }
        }
    }
    return QStringLiteral("UNKNOWN");
}

QString normalizeDeviceType(const QJsonValue &val)
{
    if (val.isString()) {
        const QString s = val.toString().trimmed();
        if (s.isEmpty()) {
            return QStringLiteral("Device");
        }
        const QString upper = s.toUpper();
        if (upper == QStringLiteral("INVERTER")) return QStringLiteral("Inverter");
        if (upper == QStringLiteral("MICRO_INVERTER")) return QStringLiteral("Microinverter");
        if (upper == QStringLiteral("COLLECTOR") || upper == QStringLiteral("LOGGER")) return QStringLiteral("Data Logger");
        if (upper == QStringLiteral("BATTERY")) return QStringLiteral("Battery");
        if (upper == QStringLiteral("METER")) return QStringLiteral("Smart Meter");
        if (upper == QStringLiteral("EV_CHARGER")) return QStringLiteral("EV Charger");
        return s;
    }
    if (val.isDouble()) {
        switch (val.toInt()) {
        case 1: return QStringLiteral("Inverter");
        case 2: return QStringLiteral("Data Logger");
        case 3: return QStringLiteral("Battery");
        case 4: return QStringLiteral("Smart Meter");
        default: return QStringLiteral("Device");
        }
    }
    return QStringLiteral("Device");
}

QString normalizeDeviceStatus(const QJsonObject &obj)
{
    const QJsonValue v = obj.contains(QStringLiteral("connectStatus"))
        ? obj.value(QStringLiteral("connectStatus"))
        : obj.value(QStringLiteral("connectionStatus"));
    if (v.isString()) {
        const QString u = v.toString().trimmed().toUpper();
        if (u == QStringLiteral("NORMAL") || u == QStringLiteral("ONLINE") || u == QStringLiteral("1")) {
            return QStringLiteral("NORMAL");
        }
        if (u == QStringLiteral("OFFLINE") || u == QStringLiteral("ALL_OFFLINE") || u == QStringLiteral("0")) {
            return QStringLiteral("ALL_OFFLINE");
        }
        if (!u.isEmpty()) {
            return u;
        }
    } else if (v.isDouble()) {
        const int code = v.toInt();
        if (code == 1) return QStringLiteral("NORMAL");
        if (code == 2) return QStringLiteral("PARTIAL_OFFLINE");
        if (code == 0) return QStringLiteral("ALL_OFFLINE");
    }
    return QStringLiteral("UNKNOWN");
}

QString normalizeTouTime(const QJsonValue &val)
{
    auto formatHm = [](int h, int m) {
        h = std::clamp(h, 0, 23);
        m = std::clamp(m, 0, 59);
        return QStringLiteral("%1:%2")
            .arg(h, 2, 10, QLatin1Char('0'))
            .arg(m, 2, 10, QLatin1Char('0'));
    };

    if (val.isDouble()) {
        const int raw = static_cast<int>(std::round(val.toDouble()));
        return formatHm(raw / 100, raw % 100);
    }

    const QString s = val.toString().trimmed();
    if (s.isEmpty()) {
        return {};
    }

    if (s.contains(QLatin1Char(':'))) {
        const QStringList parts = s.split(QLatin1Char(':'));
        bool okH = false;
        bool okM = false;
        const int h = parts.value(0).toInt(&okH);
        const int m = parts.value(1).toInt(&okM);
        if (okH && okM) {
            return formatHm(h, m);
        }
        return s;
    }

    bool okNum = false;
    const int raw = s.toInt(&okNum);
    if (okNum) {
        return formatHm(raw / 100, raw % 100);
    }
    return s;
}

} // namespace

QVector<DeyeRegion> defaultRegions()
{
    return {
        {QStringLiteral("Europe / EMEA (eu1)"), QStringLiteral("https://eu1-developer.deyecloud.com")},
        {QStringLiteral("Americas (us1)"), QStringLiteral("https://us1-developer.deyecloud.com")},
        {QStringLiteral("Custom URL"), QString()}
    };
}

QString DeyeCredentials::normalizedBaseUrl() const
{
    QString url = baseUrl.trimmed();
    while (url.endsWith(QLatin1Char('/'))) {
        url.chop(1);
    }
    return url;
}

QString DeyeCredentials::sha256PasswordHex() const
{
    const QByteArray digest = QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256);
    return QString::fromLatin1(digest.toHex()).toLower();
}

QJsonObject DeyeCredentials::toTokenRequestJson() const
{
    QJsonObject obj;
    obj.insert(QStringLiteral("appSecret"), appSecret.trimmed());
    obj.insert(QStringLiteral("password"), sha256PasswordHex());

    switch (loginMethod) {
    case LoginMethod::Email:
        obj.insert(QStringLiteral("email"), email.trimmed());
        break;
    case LoginMethod::Phone: {
        QString cc = countryCode.trimmed();
        if (cc.startsWith(QLatin1Char('+'))) {
            cc.remove(0, 1);
        }
        obj.insert(QStringLiteral("countryCode"), cc);
        obj.insert(QStringLiteral("mobile"), mobile.trimmed());
        break;
    }
    case LoginMethod::Username:
        obj.insert(QStringLiteral("username"), username.trimmed());
        break;
    }

    const QString trimmedCompany = companyId.trimmed();
    if (!trimmedCompany.isEmpty()) {
        obj.insert(QStringLiteral("companyId"), trimmedCompany);
    }

    return obj;
}

QString DeyeCredentials::validate() const
{
    if (normalizedBaseUrl().isEmpty() || !normalizedBaseUrl().startsWith(QStringLiteral("http"))) {
        return QStringLiteral("Please enter a valid Deye Cloud API base URL.");
    }
    if (appId.trimmed().isEmpty()) {
        return QStringLiteral("App ID is required.");
    }
    if (appSecret.trimmed().isEmpty()) {
        return QStringLiteral("App Secret is required.");
    }
    switch (loginMethod) {
    case LoginMethod::Email:
        if (email.trimmed().isEmpty()) {
            return QStringLiteral("Email address is required.");
        }
        break;
    case LoginMethod::Phone:
        if (countryCode.trimmed().isEmpty()) {
            return QStringLiteral("Country code is required for phone login.");
        }
        if (mobile.trimmed().isEmpty()) {
            return QStringLiteral("Mobile number is required for phone login.");
        }
        break;
    case LoginMethod::Username:
        if (username.trimmed().isEmpty()) {
            return QStringLiteral("Username is required.");
        }
        break;
    }
    if (password.isEmpty()) {
        return QStringLiteral("Password is required.");
    }
    return {};
}

bool isApiSuccess(const QJsonObject &root, QString *outCode, QString *outMsg)
{
    const QString code = root.value(QStringLiteral("code")).toVariant().toString();
    const QString msg = root.value(QStringLiteral("msg")).toString();
    if (outCode) {
        *outCode = code;
    }
    if (outMsg) {
        *outMsg = msg;
    }

    if (root.contains(QStringLiteral("success")) && root.value(QStringLiteral("success")).isBool()) {
        return root.value(QStringLiteral("success")).toBool();
    }
    return code == QStringLiteral("1000000") || code == QStringLiteral("0");
}

DeyeAuthResult DeyeAuthResult::fromJson(const QJsonObject &root)
{
    DeyeAuthResult result;
    result.success = isApiSuccess(root, &result.code, &result.message);

    // Some gateways return accessToken at root; others nest under "data".
    const QJsonObject payload = (root.contains(QStringLiteral("accessToken")) || !root.value(QStringLiteral("data")).isObject())
        ? root
        : root.value(QStringLiteral("data")).toObject();

    result.accessToken = payload.value(QStringLiteral("accessToken")).toString();
    result.refreshToken = payload.value(QStringLiteral("refreshToken")).toString();
    const QString type = payload.value(QStringLiteral("tokenType")).toString();
    if (!type.isEmpty()) {
        result.tokenType = type;
    }
    result.expiresInSeconds = readInt64(payload, QStringLiteral("expiresIn"), 0);

    if (result.success && result.accessToken.isEmpty()) {
        result.success = false;
        if (result.message.isEmpty()) {
            result.message = QStringLiteral("Authentication succeeded but no access token was returned.");
        }
    }
    return result;
}

StationInfo StationInfo::fromJson(const QJsonObject &obj)
{
    StationInfo info;
    info.id = readInt64(obj, QStringLiteral("id"), 0);
    info.name = obj.value(QStringLiteral("name")).toString();
    if (info.name.isEmpty()) {
        info.name = QStringLiteral("Station #%1").arg(info.id);
    }
    info.locationAddress = obj.value(QStringLiteral("locationAddress")).toString().trimmed();
    if (info.locationAddress.isEmpty()) {
        info.locationAddress = obj.value(QStringLiteral("address")).toString().trimmed();
    }
    if (info.locationAddress.isEmpty()) {
        QStringList parts;
        const QString city = obj.value(QStringLiteral("city")).toString().trimmed();
        const QString region = obj.value(QStringLiteral("region")).toString().trimmed();
        const QString country = obj.value(QStringLiteral("country")).toString().trimmed();
        if (!city.isEmpty()) parts.push_back(city);
        if (!region.isEmpty() && region != city) parts.push_back(region);
        if (!country.isEmpty()) parts.push_back(country);
        info.locationAddress = parts.join(QStringLiteral(", "));
    }
    if (!readOptionalDouble(obj, QStringLiteral("installedCapacity"), info.installedCapacityKw)) {
        readOptionalDouble(obj, QStringLiteral("capacity"), info.installedCapacityKw);
    }
    info.connectionStatus = normalizeConnectionStatus(obj);
    readOptionalDouble(obj, QStringLiteral("generationPower"), info.generationPowerW);
    readOptionalDouble(obj, QStringLiteral("batterySOC"), info.batterySoc);
    info.lastUpdateTime = readInt64(obj, QStringLiteral("lastUpdateTime"), 0);
    return info;
}

StationListResult StationListResult::fromJson(const QJsonObject &root)
{
    StationListResult result;
    result.success = isApiSuccess(root, &result.code, &result.message);
    if (!result.success) {
        return result;
    }

    const QJsonObject payload = (root.contains(QStringLiteral("stationList")) || !root.value(QStringLiteral("data")).isObject())
        ? root
        : root.value(QStringLiteral("data")).toObject();

    result.total = static_cast<int>(readInt64(payload, QStringLiteral("total"), 0));
    const QJsonArray arr = payload.value(QStringLiteral("stationList")).toArray();
    result.stations.reserve(arr.size());
    for (const QJsonValue &val : arr) {
        if (val.isObject()) {
            result.stations.push_back(StationInfo::fromJson(val.toObject()));
        }
    }
    if (result.total == 0 && !result.stations.isEmpty()) {
        result.total = static_cast<int>(result.stations.size());
    }
    return result;
}

DeviceInfo DeviceInfo::fromJson(const QJsonObject &obj)
{
    DeviceInfo info;
    info.deviceId = readInt64(obj, QStringLiteral("deviceId"), readInt64(obj, QStringLiteral("id"), 0));
    info.deviceSn = obj.value(QStringLiteral("deviceSn")).toString().trimmed();
    info.deviceType = normalizeDeviceType(obj.value(QStringLiteral("deviceType")));
    info.productId = obj.value(QStringLiteral("productId")).toString().trimmed();
    info.deviceName = obj.value(QStringLiteral("deviceName")).toString().trimmed();
    if (info.deviceName.isEmpty()) {
        if (!info.productId.isEmpty()) {
            info.deviceName = info.productId;
        } else if (!info.deviceSn.isEmpty()) {
            info.deviceName = QStringLiteral("%1 (%2)").arg(info.deviceType, info.deviceSn);
        } else {
            info.deviceName = info.deviceType;
        }
    }
    info.connectionStatus = normalizeDeviceStatus(obj);

    qint64 ts = readInt64(obj, QStringLiteral("collectionTime"), readInt64(obj, QStringLiteral("lastUpdateTime"), 0));
    if (ts > 100000000000LL) {
        ts /= 1000; // Convert milliseconds to seconds
    }
    info.collectionTime = ts;
    return info;
}

DeviceListResult DeviceListResult::fromJson(const QJsonObject &root)
{
    DeviceListResult result;
    result.success = isApiSuccess(root, &result.code, &result.message);
    if (!result.success) {
        return result;
    }

    const QJsonObject payload = (root.contains(QStringLiteral("deviceListItems"))
                                 || root.contains(QStringLiteral("deviceList"))
                                 || !root.value(QStringLiteral("data")).isObject())
        ? root
        : root.value(QStringLiteral("data")).toObject();

    result.total = static_cast<int>(readInt64(payload, QStringLiteral("total"), 0));
    const QJsonArray arr = payload.contains(QStringLiteral("deviceListItems"))
        ? payload.value(QStringLiteral("deviceListItems")).toArray()
        : payload.value(QStringLiteral("deviceList")).toArray();

    result.devices.reserve(arr.size());
    for (const QJsonValue &val : arr) {
        if (val.isObject()) {
            result.devices.push_back(DeviceInfo::fromJson(val.toObject()));
        }
    }
    if (result.total == 0 && !result.devices.isEmpty()) {
        result.total = static_cast<int>(result.devices.size());
    }
    return result;
}

StationLatestData StationLatestData::fromJson(const QJsonObject &root)
{
    StationLatestData data;
    data.success = isApiSuccess(root, &data.code, &data.message);
    if (!data.success) {
        return data;
    }

    const QJsonObject payload = (root.contains(QStringLiteral("generationPower"))
                                 || root.contains(QStringLiteral("consumptionPower"))
                                 || root.contains(QStringLiteral("batterySOC"))
                                 || !root.value(QStringLiteral("data")).isObject())
        ? root
        : root.value(QStringLiteral("data")).toObject();

    readOptionalDouble(payload, QStringLiteral("generationPower"), data.generationPowerW);
    data.generationPowerW = std::max(0.0, data.generationPowerW);

    if (!readOptionalDouble(payload, QStringLiteral("consumptionPower"), data.consumptionPowerW)) {
        readOptionalDouble(payload, QStringLiteral("usePower"), data.consumptionPowerW);
    }
    data.consumptionPowerW = std::max(0.0, data.consumptionPowerW);

    data.hasBatterySoc = readOptionalDouble(payload, QStringLiteral("batterySOC"), data.batterySoc);
    if (data.hasBatterySoc) {
        data.batterySoc = std::clamp(data.batterySoc, 0.0, 100.0);
    }

    // Normalize battery power: positive = charging, negative = discharging
    double chargeW = 0.0;
    double dischargeW = 0.0;
    double rawBatteryW = 0.0;
    const bool hasCharge = readOptionalDouble(payload, QStringLiteral("chargePower"), chargeW);
    const bool hasDischarge = readOptionalDouble(payload, QStringLiteral("dischargePower"), dischargeW);
    const bool hasBattery = readOptionalDouble(payload, QStringLiteral("batteryPower"), rawBatteryW);

    if (hasCharge && std::abs(chargeW) > 0.01 && (!hasDischarge || std::abs(dischargeW) <= 0.01)) {
        data.batteryPowerW = std::abs(chargeW);
    } else if (hasDischarge && std::abs(dischargeW) > 0.01 && (!hasCharge || std::abs(chargeW) <= 0.01)) {
        data.batteryPowerW = -std::abs(dischargeW);
    } else if (hasBattery) {
        // In Deye Cloud /station/latest, negative batteryPower indicates charging
        data.batteryPowerW = -rawBatteryW;
    }

    // Normalize grid power: positive = importing from grid, negative = exporting to grid
    double wireW = 0.0;
    double purchaseW = 0.0;
    double gridW = 0.0;
    const bool hasWire = readOptionalDouble(payload, QStringLiteral("wirePower"), wireW);
    const bool hasPurchase = readOptionalDouble(payload, QStringLiteral("purchasePower"), purchaseW);
    const bool hasGrid = readOptionalDouble(payload, QStringLiteral("gridPower"), gridW);

    if (hasWire && std::abs(wireW) > 0.01) {
        data.gridPowerW = wireW;
    } else if (hasPurchase && std::abs(purchaseW) > 0.01) {
        data.gridPowerW = std::abs(purchaseW);
    } else if (hasGrid) {
        data.gridPowerW = gridW;
    } else if (hasWire) {
        data.gridPowerW = wireW;
    }

    data.lastUpdateTime = readInt64(payload, QStringLiteral("lastUpdateTime"), 0);
    return data;
}

namespace {

bool readOptionalBool(const QJsonObject &obj, const QString &key, bool &outValue)
{
    if (!obj.contains(key)) {
        return false;
    }
    const QJsonValue v = obj.value(key);
    if (v.isBool()) {
        outValue = v.toBool();
        return true;
    }
    if (v.isDouble()) {
        outValue = v.toInt() != 0;
        return true;
    }
    if (v.isString()) {
        const QString s = v.toString().trimmed().toLower();
        if (s == QStringLiteral("true") || s == QStringLiteral("on") || s == QStringLiteral("1") || s == QStringLiteral("enable") || s == QStringLiteral("enabled")) {
            outValue = true;
            return true;
        }
        if (s == QStringLiteral("false") || s == QStringLiteral("off") || s == QStringLiteral("0") || s == QStringLiteral("disable") || s == QStringLiteral("disabled")) {
            outValue = false;
            return true;
        }
    }
    return false;
}

QJsonObject unwrapDataObject(const QJsonObject &root)
{
    if (root.value(QStringLiteral("data")).isObject()) {
        return root.value(QStringLiteral("data")).toObject();
    }
    return root;
}

} // namespace

InverterSystemConfig InverterSystemConfig::fromJson(const QJsonObject &root)
{
    InverterSystemConfig cfg;
    cfg.success = isApiSuccess(root, &cfg.code, &cfg.message);
    if (!cfg.success) {
        return cfg;
    }

    const QJsonObject p = unwrapDataObject(root);
    const QString wm = p.value(QStringLiteral("workMode")).toString().trimmed();
    if (!wm.isEmpty()) cfg.workMode = wm;

    const QString ep = p.value(QStringLiteral("energyPattern")).toString().trimmed();
    if (!ep.isEmpty()) cfg.energyPattern = ep;

    readOptionalBool(p, QStringLiteral("solarSell"), cfg.solarSell);

    const QString lc = p.value(QStringLiteral("limitControl")).toString().trimmed();
    if (!lc.isEmpty()) cfg.limitControl = lc;

    double val = 0.0;
    if (readOptionalDouble(p, QStringLiteral("maxSellPower"), val)) cfg.maxSellPower = static_cast<int>(std::round(val));
    if (readOptionalDouble(p, QStringLiteral("maxSolarPower"), val)) cfg.maxSolarPower = static_cast<int>(std::round(val));

    if (!readOptionalBool(p, QStringLiteral("gridPeakShaving"), cfg.gridPeakShavingEnabled)) {
        readOptionalBool(p, QStringLiteral("peakShavingEnable"), cfg.gridPeakShavingEnabled);
    }
    if (readOptionalDouble(p, QStringLiteral("gridPeakShavingPower"), val)
        || readOptionalDouble(p, QStringLiteral("peakShavingPower"), val)) {
        cfg.gridPeakShavingPower = static_cast<int>(std::round(val));
    }
    return cfg;
}

InverterBatteryConfig InverterBatteryConfig::fromJson(const QJsonObject &root)
{
    InverterBatteryConfig cfg;
    cfg.success = isApiSuccess(root, &cfg.code, &cfg.message);
    if (!cfg.success) {
        return cfg;
    }

    const QJsonObject p = unwrapDataObject(root);
    const QString bt = p.value(QStringLiteral("batteryType")).toString().trimmed();
    if (!bt.isEmpty()) cfg.batteryType = bt;

    readOptionalBool(p, QStringLiteral("gridCharge"), cfg.gridChargeEnabled);
    readOptionalBool(p, QStringLiteral("genCharge"), cfg.genChargeEnabled);

    double v = 0.0;
    if (readOptionalDouble(p, QStringLiteral("maxChargeCurrent"), v)) cfg.maxChargeCurrent = static_cast<int>(std::round(v));
    if (readOptionalDouble(p, QStringLiteral("maxDischargeCurrent"), v)) cfg.maxDischargeCurrent = static_cast<int>(std::round(v));
    if (readOptionalDouble(p, QStringLiteral("gridChargeAmpere"), v)
        || readOptionalDouble(p, QStringLiteral("maxGridChargeCurrent"), v)) {
        cfg.gridChargeAmpere = static_cast<int>(std::round(v));
    }
    if (readOptionalDouble(p, QStringLiteral("genChargeAmpere"), v)
        || readOptionalDouble(p, QStringLiteral("maxGenChargeCurrent"), v)) {
        cfg.genChargeAmpere = static_cast<int>(std::round(v));
    }
    if (readOptionalDouble(p, QStringLiteral("batteryCapacity"), v)
        || readOptionalDouble(p, QStringLiteral("battCapacity"), v)) {
        cfg.batteryCapacityAh = static_cast<int>(std::round(v));
    }
    if (readOptionalDouble(p, QStringLiteral("shutdownSOC"), v)
        || readOptionalDouble(p, QStringLiteral("shutdownSoc"), v)) {
        cfg.shutdownSoc = static_cast<int>(std::round(v));
    }
    if (readOptionalDouble(p, QStringLiteral("lowSOC"), v)
        || readOptionalDouble(p, QStringLiteral("lowBattSoc"), v)) {
        cfg.lowBattSoc = static_cast<int>(std::round(v));
    }
    if (readOptionalDouble(p, QStringLiteral("restartSOC"), v)
        || readOptionalDouble(p, QStringLiteral("restartSoc"), v)) {
        cfg.restartSoc = static_cast<int>(std::round(v));
    }
    if (readOptionalDouble(p, QStringLiteral("gridChargeStartSoc"), v)
        || readOptionalDouble(p, QStringLiteral("gridChargeStartSOC"), v)) {
        cfg.gridChargeStartSoc = static_cast<int>(std::round(v));
    }
    if (readOptionalDouble(p, QStringLiteral("genChargeStartSoc"), v)
        || readOptionalDouble(p, QStringLiteral("genChargeStartSOC"), v)) {
        cfg.genChargeStartSoc = static_cast<int>(std::round(v));
    }
    if (readOptionalDouble(p, QStringLiteral("equalizationV"), v)) cfg.equalizationV = v;
    if (readOptionalDouble(p, QStringLiteral("absorptionV"), v)) cfg.absorptionV = v;
    if (readOptionalDouble(p, QStringLiteral("floatV"), v)
        || readOptionalDouble(p, QStringLiteral("floatVoltage"), v)) {
        cfg.floatV = v;
    }
    return cfg;
}

QJsonObject TouSlot::toJson() const
{
    QJsonObject o;
    o.insert(QStringLiteral("time"), time);
    o.insert(QStringLiteral("soc"), soc);
    o.insert(QStringLiteral("power"), power);
    o.insert(QStringLiteral("voltage"), voltage);
    o.insert(QStringLiteral("enableGridCharge"), enableGridCharge);
    o.insert(QStringLiteral("enableGeneration"), enableGeneration);
    return o;
}

TouSlot TouSlot::fromJson(const QJsonObject &obj)
{
    TouSlot s;
    QString t = normalizeTouTime(obj.value(QStringLiteral("time")));
    if (t.isEmpty()) {
        t = normalizeTouTime(obj.value(QStringLiteral("startTime")));
    }
    if (!t.isEmpty()) {
        s.time = t;
    }

    double v = 0.0;
    if (readOptionalDouble(obj, QStringLiteral("soc"), v)) s.soc = static_cast<int>(std::round(v));
    if (readOptionalDouble(obj, QStringLiteral("power"), v)) s.power = static_cast<int>(std::round(v));
    if (readOptionalDouble(obj, QStringLiteral("voltage"), v)) s.voltage = v;

    if (!readOptionalBool(obj, QStringLiteral("enableGridCharge"), s.enableGridCharge)) {
        readOptionalBool(obj, QStringLiteral("charge"), s.enableGridCharge);
    }
    readOptionalBool(obj, QStringLiteral("enableGeneration"), s.enableGeneration);
    return s;
}

InverterTouConfig InverterTouConfig::fromJson(const QJsonObject &root)
{
    InverterTouConfig cfg;
    cfg.success = isApiSuccess(root, &cfg.code, &cfg.message);
    if (!cfg.success) {
        return cfg;
    }

    const QJsonObject p = unwrapDataObject(root);
    if (!readOptionalBool(p, QStringLiteral("touAction"), cfg.enabled)) {
        readOptionalBool(p, QStringLiteral("enable"), cfg.enabled);
    }

    const QJsonArray arr = p.value(QStringLiteral("timeUseSettingItems")).toArray();
    for (const QJsonValue &val : arr) {
        if (val.isObject()) {
            cfg.slotsList.push_back(TouSlot::fromJson(val.toObject()));
        }
    }
    return cfg;
}

OrderResult OrderResult::fromJson(const QJsonObject &root)
{
    OrderResult r;
    r.success = isApiSuccess(root, &r.code, &r.message);
    const QJsonObject p = unwrapDataObject(root);
    if (p.contains(QStringLiteral("orderId"))) {
        r.orderId = p.value(QStringLiteral("orderId")).toVariant().toString();
    } else if (root.contains(QStringLiteral("orderId"))) {
        r.orderId = root.value(QStringLiteral("orderId")).toVariant().toString();
    }
    return r;
}

} // namespace deye
