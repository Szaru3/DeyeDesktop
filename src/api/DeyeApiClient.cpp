#include "DeyeApiClient.h"

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

} // namespace deye
