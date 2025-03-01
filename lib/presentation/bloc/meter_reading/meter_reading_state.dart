import '../../../domain/entities/meter_reading.dart';

abstract class MeterReadingState {
  const MeterReadingState();
}

class MeterReadingInitial extends MeterReadingState {
  const MeterReadingInitial();
}

class MeterReadingLoading extends MeterReadingState {
  const MeterReadingLoading();
}

class MeterReadingsLoaded extends MeterReadingState {
  final List<MeterReading> readings;
  final double totalConsumption;
  final double averageConsumption;

  const MeterReadingsLoaded({
    required this.readings,
    required this.totalConsumption,
    required this.averageConsumption,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeterReadingsLoaded &&
        other.readings == readings &&
        other.totalConsumption == totalConsumption &&
        other.averageConsumption == averageConsumption;
  }

  @override
  int get hashCode =>
      readings.hashCode ^
      totalConsumption.hashCode ^
      averageConsumption.hashCode;
}

class MeterReadingOperationSuccess extends MeterReadingState {
  final String message;

  const MeterReadingOperationSuccess(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeterReadingOperationSuccess && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class MeterReadingError extends MeterReadingState {
  final String message;

  const MeterReadingError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeterReadingError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
