#include "SettingsStore.h"

#include <algorithm>

namespace deye {

SettingsStore::SettingsStore()
    : m_settings(QStringLiteral("DeyeDesktop"), QStringLiteral("DeyeDesktop"))
{
}

SavedSettings SettingsStore::load() const
{
    SavedSettings s;
    s.regionIndex = m_settings.value(QStringLiteral("auth/regionIndex"), 0).toInt();
    s.customBaseUrl = m_settings.value(QStringLiteral("auth/customBaseUrl"), QString()).toString();
    s.appId = m_settings.value(QStringLiteral("auth/appId"), QString()).toString();
    s.loginMethod = m_settings.value(QStringLiteral("auth/loginMethod"), 0).toInt();
    s.email = m_settings.value(QStringLiteral("auth/email"), QString()).toString();
    s.countryCode = m_settings.value(QStringLiteral("auth/countryCode"), QStringLiteral("48")).toString();
    s.mobile = m_settings.value(QStringLiteral("auth/mobile"), QString()).toString();
    s.username = m_settings.value(QStringLiteral("auth/username"), QString()).toString();
    s.companyId = m_settings.value(QStringLiteral("auth/companyId"), QString()).toString();
    s.rememberMe = m_settings.value(QStringLiteral("auth/rememberMe"), true).toBool();

    if (s.rememberMe) {
        s.appSecret = m_settings.value(QStringLiteral("auth/appSecret"), QString()).toString();
        s.password = m_settings.value(QStringLiteral("auth/password"), QString()).toString();
    }

    s.lastStationId = m_settings.value(QStringLiteral("dashboard/lastStationId"), 0).toLongLong();
    s.refreshIntervalSec = 120;
    s.autoRefreshEnabled = true;
    return s;
}

void SettingsStore::saveLoginSettings(const SavedSettings &settings)
{
    m_settings.setValue(QStringLiteral("auth/regionIndex"), settings.regionIndex);
    m_settings.setValue(QStringLiteral("auth/customBaseUrl"), settings.customBaseUrl);
    m_settings.setValue(QStringLiteral("auth/appId"), settings.appId);
    m_settings.setValue(QStringLiteral("auth/loginMethod"), settings.loginMethod);
    m_settings.setValue(QStringLiteral("auth/email"), settings.email);
    m_settings.setValue(QStringLiteral("auth/countryCode"), settings.countryCode);
    m_settings.setValue(QStringLiteral("auth/mobile"), settings.mobile);
    m_settings.setValue(QStringLiteral("auth/username"), settings.username);
    m_settings.setValue(QStringLiteral("auth/companyId"), settings.companyId);
    m_settings.setValue(QStringLiteral("auth/rememberMe"), settings.rememberMe);

    if (settings.rememberMe) {
        m_settings.setValue(QStringLiteral("auth/appSecret"), settings.appSecret);
        m_settings.setValue(QStringLiteral("auth/password"), settings.password);
    } else {
        m_settings.remove(QStringLiteral("auth/appSecret"));
        m_settings.remove(QStringLiteral("auth/password"));
    }
    m_settings.sync();
}

void SettingsStore::saveLastStationId(qint64 stationId)
{
    m_settings.setValue(QStringLiteral("dashboard/lastStationId"), stationId);
    m_settings.sync();
}

void SettingsStore::saveRefreshSettings(bool autoRefreshEnabled, int intervalSec)
{
    m_settings.setValue(QStringLiteral("dashboard/autoRefreshEnabled"), autoRefreshEnabled);
    m_settings.setValue(QStringLiteral("dashboard/refreshIntervalSec"), std::clamp(intervalSec, 15, 3600));
    m_settings.sync();
}

} // namespace deye
