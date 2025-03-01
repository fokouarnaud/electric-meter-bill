import '../entities/meter.dart';

abstract class MeterRepository {
  Future<List<Meter>> getMeters();
  Future<Meter?> getMeterById(String id);
  Future<void> addMeter(Meter meter);
  Future<void> updateMeter(Meter meter);
  Future<void> deleteMeter(String id);
  Future<bool> meterExists(String id);
  Future<int> getMeterCount();
}
