#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "imagemanager.h"
#include "imageprovider.h"
#include "markermodel.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    auto *imageManager = new ImageManager(&app);
    auto *markerModel = new MarkerModel(&app);

    QQmlApplicationEngine engine;
    engine.addImageProvider("snapimage", new ImageProvider(imageManager));
    qmlRegisterSingletonInstance("snap_purify", 1, 0, "ImageManager", imageManager);
    qmlRegisterSingletonInstance("snap_purify", 1, 0, "MarkerModel", markerModel);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("snap_purify", "Main");

    return QCoreApplication::exec();
}
