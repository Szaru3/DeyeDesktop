#include "DeyeApiClient.h"

#include <QDate>
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>
#include <QUrlQuery>

namespace deye {

namespace {
constexpr int kRequestTimeoutMs = 15000;
}

DeyeApiClient::DeyeApiClient(QObject *parent)
    : QObject(parent)
{
}

void DeyeApiClient::setBaseUrl(const QString &baseUrl)
{
    QString normalized = baseUrl.trimmed();
    while (normalized.endsWith(QLatin1Char('/'))) {
        normalized.chop(1);
    }
    m_baseUrl = normalized;
}

void DeyeApiClient::setAccessToken(const QString &token)
{
    m_accessToken = token.trimmed();
}

void DeyeApiClient::clearSession()
{
    m_accessToken.clear();
}

QNetworkRequest DeyeApiClient::buildRequest(const QUrl &url, bool includeAuth) const
{
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    req.setRawHeader("Accept", "application/json");
    req.setTransferTimeout(kRequestTimeoutMs);
    if (includeAuth && !m_accessToken.isEmpty()) {
        req.setRawHeader("Authorization", QByteArray("Bearer ") + m_accessToken.toUtf8());
    }
    return req;
}

bool DeyeApiClient::isAuthErrorCode(const QString &code, int httpStatus)
{
    if (httpStatus == 401 || httpStatus == 403) {
        return true;
    }
    // Common Deye/Solarman token expiry / unauthorized API codes
    return code == QStringLiteral("2101019")
        || code == QStringLiteral("2101018")
        || code == QStringLiteral("2101017")
        || code == QStringLiteral("401");
}

void DeyeApiClient::authenticate(const DeyeCredentials &credentials)
{
    setBaseUrl(credentials.normalizedBaseUrl());

    QUrl url(m_baseUrl + QStringLiteral("/v1.0/account/token"));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("appId"), credentials.appId.trimmed());
    url.setQuery(query);

    const QByteArray payload = QJsonDocument(credentials.toTokenRequestJson()).toJson(QJsonDocument::Compact);
    QNetworkReply *reply = m_network.post(buildRequest(url, false), payload);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        const int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        const QByteArray body = reply->readAll();

        QJsonParseError parseErr{};
        const QJsonDocument doc = QJsonDocument::fromJson(body, &parseErr);

        if (reply->error() != QNetworkReply::NoError && (parseErr.error != QJsonParseError::NoError || !doc.isObject())) {
            emit requestFailed(QStringLiteral("auth"),
                               QStringLiteral("Network error (%1): %2").arg(httpStatus).arg(reply->errorString()),
                               false);
            return;
        }

        if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
            emit requestFailed(QStringLiteral("auth"),
                               QStringLiteral("Invalid JSON response from server."),
                               false);
            return;
        }

        const DeyeAuthResult result = DeyeAuthResult::fromJson(doc.object());
        if (!result.success) {
            const QString msg = result.message.isEmpty()
                ? QStringLiteral("Authentication failed (code %1).").arg(result.code)
                : QStringLiteral("%1 (code %2)").arg(result.message, result.code);
            emit requestFailed(QStringLiteral("auth"), msg, false);
            return;
        }

        m_accessToken = result.accessToken;
        emit authenticated(result);
    });
}

