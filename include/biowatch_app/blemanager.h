#pragma once

#include <QObject>
#include <QBluetoothDeviceDiscoveryAgent>
#include <QLowEnergyController>
#include <QLowEnergyService>
#include <QVariantMap>
#include <memory>

class Repository;

class BleManager : public QObject {
	Q_OBJECT

	Q_PROPERTY(ConnectionState connectionState READ connectionState NOTIFY connectionStateChanged)
	Q_PROPERTY(QString statusText READ statusText NOTIFY connectionStateChanged)
	Q_PROPERTY(QString deviceName READ deviceName NOTIFY deviceNameChanged)

public:
	enum ConnectionState : uint8_t { Idle, Scanning, Connecting, Connected, Error };
	Q_ENUM(ConnectionState)

	explicit BleManager(Repository *repository, QObject *parent = nullptr);
	~BleManager() override;

	ConnectionState connectionState() const
	{
		return m_state;
	}
	QString statusText() const;
	QString deviceName() const
	{
		return m_deviceName;
	}

	Q_INVOKABLE void scanAndConnect();
	Q_INVOKABLE void disconnectDevice();
	Q_INVOKABLE void writeHeightCm(int cm);
	Q_INVOKABLE void writeWeightKg(double kg);

signals:
	void connectionStateChanged();
	void deviceNameChanged();

	void activityUpdated();
	void vitalsUpdated(int type);
	void environmentUpdated();
	void deviceInfoUpdated(const QString &manufacturer, const QString &firmwareVersion);

private slots:
	void onDeviceDiscovered(const QBluetoothDeviceInfo &info);
	void onDiscoveryFinished();
	void onDiscoveryError(QBluetoothDeviceDiscoveryAgent::Error error);

	void onControllerConnected();
	void onControllerDisconnected();
	void onControllerError(QLowEnergyController::Error error);
	void onServiceDiscoveryFinished();

	void onServiceStateChanged(QLowEnergyService::ServiceState state);
	void onCharacteristicChanged(const QLowEnergyCharacteristic &c, const QByteArray &value);
	void onCharacteristicRead(const QLowEnergyCharacteristic &c, const QByteArray &value);

private:
	void setState(ConnectionState s);
	void startScanning();
	void checkPermissionsAndScan();
	void setupService(QLowEnergyService *service);
	void enableNotification(QLowEnergyService *service, const QBluetoothUuid &charUuid);
	void syncTime();
	void flushPendingSettingsWrites();
	void cleanupServices();

	Repository *m_repository{ nullptr };
	std::unique_ptr<QBluetoothDeviceDiscoveryAgent> m_discovery;
	std::unique_ptr<QLowEnergyController> m_controller;

	QList<QLowEnergyService *> m_activeServices;
	QLowEnergyService *m_settingsService{ nullptr };

	ConnectionState m_state{ Idle };
	QString m_deviceName;

	int m_pendingHeightCm{ -1 };
	double m_pendingWeightKg{ -1.0 };
};
