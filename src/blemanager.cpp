#include "blemanager.h"
#include "repository.h"
#include "bleuuids.h"

#include <QCoreApplication>
#include <QPermissions>
#include <QLowEnergyDescriptor>
#include <QDateTime>
#include <QDebug>
#include <cstring>

namespace
{

template <typename T> bool readInto(const QByteArray &bytes, T &out)
{
	if (bytes.size() != sizeof(T))
		return false;
	std::memcpy(&out, bytes.constData(), sizeof(T));
	return true;
}

} // namespace

BleManager::BleManager(Repository *repository, QObject *parent)
	: QObject(parent)
	, m_repository(repository)
{
	m_discovery = std::make_unique<QBluetoothDeviceDiscoveryAgent>(this);
	connect(m_discovery.get(), &QBluetoothDeviceDiscoveryAgent::deviceDiscovered, this,
			&BleManager::onDeviceDiscovered);
	connect(m_discovery.get(), &QBluetoothDeviceDiscoveryAgent::finished, this,
			&BleManager::onDiscoveryFinished);
	connect(m_discovery.get(), &QBluetoothDeviceDiscoveryAgent::errorOccurred, this,
			&BleManager::onDiscoveryError);
}

BleManager::~BleManager() = default;

QString BleManager::statusText() const
{
	switch (m_state) {
	case Idle:
		return QStringLiteral("Not connected");
	case Scanning:
		return QStringLiteral("Scanning for BioWatch…");
	case Connecting:
		return QStringLiteral("Connecting…");
	case Connected:
		return QStringLiteral("Connected to %1").arg(m_deviceName);
	case Error:
		return QStringLiteral("Connection error");
	}
	return {};
}

void BleManager::setState(ConnectionState s)
{
	if (m_state == s)
		return;
	m_state = s;
	emit connectionStateChanged();
}

void BleManager::cleanupServices()
{
	m_activeServices.clear();
	m_settingsService = nullptr;
}

void BleManager::scanAndConnect()
{
	if (m_state == Scanning || m_state == Connecting || m_state == Connected)
		return;

	checkPermissionsAndScan();
}

void BleManager::checkPermissionsAndScan()
{
#if QT_CONFIG(permissions)
	// Configure BLE permission in Qt 6
	QBluetoothPermission blePermission;
	blePermission.setCommunicationModes(QBluetoothPermission::Access);

	switch (qApp->checkPermission(blePermission)) {
	case Qt::PermissionStatus::Granted:
		startScanning();
		break;

	case Qt::PermissionStatus::Undetermined:
		qApp->requestPermission(blePermission, this, [this](const QPermission &permission) {
			if (permission.status() == Qt::PermissionStatus::Granted) {
				this->startScanning();
			} else {
				qWarning() << "Bluetooth permission denied by user.";
				this->setState(Error);
				this->setState(Idle);
			}
		});
		break;

	case Qt::PermissionStatus::Denied:
		qWarning() << "Bluetooth permission was previously denied.";
		setState(Error);
		setState(Idle);
		break;
	}
#else
	startScanning();
#endif
}

