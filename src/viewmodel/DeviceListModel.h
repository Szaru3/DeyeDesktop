#pragma once

#include "api/DeyeModels.h"

#include <QAbstractListModel>
#include <QVector>

namespace deye {

class DeviceListModel : public QAbstractListModel {
    Q_OBJECT

public:
    enum Roles {
        DeviceIdRole = Qt::UserRole + 1,
        DeviceSnRole,
        DeviceNameRole,
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
    void clear();

private:
    QVector<DeviceInfo> m_devices;
};

} // namespace deye
