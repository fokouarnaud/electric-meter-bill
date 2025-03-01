import '../../../domain/entities/meter_reading.dart';

abstract class MeterReadingEvent {
  const MeterReadingEvent();
}

class LoadMeterReadings extends MeterReadingEvent {
  final String meterId;

  const LoadMeterReadings(this.meterId);
}

class AddMeterReading extends MeterReadingEvent {
  final MeterReading reading;

  const AddMeterReading(this.reading);
}

class UpdateMeterReading extends MeterReadingEvent {
  final MeterReading reading;

  const UpdateMeterReading(this.reading);
}

class DeleteMeterReading extends MeterReadingEvent {
  final String id;

  const DeleteMeterReading(this.id);
}

class VerifyMeterReading extends MeterReadingEvent {
  final MeterReading reading;

  const VerifyMeterReading(this.reading);
}

class RefreshMeterReadings extends MeterReadingEvent {
  final String meterId;

  const RefreshMeterReadings(this.meterId);
}
