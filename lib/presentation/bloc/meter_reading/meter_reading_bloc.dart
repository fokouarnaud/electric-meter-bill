import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/meter_reading.dart';
import '../../../domain/repositories/meter_reading_repository.dart';
import 'meter_reading_event.dart';
import 'meter_reading_state.dart';

class MeterReadingBloc extends Bloc<MeterReadingEvent, MeterReadingState> {
  final MeterReadingRepository repository;

  MeterReadingBloc({required this.repository})
      : super(const MeterReadingInitial()) {
    on<LoadMeterReadings>(_onLoadMeterReadings);
    on<AddMeterReading>(_onAddMeterReading);
    on<UpdateMeterReading>(_onUpdateMeterReading);
    on<DeleteMeterReading>(_onDeleteMeterReading);
    on<VerifyMeterReading>(_onVerifyMeterReading);
    on<RefreshMeterReadings>(_onRefreshMeterReadings);
  }

  Future<void> _onLoadMeterReadings(
    LoadMeterReadings event,
    Emitter<MeterReadingState> emit,
  ) async {
    try {
      emit(const MeterReadingLoading());
      final readings = await repository.getMeterReadings(event.meterId);
      _emitLoadedState(emit, readings);
    } catch (e) {
      emit(MeterReadingError(e.toString()));
    }
  }

  Future<void> _onAddMeterReading(
    AddMeterReading event,
    Emitter<MeterReadingState> emit,
  ) async {
    try {
      emit(const MeterReadingLoading());
      await repository.addMeterReading(event.reading);
      final readings = await repository.getMeterReadings(event.reading.meterId);
      emit(const MeterReadingOperationSuccess('Reading added successfully'));
      _emitLoadedState(emit, readings);
    } catch (e) {
      emit(MeterReadingError(e.toString()));
    }
  }

  Future<void> _onUpdateMeterReading(
    UpdateMeterReading event,
    Emitter<MeterReadingState> emit,
  ) async {
    try {
      emit(const MeterReadingLoading());
      await repository.updateMeterReading(event.reading);
      final readings = await repository.getMeterReadings(event.reading.meterId);
      emit(const MeterReadingOperationSuccess('Reading updated successfully'));
      _emitLoadedState(emit, readings);
    } catch (e) {
      emit(MeterReadingError(e.toString()));
    }
  }

  Future<void> _onDeleteMeterReading(
    DeleteMeterReading event,
    Emitter<MeterReadingState> emit,
  ) async {
    try {
      emit(const MeterReadingLoading());
      await repository.deleteMeterReading(event.id);

      // Get the current state to access meterId
      if (state is MeterReadingsLoaded) {
        final currentState = state as MeterReadingsLoaded;
        final readings = currentState.readings;
        final meterId = readings.firstWhere((r) => r.id == event.id).meterId;

        final updatedReadings = await repository.getMeterReadings(meterId);
        emit(
            const MeterReadingOperationSuccess('Reading deleted successfully'));
        _emitLoadedState(emit, updatedReadings);
      }
    } catch (e) {
      emit(MeterReadingError(e.toString()));
    }
  }

  Future<void> _onVerifyMeterReading(
    VerifyMeterReading event,
    Emitter<MeterReadingState> emit,
  ) async {
    try {
      emit(const MeterReadingLoading());
      await repository.updateMeterReading(event.reading);
      final readings = await repository.getMeterReadings(event.reading.meterId);
      emit(const MeterReadingOperationSuccess('Reading verified successfully'));
      _emitLoadedState(emit, readings);
    } catch (e) {
      emit(MeterReadingError(e.toString()));
    }
  }

  Future<void> _onRefreshMeterReadings(
    RefreshMeterReadings event,
    Emitter<MeterReadingState> emit,
  ) async {
    try {
      final readings = await repository.getMeterReadings(event.meterId);
      _emitLoadedState(emit, readings);
    } catch (e) {
      emit(MeterReadingError(e.toString()));
    }
  }

  void _emitLoadedState(
      Emitter<MeterReadingState> emit, List<MeterReading> readings) {
    double totalConsumption = 0;
    double averageConsumption = 0;

    if (readings.length >= 2) {
      // Calculate consumption between consecutive readings
      for (int i = 0; i < readings.length - 1; i++) {
        final consumption = readings[i].value - readings[i + 1].value;
        if (consumption > 0) {
          totalConsumption += consumption;
        }
      }

      // Calculate average consumption
      final days = readings.first.readingDate
          .difference(readings.last.readingDate)
          .inDays;
      if (days > 0) {
        averageConsumption = totalConsumption / days;
      }
    }

    emit(MeterReadingsLoaded(
      readings: readings,
      totalConsumption: totalConsumption,
      averageConsumption: averageConsumption,
    ));
  }
}
