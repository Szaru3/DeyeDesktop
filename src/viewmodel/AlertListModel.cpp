#include "AlertListModel.h"

#include <QDateTime>
#include <algorithm>

namespace deye {

AlertListModel::AlertListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int AlertListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return static_cast<int>(m_alerts.size());
}

QVariant AlertListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_alerts.size()) {
        return {};
    }

    const AlertInfo &a = m_alerts.at(index.row());
    switch (role) {
    case AlertIdRole:
        return a.alertId;
    case DeviceSnRole:
        return a.deviceSn;
    case DeviceTypeRole:
        return a.deviceType;
    case AlertCodeRole:
        return a.alertCode;
    case Qt::DisplayRole:
    case AlertMessageRole:
        return a.alertMessage;
    case LevelRole:
        return a.level;
    case IsActiveRole:
        return a.isActive;
    case StartTimeTextRole:
        return a.startTime > 0
            ? QDateTime::fromSecsSinceEpoch(a.startTime).toString(QStringLiteral("yyyy-MM-dd HH:mm"))
            : QStringLiteral("—");
    case EndTimeTextRole:
        return a.endTime > 0
            ? QDateTime::fromSecsSinceEpoch(a.endTime).toString(QStringLiteral("yyyy-MM-dd HH:mm"))
            : QStringLiteral("Active");
    default:
        return {};
    }
}

QHash<int, QByteArray> AlertListModel::roleNames() const
{
    return {
        {AlertIdRole, "alertId"},
        {DeviceSnRole, "deviceSn"},
        {DeviceTypeRole, "deviceType"},
        {AlertCodeRole, "alertCode"},
        {AlertMessageRole, "alertMessage"},
        {LevelRole, "level"},
        {IsActiveRole, "isActive"},
        {StartTimeTextRole, "startTimeText"},
        {EndTimeTextRole, "endTimeText"}
    };
}

void AlertListModel::setAlerts(const QVector<AlertInfo> &alerts)
{
    beginResetModel();
    m_alerts = alerts;
    // Active alerts first, then newest first
    std::sort(m_alerts.begin(), m_alerts.end(), [](const AlertInfo &a, const AlertInfo &b) {
        if (a.isActive != b.isActive) {
            return a.isActive > b.isActive;
        }
        return a.startTime > b.startTime;
    });
    endResetModel();
}

void AlertListModel::clear()
{
    beginResetModel();
    m_alerts.clear();
    endResetModel();
}

int AlertListModel::activeCount() const
{
    int count = 0;
    for (const AlertInfo &a : m_alerts) {
        if (a.isActive) ++count;
    }
    return count;
}

} // namespace deye
