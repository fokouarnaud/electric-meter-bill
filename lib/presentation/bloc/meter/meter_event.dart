import '../../../domain/entities/meter.dart';

abstract class MeterEvent {
  const MeterEvent();
}

class LoadMeters extends MeterEvent {
  const LoadMeters();
}

class AddMeter extends MeterEvent {
  final Meter meter;

  const AddMeter(this.meter);
}

class UpdateMeter extends MeterEvent {
  final Meter meter;

  const UpdateMeter(this.meter);
}

class DeleteMeter extends MeterEvent {
  final String id;

  const DeleteMeter(this.id);
}

class RefreshMeters extends MeterEvent {
  const RefreshMeters();
}
