import 'package:sqflite/sqflite.dart';
import '../../domain/entities/meter.dart';
import '../../domain/repositories/meter_repository.dart';
import '../datasources/database_helper.dart';
import '../models/meter_model.dart';

class MeterRepositoryImpl implements MeterRepository {
  final DatabaseHelper _databaseHelper;

  MeterRepositoryImpl(this._databaseHelper);

  @override
  Future<List<Meter>> getMeters() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('meters');
    return List.generate(maps.length, (i) => MeterModel.fromMap(maps[i]));
  }

  @override
  Future<Meter?> getMeterById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'meters',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return MeterModel.fromMap(maps.first);
  }

  @override
  Future<void> addMeter(Meter meter) async {
    final db = await _databaseHelper.database;
    final meterModel =
        meter is MeterModel ? meter : MeterModel.fromMeter(meter);
    await db.insert(
      'meters',
      meterModel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateMeter(Meter meter) async {
    final db = await _databaseHelper.database;
    final meterModel =
        meter is MeterModel ? meter : MeterModel.fromMeter(meter);
    await db.update(
      'meters',
      meterModel.toMap(),
      where: 'id = ?',
      whereArgs: [meter.id],
    );
  }

  @override
  Future<void> deleteMeter(String id) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      // Delete related meter readings
      await txn.delete(
        'meter_readings',
        where: 'meter_id = ?',
        whereArgs: [id],
      );

      // Delete related bills
      await txn.delete(
        'bills',
        where: 'meter_id = ?',
        whereArgs: [id],
      );

      // Delete the meter
      await txn.delete(
        'meters',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<bool> meterExists(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'meters',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  @override
  Future<int> getMeterCount() async {
    final db = await _databaseHelper.database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM meters'),
        ) ??
        0;
  }
}
