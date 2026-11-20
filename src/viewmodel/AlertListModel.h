#pragma once

#include "api/DeyeModels.h"

#include <QAbstractListModel>
#include <QVector>

namespace deye {

class AlertListModel : public QAbstractListModel {
    Q_OBJECT

public:
    enum Roles {
        AlertIdRole = Qt::UserRole + 1,
        DeviceSnRole,
        DeviceTypeRole,
        AlertCodeRole,
        AlertMessageRole,
        LevelRole,
        IsActiveRole,
        StartTimeTextRole,
        EndTimeTextRole
    };

    explicit AlertListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setAlerts(const QVector<AlertInfo> &alerts);
    void clear();
    [[nodiscard]] int activeCount() const;

private:
    QVector<AlertInfo> m_alerts;
};

} // namespace deye
