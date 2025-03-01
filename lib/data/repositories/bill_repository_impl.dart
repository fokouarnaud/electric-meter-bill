import 'package:sqflite/sqflite.dart';
import '../../domain/entities/bill.dart';
import '../../domain/repositories/bill_repository.dart';
import '../datasources/database_helper.dart';
import '../models/bill_model.dart';

class BillRepositoryImpl implements BillRepository {
  final DatabaseHelper _databaseHelper;

  BillRepositoryImpl(this._databaseHelper);

  @override
  Future<List<Bill>> getBills(String meterId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bills',
      where: 'meter_id = ?',
      whereArgs: [meterId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => BillModel.fromMap(maps[i]));
  }

  @override
  Future<Bill?> getBillById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bills',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return BillModel.fromMap(maps.first);
  }

  @override
  Future<void> addBill(Bill bill) async {
    final db = await _databaseHelper.database;
    final billModel = bill as BillModel;
    await db.insert(
      'bills',
      billModel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateBill(Bill bill) async {
    final db = await _databaseHelper.database;
    final billModel = bill as BillModel;
    await db.update(
      'bills',
      billModel.toMap(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );
  }

  @override
  Future<void> deleteBill(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'bills',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<bool> billExists(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bills',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  @override
  Future<int> getBillCount(String meterId) async {
    final db = await _databaseHelper.database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM bills WHERE meter_id = ?',
            [meterId],
          ),
        ) ??
        0;
  }

  @override
  Future<List<Bill>> getUnpaidBills(String meterId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bills',
      where: 'meter_id = ? AND is_paid = 0',
      whereArgs: [meterId],
      orderBy: 'due_date ASC',
    );
    return List.generate(maps.length, (i) => BillModel.fromMap(maps[i]));
  }

  @override
  Future<double> getTotalAmount(String meterId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM bills WHERE meter_id = ?',
      [meterId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<double> getUnpaidAmount(String meterId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM bills WHERE meter_id = ? AND is_paid = 0',
      [meterId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<List<Bill>> getBillsForPeriod({
    required String meterId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bills',
      where: 'meter_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [
        meterId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => BillModel.fromMap(maps[i]));
  }

  @override
  Future<void> updatePaymentStatus({
    required String billId,
    required bool isPaid,
  }) async {
    final db = await _databaseHelper.database;
    await db.update(
      'bills',
      {'is_paid': isPaid ? 1 : 0},
      where: 'id = ?',
      whereArgs: [billId],
    );
  }
}
