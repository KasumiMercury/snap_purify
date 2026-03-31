#include "imagemanager.h"

#include <QFileInfo>
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

    bool wasEmpty = m_image.isNull();
    m_image = newImage;
    m_fileName = QFileInfo(localPath).fileName();
    m_revision++;

    emit imageChanged();
    emit revisionChanged();
    if (wasEmpty) {
        emit hasImageChanged();
    }

    return true;
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
