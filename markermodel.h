#ifndef MARKERMODEL_H
#define MARKERMODEL_H

#include <QAbstractListModel>
#include <QRectF>
#include <QVector>
#include <QtQml/qqml.h>

class MarkerModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum MarkerRoles {
        MarkerXRole = Qt::UserRole + 1,
        MarkerYRole,
        MarkerWidthRole,
        MarkerHeightRole,
    };

    explicit MarkerModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const;

    Q_INVOKABLE int addMarker(qreal x, qreal y, qreal w, qreal h);
    Q_INVOKABLE void updateMarker(int index, qreal x, qreal y, qreal w, qreal h);
    Q_INVOKABLE void removeMarker(int index);
    Q_INVOKABLE void clear();

signals:
    void countChanged();

private:
    QVector<QRectF> m_markers;
};

#endif // MARKERMODEL_H
