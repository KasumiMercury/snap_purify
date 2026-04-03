#ifndef IMAGEPROCESSOR_H
#define IMAGEPROCESSOR_H

#include <QFileInfo>
#include <QImage>
#include <QObject>
#include <QPainterPath>
#include <QTimer>
#include <QUrl>
#include <QtQml/qqml.h>
#include "markermodel.h"

class ImageManager;

class ImageProcessor : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool previewEnabled READ previewEnabled WRITE setPreviewEnabled NOTIFY previewEnabledChanged)
    Q_PROPERTY(int previewRevision READ previewRevision NOTIFY previewRevisionChanged)

public:
    explicit ImageProcessor(ImageManager *imgMgr, MarkerModel *markerModel, QObject *parent = nullptr);

    bool previewEnabled() const;
    void setPreviewEnabled(bool enabled);
    int previewRevision() const;

    QImage currentPreviewImage() const;

    static QImage applyMarkers(const QImage &source, const QVector<MarkerData> &markers);

    Q_INVOKABLE bool exportImage(const QUrl &fileUrl);

signals:
    void previewEnabledChanged();
    void previewRevisionChanged();
    void exportFinished(bool success, const QString &filePath);

private slots:
    void scheduleRegenerate();
    void regenerate();

private:
    static QPainterPath shapePath(const MarkerData &marker);
    static void applyCrop(QImage &image, const QVector<MarkerData> &markers);
    static void applyCutout(QImage &image, const QVector<MarkerData> &markers);
    static void applyFill(QImage &image, const MarkerData &marker);
    static void applyMosaic(QImage &image, const MarkerData &marker, int blockSize);

    ImageManager *m_imageManager;
    MarkerModel  *m_markerModel;
    bool   m_previewEnabled = false;
    int    m_previewRevision = 0;
    QImage m_previewImage;
    QTimer m_regenTimer;
};

#endif // IMAGEPROCESSOR_H
