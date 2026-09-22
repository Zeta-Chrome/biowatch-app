#pragma once

#include <QBluetoothUuid>
#include <QString>

namespace BleUuid
{

// ---- Device Information Service (standard Bluetooth SIG UUIDs) ----
inline const QBluetoothUuid ServiceDeviceInfo{ quint16(0x180A) };
inline const QBluetoothUuid CharManufacturerName{ quint16(0x2A29) };
inline const QBluetoothUuid CharFirmwareRevision{ quint16(0x2A26) };

// ---- Activity Service ----
inline const QBluetoothUuid ServiceActivity{ QStringLiteral(
	"04930238-885a-4a87-2d4a-16451765ebdd") }; // BLE_SVC_ACTIVITY
inline const QBluetoothUuid CharActivityData{ QStringLiteral(
	"2be86903-d50f-85b1-b049-96d7733761dd") }; // BLE_CHAR_ACT_DATA

// ---- Vitals Service ----
inline const QBluetoothUuid ServiceVitals{ QStringLiteral(
	"f1333581-c1ac-b4a1-ab4e-2f3f94244396") }; // BLE_SVC_VITALS_DATA
inline const QBluetoothUuid CharVitalsData{ QStringLiteral(
	"58ac6332-de49-d4bc-fc4e-a521ed92b1bb") }; // BLE_CHAR_VITALS_DATA

// ---- Environment Service ----
inline const QBluetoothUuid ServiceEnvironment{ QStringLiteral(
	"acf66696-e8ff-0da5-8246-74126745cdcb") }; // BLE_SVC_ENVIRONMENT
inline const QBluetoothUuid CharEnvironmentData{ QStringLiteral(
	"bac797c8-d98c-1b8f-e44e-e66b986f62cc") }; // BLE_CHAR_ENV_DATA

// ---- Settings Service ----
inline const QBluetoothUuid ServiceSettings{ QStringLiteral(
	"b11f041e-15cb-c6bb-ff4e-bfd0d7f76899") }; // BLE_SVC_SETTINGS
inline const QBluetoothUuid CharTime{ QStringLiteral(
	"011fb41e-a5cb-c8bb-ff4e-bfd0d7f768aa") }; // BLE_CHAR_TIME
inline const QBluetoothUuid CharWeightKg{ QStringLiteral(
	"f2db3ec2-48d0-159a-5b44-376e38ca277c") }; // BLE_CHAR_WEIGHT_KG
inline const QBluetoothUuid CharHeight{ quint16(0x2A8E) }; // BLE_CHAR_HEIGHT

inline const QString DeviceNameFilter = QStringLiteral("BioWatch");

} // namespace BleUuid