void DeyeApiClient::fetchStations(int page, int size)
{
    if (m_baseUrl.isEmpty() || m_accessToken.isEmpty()) {
        emit requestFailed(QStringLiteral("stations"), QStringLiteral("Not authenticated."), true);
        return;
    }

    const QUrl url(m_baseUrl + QStringLiteral("/v1.0/station/list"));
    QJsonObject bodyObj;
    bodyObj.insert(QStringLiteral("page"), page);
    bodyObj.insert(QStringLiteral("size"), size);

    const QByteArray payload = QJsonDocument(bodyObj).toJson(QJsonDocument::Compact);
    QNetworkReply *reply = m_network.post(buildRequest(url, true), payload);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        const int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        const QByteArray body = reply->readAll();

        QJsonParseError parseErr{};
        const QJsonDocument doc = QJsonDocument::fromJson(body, &parseErr);

        if (reply->error() != QNetworkReply::NoError && (parseErr.error != QJsonParseError::NoError || !doc.isObject())) {
            emit requestFailed(QStringLiteral("stations"),
                               QStringLiteral("Failed to load stations (%1): %2").arg(httpStatus).arg(reply->errorString()),
                               isAuthErrorCode({}, httpStatus));
            return;
        }

        if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
            emit requestFailed(QStringLiteral("stations"),
                               QStringLiteral("Invalid station list response."),
                               false);
            return;
        }

        const StationListResult result = StationListResult::fromJson(doc.object());
        if (!result.success) {
            const QString msg = result.message.isEmpty()
                ? QStringLiteral("Failed to fetch stations (code %1).").arg(result.code)
                : QStringLiteral("%1 (code %2)").arg(result.message, result.code);
            emit requestFailed(QStringLiteral("stations"), msg, isAuthErrorCode(result.code, httpStatus));
            return;
        }

        emit stationsFetched(result.stations);
    });
}

void DeyeApiClient::fetchStationLatest(qint64 stationId)
{
    if (m_baseUrl.isEmpty() || m_accessToken.isEmpty()) {
        emit requestFailed(QStringLiteral("latest"), QStringLiteral("Not authenticated."), true);
        return;
    }

    const QUrl url(m_baseUrl + QStringLiteral("/v1.0/station/latest"));
    QJsonObject bodyObj;
    bodyObj.insert(QStringLiteral("stationId"), stationId);

    const QByteArray payload = QJsonDocument(bodyObj).toJson(QJsonDocument::Compact);
    QNetworkReply *reply = m_network.post(buildRequest(url, true), payload);

    connect(reply, &QNetworkReply::finished, this, [this, reply, stationId]() {
        reply->deleteLater();
        const int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        const QByteArray body = reply->readAll();

        QJsonParseError parseErr{};
        const QJsonDocument doc = QJsonDocument::fromJson(body, &parseErr);

        if (reply->error() != QNetworkReply::NoError && (parseErr.error != QJsonParseError::NoError || !doc.isObject())) {
            emit requestFailed(QStringLiteral("latest"),
                               QStringLiteral("Failed to load telemetry (%1): %2").arg(httpStatus).arg(reply->errorString()),
                               isAuthErrorCode({}, httpStatus));
            return;
        }

        if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
            emit requestFailed(QStringLiteral("latest"),
                               QStringLiteral("Invalid telemetry response."),
                               false);
            return;
        }

        const StationLatestData data = StationLatestData::fromJson(doc.object());
        if (!data.success) {
            const QString msg = data.message.isEmpty()
                ? QStringLiteral("Failed to fetch station data (code %1).").arg(data.code)
                : QStringLiteral("%1 (code %2)").arg(data.message, data.code);
            emit requestFailed(QStringLiteral("latest"), msg, isAuthErrorCode(data.code, httpStatus));
            return;
        }

        emit stationLatestFetched(stationId, data);
    });
}

void DeyeApiClient::fetchStationDevices(qint64 stationId, int page, int size)
{
    if (m_baseUrl.isEmpty() || m_accessToken.isEmpty()) {
        emit requestFailed(QStringLiteral("devices"), QStringLiteral("Not authenticated."), true);
        return;
    }

    const QUrl url(m_baseUrl + QStringLiteral("/v1.0/station/device"));
    QJsonObject bodyObj;
    QJsonArray ids;
    ids.append(stationId);
    bodyObj.insert(QStringLiteral("stationIds"), ids);
    bodyObj.insert(QStringLiteral("page"), page);
    bodyObj.insert(QStringLiteral("size"), size);

    const QByteArray payload = QJsonDocument(bodyObj).toJson(QJsonDocument::Compact);
    QNetworkReply *reply = m_network.post(buildRequest(url, true), payload);

    connect(reply, &QNetworkReply::finished, this, [this, reply, stationId]() {
        reply->deleteLater();
        const int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        const QByteArray body = reply->readAll();

        QJsonParseError parseErr{};
        const QJsonDocument doc = QJsonDocument::fromJson(body, &parseErr);

        if (reply->error() != QNetworkReply::NoError && (parseErr.error != QJsonParseError::NoError || !doc.isObject())) {
            emit requestFailed(QStringLiteral("devices"),
                               QStringLiteral("Failed to load devices (%1): %2").arg(httpStatus).arg(reply->errorString()),
                               isAuthErrorCode({}, httpStatus));
            return;
        }

        if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
            emit requestFailed(QStringLiteral("devices"),
                               QStringLiteral("Invalid device list response."),
                               false);
            return;
        }

        const DeviceListResult result = DeviceListResult::fromJson(doc.object());
        if (!result.success) {
            const QString msg = result.message.isEmpty()
                ? QStringLiteral("Failed to fetch devices (code %1).").arg(result.code)
                : QStringLiteral("%1 (code %2)").arg(result.message, result.code);
            emit requestFailed(QStringLiteral("devices"), msg, isAuthErrorCode(result.code, httpStatus));
            return;
        }

        emit stationDevicesFetched(stationId, result.devices);
    });
}

