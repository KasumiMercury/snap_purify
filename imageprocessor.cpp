#include "imageprocessor.h"
#include "imagemanager.h"

#include <QPainter>
#include <algorithm>

static constexpr int kMosaicBlockSize = 16;

ImageProcessor::ImageProcessor(ImageManager *imgMgr, MarkerModel *markerModel, QObject *parent)
    : QObject(parent)
    , m_imageManager(imgMgr)
    , m_markerModel(markerModel)
{
    m_regenTimer.setSingleShot(true);
    m_regenTimer.setInterval(40);
    connect(&m_regenTimer, &QTimer::timeout, this, &ImageProcessor::regenerate);

    connect(m_markerModel, &QAbstractItemModel::dataChanged, this, &ImageProcessor::scheduleRegenerate);
    connect(m_markerModel, &QAbstractItemModel::rowsInserted, this, &ImageProcessor::scheduleRegenerate);
    connect(m_markerModel, &QAbstractItemModel::rowsRemoved, this, &ImageProcessor::scheduleRegenerate);
    connect(m_markerModel, &QAbstractItemModel::modelReset, this, &ImageProcessor::scheduleRegenerate);
    connect(m_imageManager, &ImageManager::imageChanged, this, &ImageProcessor::scheduleRegenerate);
}

bool ImageProcessor::previewEnabled() const
{
    return m_previewEnabled;
}

void ImageProcessor::setPreviewEnabled(bool enabled)
{
    if (m_previewEnabled == enabled)
        return;
    m_previewEnabled = enabled;
    emit previewEnabledChanged();

    if (enabled) {
        regenerate();
    } else {
        m_previewImage = QImage();
        m_previewRevision++;
        emit previewRevisionChanged();
    }
}

int ImageProcessor::previewRevision() const
{
    return m_previewRevision;
}

QImage ImageProcessor::currentPreviewImage() const
{
    return m_previewImage;
}

void ImageProcessor::scheduleRegenerate()
{
    if (m_previewEnabled)
        m_regenTimer.start();
}

void ImageProcessor::regenerate()
{
    m_previewImage = applyMarkers(m_imageManager->currentImage(), m_markerModel->markers());
    m_previewRevision++;
    emit previewRevisionChanged();
}

// --- Static reusable processing ---

QPainterPath ImageProcessor::shapePath(const MarkerData &marker)
{
    QPainterPath path;
    if (marker.shapeType == 1) {
        path.addEllipse(marker.rect);
    } else {
        if (marker.cornerRadius > 0) {
            path.addRoundedRect(marker.rect, marker.cornerRadius, marker.cornerRadius);
        } else {
            path.addRect(marker.rect);
        }
    }
    return path;
}

QImage ImageProcessor::applyMarkers(const QImage &source, const QVector<MarkerData> &markers)
{
    if (source.isNull() || markers.isEmpty())
        return source;

    QImage result = source.convertToFormat(QImage::Format_ARGB32_Premultiplied);

    // 1. Crop: make everything outside crop markers transparent
    applyCrop(result, markers);

    // 2. Cutout: make everything inside cutout markers transparent
    applyCutout(result, markers);

    // 3. Fill
    for (const MarkerData &m : markers) {
        if (m.mode == 0)
            applyFill(result, m);
    }

    // 4. Mosaic
    for (const MarkerData &m : markers) {
        if (m.mode == 1)
            applyMosaic(result, m, kMosaicBlockSize);
    }

    return result;
}

void ImageProcessor::applyCrop(QImage &image, const QVector<MarkerData> &markers)
{
    QPainterPath cropUnion;
    bool hasCrop = false;
    for (const MarkerData &m : markers) {
        if (m.mode == 2) {
            cropUnion = cropUnion.united(shapePath(m));
            hasCrop = true;
        }
    }
    if (!hasCrop)
        return;

    QPainterPath fullRect;
    fullRect.addRect(QRectF(0, 0, image.width(), image.height()));
    QPainterPath outside = fullRect.subtracted(cropUnion);

    QPainter painter(&image);
    painter.setCompositionMode(QPainter::CompositionMode_Source);
    painter.fillPath(outside, Qt::transparent);
}

void ImageProcessor::applyCutout(QImage &image, const QVector<MarkerData> &markers)
{
    QPainterPath cutoutUnion;
    bool hasCutout = false;
    for (const MarkerData &m : markers) {
        if (m.mode == 3) {
            cutoutUnion = cutoutUnion.united(shapePath(m));
            hasCutout = true;
        }
    }
    if (!hasCutout)
        return;

    QPainter painter(&image);
    painter.setCompositionMode(QPainter::CompositionMode_Source);
    painter.fillPath(cutoutUnion, Qt::transparent);
}

bool ImageProcessor::exportImage(const QUrl &fileUrl)
{
    QString filePath = fileUrl.toLocalFile();
    if (filePath.isEmpty())
        return false;

    QImage processed = applyMarkers(m_imageManager->currentImage(),
                                     m_markerModel->markers());
    if (processed.isNull()) {
        emit exportFinished(false, filePath);
        return false;
    }

    QString ext = QFileInfo(filePath).suffix().toLower();

    // For formats without transparency support, composite onto black background
    if (ext == "jpg" || ext == "jpeg" || ext == "bmp") {
        QImage opaque(processed.size(), QImage::Format_RGB32);
        opaque.fill(Qt::black);
        QPainter painter(&opaque);
        painter.drawImage(0, 0, processed);
        painter.end();
        processed = opaque;
    }

    bool ok = processed.save(filePath);
    emit exportFinished(ok, filePath);
    return ok;
}

void ImageProcessor::applyFill(QImage &image, const MarkerData &marker)
{
    QPainter painter(&image);
    painter.setRenderHint(QPainter::Antialiasing, true);
    painter.setClipPath(shapePath(marker));
    painter.fillRect(marker.rect.toAlignedRect(), Qt::black);
}

void ImageProcessor::applyMosaic(QImage &image, const MarkerData &marker, int blockSize)
{
    QRect boundingRect = marker.rect.toAlignedRect().intersected(image.rect());
    if (boundingRect.isEmpty())
        return;

    QImage region = image.copy(boundingRect);

    int smallW = std::max(1, boundingRect.width() / blockSize);
    int smallH = std::max(1, boundingRect.height() / blockSize);
    QImage small = region.scaled(smallW, smallH, Qt::IgnoreAspectRatio, Qt::FastTransformation);
    QImage pixelated = small.scaled(boundingRect.size(), Qt::IgnoreAspectRatio, Qt::FastTransformation);

    QPainterPath clipPath = shapePath(marker).translated(-boundingRect.x(), -boundingRect.y());

    QPainter painter(&image);
    painter.setRenderHint(QPainter::Antialiasing, true);
    painter.setClipPath(shapePath(marker));
    painter.drawImage(boundingRect.topLeft(), pixelated);
}
