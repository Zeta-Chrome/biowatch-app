#include "repository.h"

#include <QGuiApplication>
#include <QTimeZone>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QSqlError>
#include <QDebug>
#include <QUuid>

namespace
{

qint64 midnight(const QDate &d)
{
	return QDateTime(d, QTime(0, 0), QTimeZone::LocalTime).toSecsSinceEpoch();
}

} // namespace

Repository::Repository(const QString &dbPath, QObject *parent)
	: QObject(parent)
	, m_connectionName(QUuid::createUuid().toString())
{
	QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", m_connectionName);
	db.setDatabaseName(dbPath);
	if (!db.open()) {
		qWarning() << "Repository: failed to open database" << dbPath << db.lastError().text();
		return;
	}
	m_valid = true;
	initSchema();
}

Repository::~Repository()
{
	{
		QSqlDatabase db = QSqlDatabase::database(m_connectionName, false);
		if (db.isOpen())
			db.close();
	}
	QSqlDatabase::removeDatabase(m_connectionName);
}

void Repository::initSchema()
{
	QSqlDatabase db = QSqlDatabase::database(m_connectionName);
	QSqlQuery q(db);

	q.exec("PRAGMA journal_mode=WAL");

	q.exec(R"(
		CREATE TABLE IF NOT EXISTS environment (
			timestamp   INTEGER PRIMARY KEY,
			humidity    REAL,
			temperature REAL,
			lux         REAL
		)
	)");

	q.exec(R"(
		CREATE TABLE IF NOT EXISTS activity (
			timestamp     INTEGER PRIMARY KEY,
			duration_ms   INTEGER,
			distance_m    REAL,
			speed_ms      REAL,
			calories_kcal REAL,
			steps         INTEGER
		)
	)");

	q.exec(R"(
		CREATE TABLE IF NOT EXISTS vitals (
			id        INTEGER PRIMARY KEY AUTOINCREMENT,
			timestamp INTEGER NOT NULL,
			type      INTEGER NOT NULL,
			value     REAL,
			UNIQUE(timestamp, type)
		)
	)");
	q.exec("CREATE INDEX IF NOT EXISTS idx_vitals_type_ts ON vitals(type, timestamp)");
}

bool Repository::saveEnvironmentRecord(const env_record &rec)
{
	if (!m_valid)
		return false;
	QSqlQuery q(QSqlDatabase::database(m_connectionName));
	q.prepare(R"(
		INSERT INTO environment(timestamp, humidity, temperature, lux)
		VALUES(:ts, :rh, :temp, :lux)
		ON CONFLICT(timestamp) DO UPDATE SET
			humidity=excluded.humidity, temperature=excluded.temperature, lux=excluded.lux
	)");
	q.bindValue(":ts", static_cast<qint64>(rec.timestamp));
	q.bindValue(":rh", rec.rhx100 / 100.0);
	q.bindValue(":temp", rec.tempx100 / 100.0);
	q.bindValue(":lux", rec.luxx100 / 100.0);
	if (!q.exec()) {
		qWarning() << "saveEnvironmentRecord failed:" << q.lastError().text();
		return false;
	}
	return true;
}

bool Repository::saveActivityRecord(const act_record &rec)
{
	if (!m_valid)
		return false;
	QSqlQuery q(QSqlDatabase::database(m_connectionName));
	q.prepare(R"(
		INSERT INTO activity(timestamp, duration_ms, distance_m, speed_ms, calories_kcal, steps)
		VALUES(:ts, :dur, :dist, :speed, :cal, :steps)
		ON CONFLICT(timestamp) DO UPDATE SET
			duration_ms=excluded.duration_ms, distance_m=excluded.distance_m,
			speed_ms=excluded.speed_ms, calories_kcal=excluded.calories_kcal,
			steps=excluded.steps
	)");
	q.bindValue(":ts", static_cast<qint64>(rec.timestamp));
	q.bindValue(":dur", static_cast<qint64>(rec.dur_ms));
	q.bindValue(":dist", rec.distance_m);
	q.bindValue(":speed", rec.speed_ms); // Store raw SI units (m/s)
	q.bindValue(":cal", rec.calories_kcal);
	q.bindValue(":steps", rec.steps);
	if (!q.exec()) {
		qWarning() << "saveActivityRecord failed:" << q.lastError().text();
		return false;
	}
	return true;
}

bool Repository::saveVitalsRecord(const vitals_record &rec)
{
	if (!m_valid)
		return false;
	double value = (rec.type == VITALS_HR) ? static_cast<double>(rec.value.hr_bpm) :
											 static_cast<double>(rec.value.spo2_pct);

	QSqlQuery q(QSqlDatabase::database(m_connectionName));
	q.prepare(R"(
		INSERT OR IGNORE INTO vitals(timestamp, type, value) VALUES(:ts, :type, :val)
	)");
	q.bindValue(":ts", static_cast<qint64>(rec.timestamp));
	q.bindValue(":type", static_cast<int>(rec.type));
	q.bindValue(":val", value);
	if (!q.exec()) {
		qWarning() << "saveVitalsRecord failed:" << q.lastError().text();
		return false;
	}
	return true;
}