void DeyeApiClient::fetchDevicesLatestTemps(qint64 stationId, const QStringList &deviceSns)
{
    if (m_baseUrl.isEmpty() || m_accessToken.isEmpty() || deviceSns.isEmpty()) {
        return;
    }

    // Deye Cloud /v1.0/device/latest accepts up to 10 devices per request.
    constexpr int kBatchSize = 10;
    const QUrl url(m_baseUrl + QStringLiteral("/v1.0/device/latest"));

    for (int offset = 0; offset < deviceSns.size(); offset += kBatchSize) {
        QJsonArray arr;
        const int end = std::min(offset + kBatchSize, static_cast<int>(deviceSns.size()));
        for (int i = offset; i < end; ++i) {
            arr.append(deviceSns.at(i));
        }
        QJsonObject bodyObj;
        bodyObj.insert(QStringLiteral("deviceList"), arr);

        QNetworkReply *reply = m_network.post(buildRequest(url, true), QJsonDocument(bodyObj).toJson(QJsonDocument::Compact));
        connect(reply, &QNetworkReply::finished, this, [this, reply, stationId]() {
            reply->deleteLater();
            const QByteArray raw = reply->readAll();
            if (qEnvironmentVariableIntValue("DEYE_DEBUG_DEVICE_LATEST") == 1) {
                qDebug().noquote() << "[device/latest]" << QString::fromUtf8(raw);
            }
            QJsonParseError parseErr{};
            const QJsonDocument doc = QJsonDocument::fromJson(raw, &parseErr);
            if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
                return;
            }
            const DeviceLatestTempsResult res = DeviceLatestTempsResult::fromJson(doc.object());
            if (res.success) {
                emit deviceBatteryTempsFetched(stationId, res.readings);
            }
        });
    }
}

void DeyeApiClient::fetchStationAlerts(qint64 stationId, qint64 startTimeSec, qint64 endTimeSec, int page, int size)
{
    if (m_baseUrl.isEmpty() || m_accessToken.isEmpty()) {
        return;
    }

    const QUrl url(m_baseUrl + QStringLiteral("/v1.0/station/alertList"));
    QJsonObject bodyObj;
    bodyObj.insert(QStringLiteral("stationId"), stationId);
    bodyObj.insert(QStringLiteral("startTime"), startTimeSec);
    bodyObj.insert(QStringLiteral("endTime"), endTimeSec);
    bodyObj.insert(QStringLiteral("page"), page);
    bodyObj.insert(QStringLiteral("size"), size);

    QNetworkReply *reply = m_network.post(buildRequest(url, true), QJsonDocument(bodyObj).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [this, reply, stationId]() {
        reply->deleteLater();
        QJsonParseError parseErr{};
        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll(), &parseErr);
        if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
            return;
        }
        const AlertListResult res = AlertListResult::fromJson(doc.object());
        if (res.success) {
            emit stationAlertsFetched(stationId, res.alerts);
        }
    });
}

