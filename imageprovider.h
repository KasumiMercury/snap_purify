#ifndef IMAGEPROVIDER_H
#define IMAGEPROVIDER_H

#include <QQuickImageProvider>
#include "imagemanager.h"

class ImageProvider : public QQuickImageProvider
{
public:
    explicit ImageProvider(ImageManager *manager)
        : QQuickImageProvider(QQuickImageProvider::Image)
        , m_manager(manager)
    {
    }

    QImage requestImage(const QString &id, QSize *size,
                        const QSize &requestedSize) override
    {
        Q_UNUSED(id)

        QImage image = m_manager->currentImage();
        if (image.isNull()) {
            return {};
        }

        if (size) {
            *size = image.size();
        }

        if (requestedSize.isValid()) {
            return image.scaled(requestedSize, Qt::KeepAspectRatio,
                                Qt::SmoothTransformation);
        }

        return image;
    }

private:
    ImageManager *m_manager;
};

#endif // IMAGEPROVIDER_H
