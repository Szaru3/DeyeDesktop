#pragma once

#include "api/DeyeModels.h"

#include <QMap>
#include <QSettings>
#include <QString>

namespace deye {

struct SavedSettings {
    int regionIndex = 0;
    QString customBaseUrl;
    QString appId;
    QString appSecret;
    int loginMethod = 0; // 0=Email, 1=Phone, 2=Username
    QString email;
    QString countryCode = QStringLiteral("48");
    QString mobile;
    QString username;
    QString companyId;
    QString password;
    bool rememberMe = true;
    qint64 lastStationId = 0;
    int refreshIntervalSec = 120;
    bool autoRefreshEnabled = true;
    QString language = QStringLiteral("en");
};

class SettingsStore {
public:
    SettingsStore();

    [[nodiscard]] SavedSettings load() const;
    void saveLoginSettings(const SavedSettings &settings);
    void saveLastStationId(qint64 stationId);
    void saveRefreshSettings(bool autoRefreshEnabled, int intervalSec);
    void saveLanguage(const QString &lang);

    [[nodiscard]] QMap<QString, QString> loadCustomDeviceNames() const;
    void saveCustomDeviceName(const QString &deviceSn, const QString &customName);

private:
    QSettings m_settings;
};

} // namespace deye
