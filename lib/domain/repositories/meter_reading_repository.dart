import '../entities/meter_reading.dart';

abstract class MeterReadingRepository {
  Future<List<MeterReading>> getMeterReadings(String meterId);
  Future<MeterReading?> getMeterReadingById(String id);
  Future<void> addMeterReading(MeterReading reading);
  Future<void> updateMeterReading(MeterReading reading);
  Future<void> deleteMeterReading(String id);
  Future<bool> meterReadingExists(String id);
  Future<int> getMeterReadingCount(String meterId);
  Future<List<MeterReading>> getLatestReadings(String meterId, {int limit = 2});
  Future<double?> getLastReadingValue(String meterId);
}
