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

    const MarkerData &m = m_markers.at(index.row());
    switch (role) {
    case MarkerIdRole:      return m.id;
    case MarkerLabelRole:   return QStringLiteral("Marker #%1").arg(m.id);
    case MarkerXRole:       return m.rect.x();
    case MarkerYRole:       return m.rect.y();
    case MarkerWidthRole:   return m.rect.width();
    case MarkerHeightRole:  return m.rect.height();
    case MarkerCornerRadiusRole: return m.cornerRadius;
    case MarkerShapeTypeRole: return m.shapeType;
    }
    return {};
}

QHash<int, QByteArray> MarkerModel::roleNames() const
{
    return {
        { MarkerIdRole,      "markerId" },
        { MarkerLabelRole,   "markerLabel" },
        { MarkerXRole,       "markerX" },
        { MarkerYRole,       "markerY" },
        { MarkerWidthRole,   "markerWidth" },
        { MarkerHeightRole,  "markerHeight" },
        { MarkerCornerRadiusRole, "markerCornerRadius" },
        { MarkerShapeTypeRole, "markerShapeType" },
    };
}

int MarkerModel::count() const
{
    return m_markers.size();
}

int MarkerModel::selectedMarkerId() const
{
    return m_selectedMarkerId;
}

void MarkerModel::setSelectedMarkerId(int id)
{
    if (m_selectedMarkerId == id)
        return;
    m_selectedMarkerId = id;
    emit selectedMarkerIdChanged();
}

int MarkerModel::indexOfId(int id) const
{
    for (int i = 0; i < m_markers.size(); ++i) {
        if (m_markers[i].id == id)
            return i;
    }
    return -1;
}

int MarkerModel::addMarker(qreal x, qreal y, qreal w, qreal h)
{
    int id = m_nextId++;
    int row = m_markers.size();
    beginInsertRows(QModelIndex(), row, row);
    m_markers.append({ id, QRectF(x, y, w, h) });
    endInsertRows();
    emit countChanged();
    return id;
}

void MarkerModel::updateMarker(int id, qreal x, qreal y, qreal w, qreal h)
{
    int row = indexOfId(id);
    if (row < 0)
        return;

    m_markers[row].rect = QRectF(x, y, w, h);
    qreal maxR = qMin(w, h) / 2.0;
    if (m_markers[row].cornerRadius > maxR)
        m_markers[row].cornerRadius = maxR;
    QModelIndex mi = createIndex(row, 0);
    emit dataChanged(mi, mi);
}

void MarkerModel::updateMarkerCornerRadius(int id, qreal radius)
{
    int row = indexOfId(id);
    if (row < 0)
        return;

    const QRectF &r = m_markers[row].rect;
    qreal maxR = qMin(r.width(), r.height()) / 2.0;
    m_markers[row].cornerRadius = qBound(0.0, radius, maxR);
    QModelIndex mi = createIndex(row, 0);
    emit dataChanged(mi, mi);
}

void MarkerModel::updateMarkerShapeType(int id, int shapeType)
{
    int row = indexOfId(id);
    if (row < 0)
        return;

    m_markers[row].shapeType = qBound(0, shapeType, 1);
    QModelIndex mi = createIndex(row, 0);
    emit dataChanged(mi, mi);
}

void MarkerModel::removeMarker(int id)
{
    int row = indexOfId(id);
    if (row < 0)
        return;

    beginRemoveRows(QModelIndex(), row, row);
    m_markers.removeAt(row);
    endRemoveRows();
    emit countChanged();

    if (m_selectedMarkerId == id)
        setSelectedMarkerId(-1);
}

void MarkerModel::clear()
{
    if (m_markers.isEmpty())
        return;

    beginResetModel();
    m_markers.clear();
    endResetModel();
    emit countChanged();

    setSelectedMarkerId(-1);
}

QVariantList MarkerModel::markersAtPoint(qreal x, qreal y) const
{
    QVariantList result;
    // Reverse order: last added (topmost in z-order) first
    for (int i = m_markers.size() - 1; i >= 0; --i) {
        if (m_markers[i].rect.contains(x, y))
            result.append(m_markers[i].id);
    }
    return result;
}

QVariantMap MarkerModel::markerInfo(int id) const
{
    int row = indexOfId(id);
    if (row < 0)
        return {};

    const MarkerData &m = m_markers[row];
    return {
        { "id",     m.id },
        { "x",      m.rect.x() },
        { "y",      m.rect.y() },
        { "width",  m.rect.width() },
        { "height", m.rect.height() },
        { "cornerRadius", m.cornerRadius },
        { "shapeType", m.shapeType },
    };
}
