#pragma once

#include <QObject>
#include <QSqlDatabase>
#include <QDateTime>
#include <QDate>
#include <QVariantList>
#include <QVariantMap>
#include <cstdint>

enum vitals_type : uint32_t { VITALS_HR = 0, VITALS_SPO2 = 1 };

#pragma pack(push, 1)
struct act_record {
	uint32_t timestamp;
	uint32_t dur_ms;
	float distance_m;
	float speed_ms;
	float calories_kcal;
	uint16_t steps;
	uint16_t reserved;
};

struct vitals_record {
	uint32_t timestamp;
	uint32_t type;
	union {
		uint8_t hr_bpm;
		float spo2_pct;
	} value;
};

struct env_record {
	uint32_t timestamp;
	uint16_t rhx100;
	int16_t tempx100;
	uint16_t luxx100;
	uint16_t reserved;
};
#pragma pack(pop)

class Repository : public QObject {
	Q_OBJECT

public:
	enum class TimeFrame : uint8_t { DAY, WEEK, MONTH, YEAR };
	Q_ENUM(TimeFrame)

	explicit Repository(const QString &dbPath, QObject *parent = nullptr);
	~Repository() override;

	bool isValid() const
	{
		return m_valid;
	}

	bool saveEnvironmentRecord(const env_record &rec);
	bool saveActivityRecord(const act_record &rec);
	bool saveVitalsRecord(const vitals_record &rec);

	Q_INVOKABLE void clearAllData();
	Q_INVOKABLE QVariantMap getLatestEnvironment() const;
	Q_INVOKABLE QVariantMap getLatestActivity() const;
	Q_INVOKABLE QVariantMap getLatestVital(int type) const;
	Q_INVOKABLE QVariantList getEnvironmentMetric(const QString &metricName, TimeFrame timeFrame,
												  const QDate &refDate = QDate::currentDate()) const;
	Q_INVOKABLE QVariantList getActivity(TimeFrame timeFrame,
										 const QDate &refDate = QDate::currentDate()) const;
	Q_INVOKABLE QVariantList getVitals(int type, TimeFrame timeFrame,
									   const QDate &refDate = QDate::currentDate()) const;

private:
	void initSchema();
	static std::pair<qint64, qint64> rangeFor(TimeFrame tf, const QDate &refDate);

	QString m_connectionName;
	bool m_valid{ false };
};
