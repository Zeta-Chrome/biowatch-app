#pragma once

#include <QObject>
#include <memory>
#include "repository.h"
#include "blemanager.h"

class AppManager : public QObject {
	Q_OBJECT

	Q_PROPERTY(QString firmwareVersion READ firmwareVersion NOTIFY firmwareVersionChanged)
	Q_PROPERTY(int heightCm READ heightCm WRITE setHeightCm NOTIFY heightCmChanged)
	Q_PROPERTY(int weightKg READ weightKg WRITE setWeightKg NOTIFY weightKgChanged)

	// Exposed once and never reassigned - QML owns these for the app's lifetime.
	Q_PROPERTY(Repository *repository READ repository CONSTANT)
	Q_PROPERTY(BleManager *ble READ ble CONSTANT)

public:
	explicit AppManager(QObject *parent = nullptr);
	~AppManager() override;

	QString firmwareVersion() const { return m_firmwareVersion; }
	int heightCm() const { return m_heightCm; }
	int weightKg() const { return m_weightKg; }

	void setHeightCm(int cm);
	void setWeightKg(int kg);

	Repository *repository() const { return m_repository.get(); }
	BleManager *ble() const { return m_ble.get(); }

signals:
	void firmwareVersionChanged();
	void heightCmChanged();
	void weightKgChanged();

private slots:
	void onDeviceInfoUpdated(const QString &manufacturer, const QString &firmwareVersion);

private:
	void loadSettings();
	void saveSettings();

	QString m_firmwareVersion{ "0.0.0" };
	int m_heightCm{ 170 };
	int m_weightKg{ 70 };

	std::unique_ptr<Repository> m_repository;
	std::unique_ptr<BleManager> m_ble;
};
