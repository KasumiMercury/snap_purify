#ifndef MARKERMODEL_H
#define MARKERMODEL_H

#include <QAbstractListModel>
#include <QRectF>
#include <QVector>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqml.h>

struct MarkerData {
    int id;
    QRectF rect;
    qreal cornerRadius = 0.0;
    int shapeType = 0; // 0 = rectangle, 1 = ellipse
    int mode = 0;      // 0 = fill, 1 = mosaic, 2 = crop, 3 = cutout
};

class MarkerModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int selectedMarkerId READ selectedMarkerId WRITE setSelectedMarkerId NOTIFY selectedMarkerIdChanged)

public:
    enum MarkerRoles {
        MarkerIdRole = Qt::UserRole + 1,
        MarkerLabelRole,
        MarkerXRole,
        MarkerYRole,
        MarkerWidthRole,
        MarkerHeightRole,
        MarkerCornerRadiusRole,
        MarkerShapeTypeRole,
        MarkerModeRole,
    };

    explicit MarkerModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const;

    int selectedMarkerId() const;
    void setSelectedMarkerId(int id);

    Q_INVOKABLE int addMarker(qreal x, qreal y, qreal w, qreal h);
    Q_INVOKABLE void updateMarker(int id, qreal x, qreal y, qreal w, qreal h);
    Q_INVOKABLE void updateMarkerCornerRadius(int id, qreal radius);
    Q_INVOKABLE void updateMarkerShapeType(int id, int shapeType);
    Q_INVOKABLE void updateMarkerMode(int id, int mode);
    Q_INVOKABLE void removeMarker(int id);
    Q_INVOKABLE void clear();

    Q_INVOKABLE QVariantList markersAtPoint(qreal x, qreal y) const;
    Q_INVOKABLE QVariantMap markerInfo(int id) const;

    const QVector<MarkerData>& markers() const;

signals:
    void countChanged();
    void selectedMarkerIdChanged();

private:
    int indexOfId(int id) const;

    QVector<MarkerData> m_markers;
    int m_nextId = 1;
    int m_selectedMarkerId = -1;
};

#endif // MARKERMODEL_H
