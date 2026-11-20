#include "DeviceListModel.h"

#include <QDateTime>

namespace deye {

DeviceListModel::DeviceListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int DeviceListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return static_cast<int>(m_devices.size());
}

QVariant DeviceListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_devices.size()) {
        return {};
    }

    const DeviceInfo &dev = m_devices.at(index.row());
    switch (role) {
    case Qt::DisplayRole:
    case DeviceNameRole:
        return dev.deviceName;
    case DeviceIdRole:
        return dev.deviceId;
    case DeviceSnRole:
        return dev.deviceSn;
    case DeviceTypeRole:
        return dev.deviceType;
    case ProductIdRole:
        return dev.productId;
    case ConnectionStatusRole:
        return dev.connectionStatus;
    case LastSeenTextRole:
        if (dev.collectionTime > 0) {
            return QDateTime::fromSecsSinceEpoch(dev.collectionTime).toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));
        }
        return QStringLiteral("—");
    default:
        return {};
    }
}

QHash<int, QByteArray> DeviceListModel::roleNames() const
{
    return {
        {DeviceIdRole, "deviceId"},
        {DeviceSnRole, "deviceSn"},
        {DeviceNameRole, "deviceName"},
        {DeviceTypeRole, "deviceType"},
        {ProductIdRole, "productId"},
        {ConnectionStatusRole, "connectionStatus"},
        {LastSeenTextRole, "lastSeenText"}
    };
}

void DeviceListModel::setDevices(const QVector<DeviceInfo> &devices)
{
    beginResetModel();
    m_devices = devices;
    endResetModel();
}

void DeviceListModel::clear()
{
    beginResetModel();
    m_devices.clear();
    endResetModel();
}

} // namespace deye
