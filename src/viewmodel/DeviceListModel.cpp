#include "DeviceListModel.h"

#include <QDateTime>
#include <algorithm>

namespace deye {

namespace {

int deviceTypeSortRank(const QString &deviceType)
{
    if (deviceType == QStringLiteral("Inverter") || deviceType == QStringLiteral("Microinverter")) {
        return 0;
    }
    if (deviceType == QStringLiteral("Battery")) {
        return 1;
    }
    if (deviceType == QStringLiteral("Data Logger")) {
        return 2;
    }
    return 3;
}

} // namespace

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
    case DeviceNameRole: {
        const auto it = m_customNames.constFind(dev.deviceSn);
        if (it != m_customNames.constEnd() && !it.value().isEmpty()) {
            return it.value();
        }
        return dev.deviceName;
    }
    case OriginalNameRole:
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
        {OriginalNameRole, "originalName"},
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
    std::sort(m_devices.begin(), m_devices.end(), [](const DeviceInfo &a, const DeviceInfo &b) {
        const int rankA = deviceTypeSortRank(a.deviceType);
        const int rankB = deviceTypeSortRank(b.deviceType);
        if (rankA != rankB) {
            return rankA < rankB;
        }
        const int snCmp = QString::compare(a.deviceSn, b.deviceSn, Qt::CaseInsensitive);
        if (snCmp != 0) {
            return snCmp < 0;
        }
        return QString::compare(a.deviceName, b.deviceName, Qt::CaseInsensitive) < 0;
    });
    endResetModel();
}

void DeviceListModel::setCustomNames(const QMap<QString, QString> &customNames)
{
    m_customNames = customNames;
    if (!m_devices.isEmpty()) {
        emit dataChanged(index(0), index(static_cast<int>(m_devices.size()) - 1), {Qt::DisplayRole, DeviceNameRole});
    }
}

void DeviceListModel::setCustomNameForDevice(const QString &deviceSn, const QString &customName)
{
    const QString key = deviceSn.trimmed();
    if (key.isEmpty()) {
        return;
    }
    const QString trimmed = customName.trimmed();
    if (trimmed.isEmpty()) {
        m_customNames.remove(key);
    } else {
        m_customNames.insert(key, trimmed);
    }

    for (int i = 0; i < m_devices.size(); ++i) {
        if (m_devices.at(i).deviceSn == key) {
            emit dataChanged(index(i), index(i), {Qt::DisplayRole, DeviceNameRole});
        }
    }
}

void DeviceListModel::clear()
{
    beginResetModel();
    m_devices.clear();
    endResetModel();
}

} // namespace deye