void DeyeApiClient::fetchStationPowerProfile(qint64 stationId, const QString &dateYmd)
{
    if (m_baseUrl.isEmpty() || m_accessToken.isEmpty()) {
        return;
    }

    const QDate d = QDate::fromString(dateYmd, QStringLiteral("yyyy-MM-dd"));
    const QString endYmd = d.isValid() ? d.addDays(1).toString(QStringLiteral("yyyy-MM-dd")) : dateYmd;

    const QUrl url(m_baseUrl + QStringLiteral("/v1.0/station/history"));
    QJsonObject bodyObj;
    bodyObj.insert(QStringLiteral("stationId"), stationId);
    bodyObj.insert(QStringLiteral("granularity"), 1);
    bodyObj.insert(QStringLiteral("startAt"), dateYmd);
    bodyObj.insert(QStringLiteral("endAt"), endYmd);

    QNetworkReply *reply = m_network.post(buildRequest(url, true), QJsonDocument(bodyObj).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [this, reply, stationId, dateYmd]() {
        reply->deleteLater();
        const QByteArray raw = reply->readAll();
        if (qEnvironmentVariableIntValue("DEYE_DEBUG_HISTORY") == 1) {
            qDebug().noquote() << "[station/history g=1]" << QString::fromUtf8(raw);
        }
        QJsonParseError parseErr{};
        const QJsonDocument doc = QJsonDocument::fromJson(raw, &parseErr);
        if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
            return;
        }
        const PowerProfileResult res = PowerProfileResult::fromJson(doc.object());
        if (res.success) {
            emit stationPowerProfileFetched(stationId, dateYmd, res.points);
        }
    });
}

void DeyeApiClient::fetchStationEnergyHistory(qint64 stationId, const QString &startDateYmd, const QString &endDateYmd, int granularity)
{
    if (m_baseUrl.isEmpty() || m_accessToken.isEmpty()) {
        return;
    }

    const QUrl url(m_baseUrl + QStringLiteral("/v1.0/station/history"));
    QJsonObject bodyObj;
    bodyObj.insert(QStringLiteral("stationId"), stationId);
    bodyObj.insert(QStringLiteral("granularity"), granularity);
    bodyObj.insert(QStringLiteral("startAt"), startDateYmd);
    bodyObj.insert(QStringLiteral("endAt"), endDateYmd);

    QNetworkReply *reply = m_network.post(buildRequest(url, true), QJsonDocument(bodyObj).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [this, reply, stationId, granularity]() {
        reply->deleteLater();
        const QByteArray raw = reply->readAll();
        if (qEnvironmentVariableIntValue("DEYE_DEBUG_HISTORY") == 1) {
            qDebug().noquote() << "[station/history g=" << granularity << "]" << QString::fromUtf8(raw);
        }
        QJsonParseError parseErr{};
        const QJsonDocument doc = QJsonDocument::fromJson(raw, &parseErr);
        if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
            return;
        }
        const EnergyHistoryResult res = EnergyHistoryResult::fromJson(doc.object(), granularity);
        if (res.success) {
            emit stationEnergyHistoryFetched(stationId, granularity, res.items);
        }
    });
}

void DeyeApiClient::fetchSystemConfig(const QString &deviceSn)
{
    if (m_baseUrl.isEmpty() || m_accessToken.isEmpty()) {
        emit requestFailed(QStringLiteral("config_system"), QStringLiteral("Not authenticated."), true);
        return;
    }

    const QUrl url(m_baseUrl + QStringLiteral("/v1.0/config/system"));
    QJsonObject bodyObj;
    bodyObj.insert(QStringLiteral("deviceSn"), deviceSn);

    QNetworkReply *reply = m_network.post(buildRequest(url, true), QJsonDocument(bodyObj).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [this, reply, deviceSn]() {
        reply->deleteLater();
        const int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        QJsonParseError parseErr{};
        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll(), &parseErr);

        if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
            emit requestFailed(QStringLiteral("config_system"),
                               QStringLiteral("Failed to load system config (%1): %2").arg(httpStatus).arg(reply->errorString()),
                               isAuthErrorCode({}, httpStatus));
            return;
        }
        const InverterSystemConfig cfg = InverterSystemConfig::fromJson(doc.object());
        if (!cfg.success) {
            emit requestFailed(QStringLiteral("config_system"),
                               cfg.message.isEmpty() ? QStringLiteral("System config error (code %1)").arg(cfg.code) : cfg.message,
                               isAuthErrorCode(cfg.code, httpStatus));
            return;
        }
        emit systemConfigFetched(deviceSn, cfg);
    });
}

