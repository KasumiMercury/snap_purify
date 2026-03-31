#ifndef IMAGEMANAGER_H
#define IMAGEMANAGER_H

#include <QImage>
#include <QObject>
#include <QString>
#include <QUrl>
#include <QtQml/qqml.h>

class ImageManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool hasImage READ hasImage NOTIFY hasImageChanged)
    Q_PROPERTY(int revision READ revision NOTIFY revisionChanged)
    Q_PROPERTY(int imageWidth READ imageWidth NOTIFY imageChanged)
    Q_PROPERTY(int imageHeight READ imageHeight NOTIFY imageChanged)
    Q_PROPERTY(QString fileName READ fileName NOTIFY imageChanged)

public:
    explicit ImageManager(QObject *parent = nullptr);

    bool hasImage() const;
    int revision() const;
    int imageWidth() const;
    int imageHeight() const;
    QString fileName() const;

    QImage currentImage() const;

    Q_INVOKABLE bool loadFromFile(const QString &path);
    Q_INVOKABLE bool isAcceptedFormat(const QString &path) const;

signals:
    void hasImageChanged();
    void revisionChanged();
    void imageChanged();

private:
    QImage m_image;
    int m_revision = 0;
    QString m_fileName;
};

#endif // IMAGEMANAGER_H