void BleManager::startScanning()
{
	cleanupServices();
	m_controller.reset();

	setState(Scanning);
	m_discovery->setLowEnergyDiscoveryTimeout(15000);
	m_discovery->start(QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
}

void BleManager::onDeviceDiscovered(const QBluetoothDeviceInfo &info)
{
	if (!info.name().contains(BleUuid::DeviceNameFilter, Qt::CaseInsensitive))
		return;

	m_discovery->stop();
	m_deviceName = info.name();
	emit deviceNameChanged();
	setState(Connecting);

	cleanupServices();
	m_controller.reset(QLowEnergyController::createCentral(info, this));
	connect(m_controller.get(), &QLowEnergyController::connected, this,
			&BleManager::onControllerConnected);
	connect(m_controller.get(), &QLowEnergyController::disconnected, this,
			&BleManager::onControllerDisconnected);
	connect(m_controller.get(), &QLowEnergyController::errorOccurred, this,
			&BleManager::onControllerError);
	connect(m_controller.get(), &QLowEnergyController::discoveryFinished, this,
			&BleManager::onServiceDiscoveryFinished);

	m_controller->connectToDevice();
}

void BleManager::onDiscoveryFinished()
{
	if (m_state == Scanning) {
		// Timed out without finding peripheral
		setState(Error);
		setState(Idle);
	}
}

void BleManager::onDiscoveryError(QBluetoothDeviceDiscoveryAgent::Error error)
{
	Q_UNUSED(error);
	qWarning() << "BLE discovery error:" << m_discovery->errorString();
	setState(Error);
	setState(Idle);
}

void BleManager::onControllerConnected()
{
	m_controller->discoverServices();
}

void BleManager::onControllerDisconnected()
{
	cleanupServices();
	setState(Idle);
}

void BleManager::onControllerError(QLowEnergyController::Error error)
{
	Q_UNUSED(error);
	qWarning()
		<< "BLE controller error:" << (m_controller ? m_controller->errorString() : "unknown");
	cleanupServices();
	setState(Error);
	setState(Idle);
}

void BleManager::onServiceDiscoveryFinished()
{
	if (!m_controller)
		return;

	static const QList<QBluetoothUuid> wanted = { BleUuid::ServiceDeviceInfo,
												  BleUuid::ServiceActivity, BleUuid::ServiceVitals,
												  BleUuid::ServiceEnvironment,
												  BleUuid::ServiceSettings };

	cleanupServices();

	for (const auto &uuid : m_controller->services()) {
		if (!wanted.contains(uuid))
			continue;

		// Parent service to m_controller so services are purged upon controller reset
		QLowEnergyService *service = m_controller->createServiceObject(uuid, m_controller.get());
		if (!service)
			continue;

		m_activeServices.append(service);

		connect(service, &QLowEnergyService::stateChanged, this,
				&BleManager::onServiceStateChanged);
		connect(service, &QLowEnergyService::characteristicChanged, this,
				&BleManager::onCharacteristicChanged);
		connect(service, &QLowEnergyService::characteristicRead, this,
				&BleManager::onCharacteristicRead);

		service->discoverDetails();
	}
}

void BleManager::onServiceStateChanged(QLowEnergyService::ServiceState state)
{
	auto *service = qobject_cast<QLowEnergyService *>(sender());
	if (!service || state != QLowEnergyService::RemoteServiceDiscovered)
		return;

	setupService(service);

	// Verify all required services are ready
	bool allReady = !m_activeServices.isEmpty();
	for (QLowEnergyService *s : m_activeServices) {
		if (s->state() != QLowEnergyService::RemoteServiceDiscovered) {
			allReady = false;
			break;
		}
	}

	if (allReady) {
		setState(Connected);
		syncTime();
		flushPendingSettingsWrites();
	}
}

void BleManager::setupService(QLowEnergyService *service)
{
	const auto uuid = service->serviceUuid();

	if (uuid == BleUuid::ServiceDeviceInfo) {
		for (const auto &ch : service->characteristics())
			service->readCharacteristic(ch);
	} else if (uuid == BleUuid::ServiceActivity) {
		enableNotification(service, BleUuid::CharActivityData);
	} else if (uuid == BleUuid::ServiceVitals) {
		enableNotification(service, BleUuid::CharVitalsData);
	} else if (uuid == BleUuid::ServiceEnvironment) {
		enableNotification(service, BleUuid::CharEnvironmentData);
	} else if (uuid == BleUuid::ServiceSettings) {
		m_settingsService = service;
	}
}

void BleManager::enableNotification(QLowEnergyService *service, const QBluetoothUuid &charUuid)
{
	QLowEnergyCharacteristic c = service->characteristic(charUuid);
	if (!c.isValid()) {
		qWarning() << "Characteristic not found:" << charUuid;
		return;
	}

	QLowEnergyDescriptor notifDesc =
		c.descriptor(QBluetoothUuid::DescriptorType::ClientCharacteristicConfiguration);

	if (notifDesc.isValid())
		service->writeDescriptor(notifDesc, QByteArray::fromHex("0100"));
}

void BleManager::onCharacteristicChanged(const QLowEnergyCharacteristic &c, const QByteArray &value)
{
	if (c.uuid() == BleUuid::CharActivityData) {
		act_record rec{};
		if (!readInto(value, rec))
			return;
		if (m_repository)
			m_repository->saveActivityRecord(rec);

		emit activityUpdated();

	} else if (c.uuid() == BleUuid::CharVitalsData) {
		vitals_record rec{};
		if (!readInto(value, rec))
			return;
		if (m_repository)
			m_repository->saveVitalsRecord(rec);

		emit vitalsUpdated(static_cast<int>(rec.type));

	} else if (c.uuid() == BleUuid::CharEnvironmentData) {
		env_record rec{};
		if (!readInto(value, rec))
			return;
		if (m_repository)
			m_repository->saveEnvironmentRecord(rec);

		emit environmentUpdated();
	}
}

void BleManager::onCharacteristicRead(const QLowEnergyCharacteristic &c, const QByteArray &value)
{
	if (c.uuid() == BleUuid::CharManufacturerName) {
		emit deviceInfoUpdated(QString::fromUtf8(value), QString());
	} else if (c.uuid() == BleUuid::CharFirmwareRevision) {
		emit deviceInfoUpdated(QString(), QString::fromUtf8(value));
	}
}

void BleManager::syncTime()
{
	if (!m_settingsService)
		return;

	QLowEnergyCharacteristic c = m_settingsService->characteristic(BleUuid::CharTime);
	if (!c.isValid())
		return;

	QDateTime now = QDateTime::currentDateTime();
	uint32_t localSecs = static_cast<uint32_t>(now.toSecsSinceEpoch() + now.offsetFromUtc());

	QByteArray payload(reinterpret_cast<const char *>(&localSecs), sizeof(localSecs));
	m_settingsService->writeCharacteristic(c, payload, QLowEnergyService::WriteWithResponse);
}

void BleManager::writeHeightCm(int cm)
{
	m_pendingHeightCm = cm;
	flushPendingSettingsWrites();
}

void BleManager::writeWeightKg(double kg)
{
	m_pendingWeightKg = kg;
	flushPendingSettingsWrites();
}

void BleManager::flushPendingSettingsWrites()
{
	if (m_state != Connected || !m_settingsService)
		return;

	if (m_pendingHeightCm >= 0) {
		QLowEnergyCharacteristic c = m_settingsService->characteristic(BleUuid::CharHeight);
		if (c.isValid()) {
			uint16_t val = static_cast<uint16_t>(m_pendingHeightCm);
			QByteArray payload(reinterpret_cast<const char *>(&val), sizeof(val));
			m_settingsService->writeCharacteristic(c, payload,
												   QLowEnergyService::WriteWithResponse);
		}
		m_pendingHeightCm = -1;
	}

	if (m_pendingWeightKg >= 0.0) {
		QLowEnergyCharacteristic c = m_settingsService->characteristic(BleUuid::CharWeightKg);
		if (c.isValid()) {
			uint16_t val = static_cast<uint16_t>(m_pendingWeightKg);
			QByteArray payload(reinterpret_cast<const char *>(&val), sizeof(val));
			m_settingsService->writeCharacteristic(c, payload,
												   QLowEnergyService::WriteWithResponse);
		}
		m_pendingWeightKg = -1.0;
	}
}

void BleManager::disconnectDevice()
{
	if (m_controller)
		m_controller->disconnectFromDevice();
	else
		setState(Idle);
}
