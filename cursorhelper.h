#ifndef CURSORHELPER_H
#define CURSORHELPER_H

#include <QCursor>
#include <QObject>
#include <QPoint>

class CursorHelper : public QObject
{
    Q_OBJECT

public:
    explicit CursorHelper(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE QPoint globalPos() const { return QCursor::pos(); }
};

#endif // CURSORHELPER_H
