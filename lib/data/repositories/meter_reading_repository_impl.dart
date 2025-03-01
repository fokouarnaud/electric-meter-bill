import 'package:sqflite/sqflite.dart';
import '../../domain/entities/meter_reading.dart';
import '../../domain/repositories/meter_reading_repository.dart';
import '../datasources/database_helper.dart';
import '../models/meter_reading_model.dart';

class MeterReadingRepositoryImpl implements MeterReadingRepository {
  final DatabaseHelper _databaseHelper;

  MeterReadingRepositoryImpl(this._databaseHelper);

  @override
  Future<List<MeterReading>> getMeterReadings(String meterId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'meter_readings',
      where: 'meter_id = ?',
      whereArgs: [meterId],
      orderBy: 'reading_date DESC',
    );
    return List.generate(
        maps.length, (i) => MeterReadingModel.fromMap(maps[i]));
  }

  @override
  Future<MeterReading?> getMeterReadingById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'meter_readings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return MeterReadingModel.fromMap(maps.first);
  }

  @override
  Future<void> addMeterReading(MeterReading reading) async {
    final db = await _databaseHelper.database;
    final readingModel = reading is MeterReadingModel
        ? reading
        : MeterReadingModel(
            id: reading.id,
            meterId: reading.meterId,
            value: reading.value,
            imageUrl: reading.imageUrl,
            readingDate: reading.readingDate,
            isVerified: reading.isVerified,
            createdAt: DateTime.now(),
            notes: reading.notes,
            consumption: reading.consumption,
          );
    await db.insert(
      'meter_readings',
      readingModel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateMeterReading(MeterReading reading) async {
    final db = await _databaseHelper.database;
    final readingModel = reading is MeterReadingModel
        ? reading
        : MeterReadingModel(
            id: reading.id,
            meterId: reading.meterId,
            value: reading.value,
            imageUrl: reading.imageUrl,
            readingDate: reading.readingDate,
            isVerified: reading.isVerified,
            createdAt: DateTime.now(),
            notes: reading.notes,
            consumption: reading.consumption,
          );
    await db.update(
      'meter_readings',
      readingModel.toMap(),
      where: 'id = ?',
      whereArgs: [reading.id],
    );
  }

  @override
  Future<void> deleteMeterReading(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'meter_readings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<bool> meterReadingExists(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'meter_readings',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  @override
  Future<int> getMeterReadingCount(String meterId) async {
    final db = await _databaseHelper.database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM meter_readings WHERE meter_id = ?',
            [meterId],
          ),
        ) ??
        0;
  }

  @override
  Future<List<MeterReading>> getLatestReadings(String meterId,
      {int limit = 2}) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'meter_readings',
      where: 'meter_id = ?',
      whereArgs: [meterId],
      orderBy: 'reading_date DESC',
      limit: limit,
    );
    return List.generate(
        maps.length, (i) => MeterReadingModel.fromMap(maps[i]));
  }

  @override
  Future<double?> getLastReadingValue(String meterId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'meter_readings',
      columns: ['value'],
      where: 'meter_id = ?',
      whereArgs: [meterId],
      orderBy: 'reading_date DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return maps.first['value'] as double;
  }
}