QVariantMap Repository::getLatestEnvironment() const
{
	QVariantMap out;
	if (!m_valid)
		return out;
	QSqlQuery q(QSqlDatabase::database(m_connectionName));
	q.exec("SELECT timestamp, humidity, temperature, lux FROM environment "
		   "ORDER BY timestamp DESC LIMIT 1");
	if (q.next()) {
		out["timestamp"] = q.value(0).toLongLong();
		out["humidity"] = q.value(1).toDouble();
		out["temperature"] = q.value(2).toDouble();
		out["lux"] = q.value(3).toDouble();
	}
	return out;
}

QVariantMap Repository::getLatestActivity() const
{
	QVariantMap out;
	if (!m_valid)
		return out;
	QSqlQuery q(QSqlDatabase::database(m_connectionName));
	q.exec("SELECT timestamp, duration_ms, distance_m, speed_ms, calories_kcal, steps "
		   "FROM activity ORDER BY timestamp DESC LIMIT 1");
	if (q.next()) {
		out["timestamp"] = q.value(0).toLongLong();
		out["duration_ms"] = q.value(1).toLongLong();
		out["distance_m"] = q.value(2).toDouble();
		// Convert m/s -> km/h for application layer
		out["speed_kmh"] = q.value(3).toDouble() * 3.6;
		out["calories_kcal"] = q.value(4).toDouble();
		out["steps"] = q.value(5).toInt();
	}
	return out;
}

QVariantMap Repository::getLatestVital(int type) const
{
	QVariantMap out;
	if (!m_valid)
		return out;
	QSqlQuery q(QSqlDatabase::database(m_connectionName));
	q.prepare("SELECT timestamp, value FROM vitals WHERE type=:type "
			  "ORDER BY timestamp DESC LIMIT 1");
	q.bindValue(":type", type);
	q.exec();
	if (q.next()) {
		out["timestamp"] = q.value(0).toLongLong();
		out["value"] = q.value(1).toDouble();
	}
	return out;
}

std::pair<qint64, qint64> Repository::rangeFor(TimeFrame tf, const QDate &refDate)
{
	QDateTime startDt = refDate.startOfDay(QTimeZone::LocalTime);
	QDateTime endDt;

	switch (tf) {
	case TimeFrame::DAY:
		endDt = startDt.addDays(1);
		break;
	case TimeFrame::WEEK: {
		int dow = refDate.dayOfWeek();
		startDt = startDt.addDays(-(dow - 1));
		endDt = startDt.addDays(7);
		break;
	}
	case TimeFrame::MONTH:
		startDt =
			QDateTime(QDate(refDate.year(), refDate.month(), 1), QTime(0, 0), QTimeZone::LocalTime);
		endDt = startDt.addMonths(1);
		break;
	case TimeFrame::YEAR:
		startDt = QDateTime(QDate(refDate.year(), 1, 1), QTime(0, 0), QTimeZone::LocalTime);
		endDt = startDt.addYears(1);
		break;
	}

	return { startDt.toSecsSinceEpoch(), endDt.toSecsSinceEpoch() };
}

void Repository::clearAllData()
{
	QSqlDatabase db = QSqlDatabase::database(m_connectionName);
	QSqlQuery q(db);

	bool ok = true;
	if (db.transaction()) {
		ok &= q.exec("DELETE FROM environment;");
		ok &= q.exec("DELETE FROM activity;");
		ok &= q.exec("DELETE FROM vitals;");

		if (ok) {
			db.commit();
			qDebug() << "Repository: Tables cleared successfully.";
		} else {
			db.rollback();
			qWarning() << "Repository: Failed to delete records:" << q.lastError().text();
		}
	} else {
		qWarning() << "Repository: Failed to start transaction:" << db.lastError().text();
	}

	if (!q.exec("VACUUM;")) {
		qWarning() << "Repository: VACUUM warning (non-fatal):" << q.lastError().text();
	}
}

