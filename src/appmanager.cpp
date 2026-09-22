#include "appmanager.h"
#include "blemanager.h"

#include <QSettings>
#include <QStandardPaths>
#include <QDir>

AppManager::AppManager(QObject *parent)
	: QObject(parent)
{
	const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
	QDir().mkpath(dataDir);

	m_repository = std::make_unique<Repository>(dataDir + "/biowatch.sqlite", this);
	m_ble = std::make_unique<BleManager>(m_repository.get(), this);

	connect(m_ble.get(), &BleManager::deviceInfoUpdated, this, &AppManager::onDeviceInfoUpdated);

	loadSettings();
}

AppManager::~AppManager() = default;

void AppManager::onDeviceInfoUpdated(const QString &manufacturer, const QString &firmwareVersion)
{
	Q_UNUSED(manufacturer); // surfaced as a static value in Settings.qml today
	if (!firmwareVersion.isEmpty() && firmwareVersion != m_firmwareVersion) {
		m_firmwareVersion = firmwareVersion;
		emit firmwareVersionChanged();
	}
}

void AppManager::setHeightCm(int cm)
{
	if (cm == m_heightCm)
		return;
	m_heightCm = cm;
	emit heightCmChanged();
	saveSettings();
	if (m_ble)
		m_ble->writeHeightCm(cm);
}

void AppManager::setWeightKg(int kg)
{
	if (kg == m_weightKg)
		return;
	m_weightKg = kg;
	emit weightKgChanged();
	saveSettings();
	if (m_ble)
		m_ble->writeWeightKg(static_cast<double>(kg));
}

void AppManager::loadSettings()
{
	QSettings s;
	m_heightCm = s.value("profile/heightCm", m_heightCm).toInt();
	m_weightKg = s.value("profile/weightKg", m_weightKg).toInt();
}

void AppManager::saveSettings()
{
	QSettings s;
	s.setValue("profile/heightCm", m_heightCm);
	s.setValue("profile/weightKg", m_weightKg);
}
