#include "imagemanager.h"

#include <QClipboard>
#include <QFileInfo>
#include <QGuiApplication>
#include <QMimeData>
#include <QSet>

static const QSet<QString> s_acceptedExtensions = {
    "png", "jpg", "jpeg", "bmp", "gif", "webp", "tiff", "tif", "svg"
};

ImageManager::ImageManager(QObject *parent)
    : QObject(parent)
{
}

bool ImageManager::hasImage() const
{
    return !m_image.isNull();
}

int ImageManager::revision() const
{
    return m_revision;
}

int ImageManager::imageWidth() const
{
    return m_image.width();
}

int ImageManager::imageHeight() const
{
    return m_image.height();
}

QString ImageManager::fileName() const
{
    return m_fileName;
}

QImage ImageManager::currentImage() const
{
    return m_image;
}

bool ImageManager::loadFromFile(const QString &path)
{
    QString localPath = path;
    if (localPath.startsWith("file:///")) {
        localPath = QUrl(localPath).toLocalFile();
    }

    QImage newImage;
    if (!newImage.load(localPath)) {
        return false;
    }

    setImage(newImage, QFileInfo(localPath).fileName());
    return true;
}

bool ImageManager::loadFromClipboard()
{
    const QClipboard *clipboard = QGuiApplication::clipboard();
    const QMimeData *mimeData = clipboard->mimeData();

    if (mimeData->hasImage()) {
        QImage image = qvariant_cast<QImage>(mimeData->imageData());
        if (!image.isNull()) {
            setImage(image, QStringLiteral("clipboard"));
            return true;
        }
    }

    if (mimeData->hasUrls()) {
        for (const QUrl &url : mimeData->urls()) {
            if (url.isLocalFile() && isAcceptedFormat(url.toLocalFile())) {
                return loadFromFile(url.toLocalFile());
            }
        }
    }

    return false;
}

void ImageManager::setImage(const QImage &image, const QString &fileName)
{
    bool wasEmpty = m_image.isNull();
    m_image = image;
    m_fileName = fileName;
    m_revision++;

    emit imageChanged();
    emit revisionChanged();
    if (wasEmpty) {
        emit hasImageChanged();
    }
}

bool ImageManager::isAcceptedFormat(const QString &path) const
{
    QString localPath = path;
    if (localPath.startsWith("file:///")) {
        localPath = QUrl(localPath).toLocalFile();
    }
    QString suffix = QFileInfo(localPath).suffix().toLower();
    return s_acceptedExtensions.contains(suffix);
}
