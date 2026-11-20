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
    info.locationAddress = obj.value(QStringLiteral("locationAddress")).toString();
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

} // namespace deye
