#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "imagemanager.h"
#include "imageprovider.h"
#include "imageprocessor.h"
#include "previewprovider.h"
#include "markermodel.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    auto *imageManager = new ImageManager(&app);
    auto *markerModel = new MarkerModel(&app);
    auto *imageProcessor = new ImageProcessor(imageManager, markerModel, &app);

    QQmlApplicationEngine engine;
    engine.addImageProvider("snapimage", new ImageProvider(imageManager));
    engine.addImageProvider("snappreview", new PreviewProvider(imageProcessor));
    qmlRegisterSingletonInstance("snap_purify", 1, 0, "ImageManager", imageManager);
    qmlRegisterSingletonInstance("snap_purify", 1, 0, "MarkerModel", markerModel);
    qmlRegisterSingletonInstance("snap_purify", 1, 0, "ImageProcessor", imageProcessor);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("snap_purify", "Main");

    return QCoreApplication::exec();
}
