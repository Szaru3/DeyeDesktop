#pragma once

#include "DeyeModels.h"

#include <QNetworkAccessManager>
#include <QObject>
#include <QString>

namespace deye {

class DeyeApiClient : public QObject {
    Q_OBJECT

public:
    explicit DeyeApiClient(QObject *parent = nullptr);

    void setBaseUrl(const QString &baseUrl);
    void setAccessToken(const QString &token);
    void clearSession();

    [[nodiscard]] QString baseUrl() const { return m_baseUrl; }
    [[nodiscard]] QString accessToken() const { return m_accessToken; }
    [[nodiscard]] bool hasToken() const { return !m_accessToken.isEmpty(); }

    void authenticate(const DeyeCredentials &credentials);
    void fetchStations(int page = 1, int size = 50);
    void fetchStationLatest(qint64 stationId);
    void fetchStationDevices(qint64 stationId, int page = 1, int size = 50);

    // Inverter Configuration Readers
    void fetchSystemConfig(const QString &deviceSn);
    void fetchBatteryConfig(const QString &deviceSn);
    void fetchTouConfig(const QString &deviceSn);

    // Inverter Control / Order Writers
    void sendOrder(const QString &endpointPath, const QJsonObject &payload, const QString &description);

signals:
    void authenticated(const deye::DeyeAuthResult &result);
    void stationsFetched(const QVector<deye::StationInfo> &stations);
    void stationLatestFetched(qint64 stationId, const deye::StationLatestData &data);
    void stationDevicesFetched(qint64 stationId, const QVector<deye::DeviceInfo> &devices);
    void systemConfigFetched(const QString &deviceSn, const deye::InverterSystemConfig &config);
    void batteryConfigFetched(const QString &deviceSn, const deye::InverterBatteryConfig &config);
    void touConfigFetched(const QString &deviceSn, const deye::InverterTouConfig &config);
    void orderCompleted(const QString &description, const deye::OrderResult &result);
    void requestFailed(const QString &context, const QString &errorMessage, bool authExpired);

private:
    QNetworkRequest buildRequest(const QUrl &url, bool includeAuth) const;
    static bool isAuthErrorCode(const QString &code, int httpStatus);

    QNetworkAccessManager m_network;
    QString m_baseUrl;
    QString m_accessToken;
};

} // namespace deye
