import '../../../domain/entities/meter.dart';

abstract class MeterState {
  const MeterState();
}

class MeterInitial extends MeterState {
  const MeterInitial();
}

class MeterLoading extends MeterState {
  const MeterLoading();
}

class MetersLoaded extends MeterState {
  final List<Meter> meters;
  final int totalMeters;
  final double totalConsumption;
  final double totalAmount;

  const MetersLoaded({
    required this.meters,
    required this.totalMeters,
    required this.totalConsumption,
    required this.totalAmount,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetersLoaded &&
        other.meters == meters &&
        other.totalMeters == totalMeters &&
        other.totalConsumption == totalConsumption &&
        other.totalAmount == totalAmount;
  }

  @override
  int get hashCode {
    return meters.hashCode ^
        totalMeters.hashCode ^
        totalConsumption.hashCode ^
        totalAmount.hashCode;
  }
}

class MeterError extends MeterState {
  final String message;

  const MeterError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeterError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class MeterOperationSuccess extends MeterState {
  final String message;

  const MeterOperationSuccess(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeterOperationSuccess && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
