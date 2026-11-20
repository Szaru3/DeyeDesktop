#pragma once

#include "api/DeyeModels.h"

#include <QAbstractListModel>
#include <QMap>
#include <QVector>

namespace deye {

class DeviceListModel : public QAbstractListModel {
    Q_OBJECT

public:
    enum Roles {
        DeviceIdRole = Qt::UserRole + 1,
        DeviceSnRole,
        DeviceNameRole,
        OriginalNameRole,
        DeviceTypeRole,
        ProductIdRole,
        ConnectionStatusRole,
        LastSeenTextRole
    };

    explicit DeviceListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setDevices(const QVector<DeviceInfo> &devices);
    void setCustomNames(const QMap<QString, QString> &customNames);
    void setCustomNameForDevice(const QString &deviceSn, const QString &customName);
    void clear();

private:
    QVector<DeviceInfo> m_devices;
    QMap<QString, QString> m_customNames;
};

} // namespace deye