QVariantList Repository::getEnvironmentMetric(const QString &metricName, TimeFrame timeFrame,
											  const QDate &refDate) const
{
	QVariantList out;
	if (!m_valid)
		return out;

	static const QStringList allowed = { "humidity", "temperature", "lux" };
	if (!allowed.contains(metricName))
		return out;

	auto [start, end] = rangeFor(timeFrame, refDate);
	QSqlDatabase db = QSqlDatabase::database(m_connectionName);
	QSqlQuery q(db);

	switch (timeFrame) {
	case TimeFrame::DAY:
		q.prepare(QString("SELECT timestamp, %1 as value FROM environment "
						  "WHERE timestamp>=:s AND timestamp<:e ORDER BY timestamp ASC")
					  .arg(metricName));
		break;
	case TimeFrame::WEEK:
		q.prepare(QString("SELECT (timestamp/3600)*3600 as bucket, AVG(%1) as value "
						  "FROM environment WHERE timestamp>=:s AND timestamp<:e "
						  "GROUP BY bucket ORDER BY bucket ASC")
					  .arg(metricName));
		break;
	case TimeFrame::MONTH:
		q.prepare(QString("SELECT (timestamp/86400)*86400 as bucket, AVG(%1) as value "
						  "FROM environment WHERE timestamp>=:s AND timestamp<:e "
						  "GROUP BY bucket ORDER BY bucket ASC")
					  .arg(metricName));
		break;
	case TimeFrame::YEAR:
		q.prepare(QString("SELECT MIN(timestamp) as bucket, AVG(%1) as value "
						  "FROM environment WHERE timestamp>=:s AND timestamp<:e "
						  "GROUP BY strftime('%%Y-%%m', timestamp, 'unixepoch') "
						  "ORDER BY bucket ASC")
					  .arg(metricName));
		break;
	}
	q.bindValue(":s", start);
	q.bindValue(":e", end);
	if (!q.exec()) {
		qWarning() << "getEnvironmentMetric failed:" << q.lastError().text();
		return out;
	}
	while (q.next()) {
		QVariantMap row;
		row["timestamp"] = q.value(0).toLongLong();
		row["value"] = q.value(1).toDouble();
		out.append(row);
	}
	return out;
}

QVariantList Repository::getActivity(TimeFrame timeFrame, const QDate &refDate) const
{
	QVariantList out;
	if (!m_valid)
		return out;

	auto [start, end] = rangeFor(timeFrame, refDate);
	QSqlDatabase db = QSqlDatabase::database(m_connectionName);
	QSqlQuery q(db);

	if (timeFrame == TimeFrame::YEAR) {
		q.prepare(R"(
			SELECT MIN(timestamp) as bucket, SUM(steps), SUM(distance_m),
			       AVG(speed_ms), SUM(calories_kcal), SUM(duration_ms)
			FROM activity WHERE timestamp>=:s AND timestamp<:e
			GROUP BY strftime('%Y-%m', timestamp, 'unixepoch')
			ORDER BY bucket ASC
		)");
	} else {
		q.prepare(R"(
			SELECT timestamp, steps, distance_m, speed_ms, calories_kcal, duration_ms
			FROM activity WHERE timestamp>=:s AND timestamp<:e ORDER BY timestamp ASC
		)");
	}
	q.bindValue(":s", start);
	q.bindValue(":e", end);
	if (!q.exec()) {
		qWarning() << "getActivity failed:" << q.lastError().text();
		return out;
	}
	while (q.next()) {
		QVariantMap row;
		row["timestamp"] = q.value(0).toLongLong();
		row["steps"] = q.value(1).toInt();
		row["distance_m"] = q.value(2).toDouble();
		// Convert m/s -> km/h before pushing to UI layer
		row["speed_kmh"] = q.value(3).toDouble() * 3.6;
		row["calories_kcal"] = q.value(4).toDouble();
		row["duration_ms"] = q.value(5).toLongLong();
		out.append(row);
	}
	return out;
}

QVariantList Repository::getVitals(int type, TimeFrame timeFrame, const QDate &refDate) const
{
	QVariantList out;
	if (!m_valid)
		return out;

	auto [start, end] = rangeFor(timeFrame, refDate);
	QSqlDatabase db = QSqlDatabase::database(m_connectionName);
	QSqlQuery q(db);

	switch (timeFrame) {
	case TimeFrame::DAY:
		q.prepare(R"(
			SELECT timestamp, value FROM vitals
			WHERE type=:type AND timestamp>=:s AND timestamp<:e ORDER BY timestamp ASC
		)");
		break;
	case TimeFrame::WEEK:
	case TimeFrame::MONTH:
		q.prepare(R"(
			SELECT (timestamp/86400)*86400 as bucket, AVG(value) as value FROM vitals
			WHERE type=:type AND timestamp>=:s AND timestamp<:e
			GROUP BY bucket ORDER BY bucket ASC
		)");
		break;
	case TimeFrame::YEAR:
		q.prepare(R"(
			SELECT MIN(timestamp) as bucket, AVG(value) as value FROM vitals
			WHERE type=:type AND timestamp>=:s AND timestamp<:e
			GROUP BY strftime('%Y-%m', timestamp, 'unixepoch') ORDER BY bucket ASC
		)");
		break;
	}
	q.bindValue(":type", type);
	q.bindValue(":s", start);
	q.bindValue(":e", end);
	if (!q.exec()) {
		qWarning() << "getVitals failed:" << q.lastError().text();
		return out;
	}
	while (q.next()) {
		QVariantMap row;
		row["timestamp"] = q.value(0).toLongLong();
		row["value"] = q.value(1).toDouble();
		out.append(row);
	}
	return out;
}
