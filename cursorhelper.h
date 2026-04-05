#ifndef CURSORHELPER_H
#define CURSORHELPER_H

#include <QCursor>
#include <QObject>
#include <QPoint>
#include <QQmlEngine>

class CursorHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit CursorHelper(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE QPoint globalPos() const { return QCursor::pos(); }
};

#endif // CURSORHELPER_H
