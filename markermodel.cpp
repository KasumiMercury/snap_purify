#include "markermodel.h"

MarkerModel::MarkerModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int MarkerModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_markers.size();
}

QVariant MarkerModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_markers.size())
        return {};

    const QRectF &rect = m_markers.at(index.row());
    switch (role) {
    case MarkerXRole:      return rect.x();
    case MarkerYRole:      return rect.y();
    case MarkerWidthRole:  return rect.width();
    case MarkerHeightRole: return rect.height();
    }
    return {};
}

QHash<int, QByteArray> MarkerModel::roleNames() const
{
    return {
        { MarkerXRole,      "markerX" },
        { MarkerYRole,      "markerY" },
        { MarkerWidthRole,  "markerWidth" },
        { MarkerHeightRole, "markerHeight" },
    };
}

int MarkerModel::count() const
{
    return m_markers.size();
}

int MarkerModel::addMarker(qreal x, qreal y, qreal w, qreal h)
{
    int row = m_markers.size();
    beginInsertRows(QModelIndex(), row, row);
    m_markers.append(QRectF(x, y, w, h));
    endInsertRows();
    emit countChanged();
    return row;
}

void MarkerModel::updateMarker(int index, qreal x, qreal y, qreal w, qreal h)
{
    if (index < 0 || index >= m_markers.size())
        return;

    m_markers[index] = QRectF(x, y, w, h);
    QModelIndex mi = createIndex(index, 0);
    emit dataChanged(mi, mi);
}

void MarkerModel::removeMarker(int index)
{
    if (index < 0 || index >= m_markers.size())
        return;

    beginRemoveRows(QModelIndex(), index, index);
    m_markers.removeAt(index);
    endRemoveRows();
    emit countChanged();
}

void MarkerModel::clear()
{
    if (m_markers.isEmpty())
        return;

    beginResetModel();
    m_markers.clear();
    endResetModel();
    emit countChanged();
}
