#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlEngine>
#include <QDebug>
#include <QDir>

#include "appmanager.h"

int main(int argc, char *argv[])
{
	QGuiApplication app(argc, argv);

	QCoreApplication::setOrganizationName("ZetaChrome");
	QCoreApplication::setApplicationName("BioWatch");

	AppManager appManager;
	QQmlApplicationEngine engine;
	engine.rootContext()->setContextProperty("appManager", &appManager);
	engine.loadFromModule("BWApp", "Main");

	QObject::connect(
		&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
		[]() {
			qCritical() << "QML object creation FAILED";
			QCoreApplication::exit(-1);
		},
		Qt::QueuedConnection);

	QObject::connect(&engine, &QQmlApplicationEngine::warnings,
					 [](const QList<QQmlError> &warnings) {
						 for (const QQmlError &w : warnings)
							 qCritical() << "QML WARNING:" << w.toString();
					 });

	return app.exec();
}
