#include "StationListModel.h"

namespace deye {

StationListModel::StationListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int StationListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return static_cast<int>(m_stations.size());
}

QVariant StationListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_stations.size()) {
        return {};
    }

    const StationInfo &st = m_stations.at(index.row());
    switch (role) {
    case Qt::DisplayRole:
    case NameRole:
        return st.name;
    case IdRole:
        return st.id;
    case LocationRole:
        return st.locationAddress;
    case CapacityRole:
        return st.installedCapacityKw;
    case StatusRole:
        return st.connectionStatus;
    case GenerationPowerRole:
        return st.generationPowerW;
    case BatterySocRole:
        return st.batterySoc;
    default:
        return {};
    }
}

QHash<int, QByteArray> StationListModel::roleNames() const
{
    return {
        {IdRole, "stationId"},
        {NameRole, "name"},
        {LocationRole, "location"},
        {CapacityRole, "installedCapacityKw"},
        {StatusRole, "connectionStatus"},
        {GenerationPowerRole, "generationPowerW"},
        {BatterySocRole, "batterySoc"}
    };
}

void StationListModel::setStations(const QVector<StationInfo> &stations)
{
    beginResetModel();
    m_stations = stations;
    endResetModel();
}

void StationListModel::clear()
{
    beginResetModel();
    m_stations.clear();
    endResetModel();
}

int StationListModel::indexOfStationId(qint64 stationId) const
{
    for (int i = 0; i < m_stations.size(); ++i) {
        if (m_stations.at(i).id == stationId) {
            return i;
        }
    }
    return -1;
}

const StationInfo *StationListModel::stationAt(int index) const
{
    if (index < 0 || index >= m_stations.size()) {
        return nullptr;
    }
    return &m_stations.at(index);
}

} // namespace deye
