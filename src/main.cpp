#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDebug>
#include <QDir>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    QObject::connect(
    &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
    []()
    {
        qCritical() << "QML object creation FAILED";
        QCoreApplication::exit(-1);
    },
    Qt::QueuedConnection);

    QObject::connect(&engine, &QQmlApplicationEngine::warnings,
                     [](const QList<QQmlError> &warnings)
                     {
                         for (const QQmlError &w : warnings)
                             qCritical() << "QML WARNING:" << w.toString();
                     });

    engine.loadFromModule("BWApp", "Main");

    return app.exec();
}
