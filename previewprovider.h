#ifndef PREVIEWPROVIDER_H
#define PREVIEWPROVIDER_H

#include <QQuickImageProvider>
#include "imageprocessor.h"

class PreviewProvider : public QQuickImageProvider
{
public:
    explicit PreviewProvider(ImageProcessor *processor)
        : QQuickImageProvider(QQuickImageProvider::Image)
        , m_processor(processor)
    {
    }

    QImage requestImage(const QString &id, QSize *size,
                        const QSize &requestedSize) override
    {
        Q_UNUSED(id)

        QImage image = m_processor->currentPreviewImage();
        if (image.isNull())
            return {};

        if (size)
            *size = image.size();

        if (requestedSize.isValid())
            return image.scaled(requestedSize, Qt::KeepAspectRatio,
                                Qt::SmoothTransformation);

        return image;
    }

private:
    ImageProcessor *m_processor;
};

#endif // PREVIEWPROVIDER_H