void DeyeApiClient::fetchBatteryConfig(const QString &deviceSn)
{
    if (m_baseUrl.isEmpty() || m_accessToken.isEmpty()) {
        emit requestFailed(QStringLiteral("config_battery"), QStringLiteral("Not authenticated."), true);
        return;
    }

    const QUrl url(m_baseUrl + QStringLiteral("/v1.0/config/battery"));
    QJsonObject bodyObj;
    bodyObj.insert(QStringLiteral("deviceSn"), deviceSn);

    QNetworkReply *reply = m_network.post(buildRequest(url, true), QJsonDocument(bodyObj).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [this, reply, deviceSn]() {
        reply->deleteLater();
        const int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        QJsonParseError parseErr{};
        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll(), &parseErr);

        if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
            emit requestFailed(QStringLiteral("config_battery"),
                               QStringLiteral("Failed to load battery config (%1): %2").arg(httpStatus).arg(reply->errorString()),
                               isAuthErrorCode({}, httpStatus));
            return;
        }
        const InverterBatteryConfig cfg = InverterBatteryConfig::fromJson(doc.object());
        if (!cfg.success) {
            emit requestFailed(QStringLiteral("config_battery"),
                               cfg.message.isEmpty() ? QStringLiteral("Battery config error (code %1)").arg(cfg.code) : cfg.message,
                               isAuthErrorCode(cfg.code, httpStatus));
            return;
        }
        emit batteryConfigFetched(deviceSn, cfg);
    });
}

void DeyeApiClient::fetchTouConfig(const QString &deviceSn)
{
    if (m_baseUrl.isEmpty() || m_accessToken.isEmpty()) {
        emit requestFailed(QStringLiteral("config_tou"), QStringLiteral("Not authenticated."), true);
        return;
    }

    const QUrl url(m_baseUrl + QStringLiteral("/v1.0/config/tou"));
    QJsonObject bodyObj;
    bodyObj.insert(QStringLiteral("deviceSn"), deviceSn);

    QNetworkReply *reply = m_network.post(buildRequest(url, true), QJsonDocument(bodyObj).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [this, reply, deviceSn]() {
        reply->deleteLater();
        const int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        QJsonParseError parseErr{};
        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll(), &parseErr);

        if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
            emit requestFailed(QStringLiteral("config_tou"),
                               QStringLiteral("Failed to load TOU config (%1): %2").arg(httpStatus).arg(reply->errorString()),
                               isAuthErrorCode({}, httpStatus));
            return;
        }
        const InverterTouConfig cfg = InverterTouConfig::fromJson(doc.object());
        if (!cfg.success) {
            emit requestFailed(QStringLiteral("config_tou"),
                               cfg.message.isEmpty() ? QStringLiteral("TOU config error (code %1)").arg(cfg.code) : cfg.message,
                               isAuthErrorCode(cfg.code, httpStatus));
            return;
        }
        emit touConfigFetched(deviceSn, cfg);
    });
}

void DeyeApiClient::sendOrder(const QString &endpointPath, const QJsonObject &payload, const QString &description)
{
    if (m_baseUrl.isEmpty() || m_accessToken.isEmpty()) {
        emit requestFailed(QStringLiteral("order"), QStringLiteral("Not authenticated."), true);
        return;
    }

    const QUrl url(m_baseUrl + endpointPath);
    QNetworkReply *reply = m_network.post(buildRequest(url, true), QJsonDocument(payload).toJson(QJsonDocument::Compact));

    connect(reply, &QNetworkReply::finished, this, [this, reply, description]() {
        reply->deleteLater();
        const int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        QJsonParseError parseErr{};
        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll(), &parseErr);

        if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
            OrderResult err;
            err.success = false;
            err.message = QStringLiteral("Network error (%1): %2").arg(httpStatus).arg(reply->errorString());
            emit orderCompleted(description, err);
            return;
        }

        const OrderResult res = OrderResult::fromJson(doc.object());
        emit orderCompleted(description, res);
    });
}

} // namespace deye
