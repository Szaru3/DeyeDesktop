#pragma once

#include "api/DeyeModels.h"

#include <QAbstractListModel>
#include <QVector>

namespace deye {

class StationListModel : public QAbstractListModel {
    Q_OBJECT

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        LocationRole,
        CapacityRole,
        StatusRole,
        GenerationPowerRole,
        BatterySocRole
    };

    explicit StationListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setStations(const QVector<StationInfo> &stations);
    void clear();

    [[nodiscard]] const QVector<StationInfo> &stations() const { return m_stations; }
    [[nodiscard]] int indexOfStationId(qint64 stationId) const;
    [[nodiscard]] const StationInfo *stationAt(int index) const;

private:
    QVector<StationInfo> m_stations;
};

} // namespace deye
