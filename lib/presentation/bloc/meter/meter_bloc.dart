//presentation\bloc\meter\meter_bloc.dart

import 'package:electric_meter_bill/domain/repositories/meter_repository.dart';
import 'package:electric_meter_bill/presentation/bloc/meter/meter_event.dart';
import 'package:electric_meter_bill/presentation/bloc/meter/meter_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MeterBloc extends Bloc<MeterEvent, MeterState> {
  final MeterRepository repository;

  MeterBloc({required this.repository}) : super(const MeterInitial()) {
    on<LoadMeters>(_onLoadMeters);
    on<AddMeter>(_onAddMeter);
    on<UpdateMeter>(_onUpdateMeter);
    on<DeleteMeter>(_onDeleteMeter);
    on<RefreshMeters>(_onRefreshMeters);
    on<SortMeters>(_onSortMeters);
  }

  Future<void> _onLoadMeters(LoadMeters event, Emitter<MeterState> emit) async {
    try {
      debugPrint('Loading meters...');
      emit(const MeterLoading());
      final meters = await repository.getMeters();
      final totalMeters = await repository.getMeterCount();
      debugPrint('Loaded ${meters.length} meters');

      // Calculate totals
      double totalConsumption = 0;
      double totalAmount = 0;
      // Note: In a real app, you would calculate these from bills or readings

      emit(MetersLoaded(
        meters: meters,
        totalMeters: totalMeters,
        totalConsumption: totalConsumption,
        totalAmount: totalAmount,
      ));
    } catch (e) {
      debugPrint('Error loading meters: $e');
      emit(MeterError(e.toString()));
    }
  }

  Future<void> _onAddMeter(AddMeter event, Emitter<MeterState> emit) async {
    try {
      debugPrint('Adding meter: ${event.meter}');
      emit(const MeterLoading());
      await repository.addMeter(event.meter);
      final meters = await repository.getMeters();
      final totalMeters = await repository.getMeterCount();
      debugPrint('Meter added successfully. Total meters: $totalMeters');

      emit(const MeterOperationSuccess('Meter added successfully'));
      emit(MetersLoaded(
        meters: meters,
        totalMeters: totalMeters,
        totalConsumption: 0, // Update with real data
        totalAmount: 0, // Update with real data
      ));
    } catch (e) {
      debugPrint('Error adding meter: $e');
      emit(MeterError(e.toString()));
    }
  }

  Future<void> _onUpdateMeter(
      UpdateMeter event, Emitter<MeterState> emit) async {
    try {
      debugPrint('Updating meter: ${event.meter}');
      emit(const MeterLoading());
      await repository.updateMeter(event.meter);
      final meters = await repository.getMeters();
      final totalMeters = await repository.getMeterCount();
      debugPrint('Meter updated successfully');

      emit(const MeterOperationSuccess('Meter updated successfully'));
      emit(MetersLoaded(
        meters: meters,
        totalMeters: totalMeters,
        totalConsumption: 0, // Update with real data
        totalAmount: 0, // Update with real data
      ));
    } catch (e) {
      debugPrint('Error updating meter: $e');
      emit(MeterError(e.toString()));
    }
  }

  Future<void> _onDeleteMeter(
      DeleteMeter event, Emitter<MeterState> emit) async {
    try {
      debugPrint('Deleting meter with ID: ${event.id}');
      emit(const MeterLoading());
      await repository.deleteMeter(event.id);
      final meters = await repository.getMeters();
      final totalMeters = await repository.getMeterCount();
      debugPrint('Meter deleted successfully');

      emit(const MeterOperationSuccess('Meter deleted successfully'));
      emit(MetersLoaded(
        meters: meters,
        totalMeters: totalMeters,
        totalConsumption: 0, // Update with real data
        totalAmount: 0, // Update with real data
      ));
    } catch (e) {
      debugPrint('Error deleting meter: $e');
      emit(MeterError(e.toString()));
    }
  }

  Future<void> _onRefreshMeters(
      RefreshMeters event, Emitter<MeterState> emit) async {
    try {
      debugPrint('Refreshing meters...');
      final meters = await repository.getMeters();
      final totalMeters = await repository.getMeterCount();
      debugPrint('Meters refreshed. Total meters: $totalMeters');

      emit(MetersLoaded(
        meters: meters,
        totalMeters: totalMeters,
        totalConsumption: 0, // Update with real data
        totalAmount: 0, // Update with real data
      ));
    } catch (e) {
      debugPrint('Error refreshing meters: $e');
      emit(MeterError(e.toString()));
    }
  }

  Future<void> _onSortMeters(SortMeters event, Emitter<MeterState> emit) async {
    try {
      final currentState = state;
      if (currentState is MetersLoaded) {
        final sortedMeters = List.of(currentState.meters);
        switch (event.criteria) {
          case 'name':
            sortedMeters.sort((a, b) => a.name.compareTo(b.name));
            break;
          case 'date':
            sortedMeters.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            break;
          case 'location':
            sortedMeters.sort((a, b) => a.location.compareTo(b.location));
            break;
        }
        emit(MetersLoaded(
          meters: sortedMeters,
          totalMeters: currentState.totalMeters,
          totalConsumption: currentState.totalConsumption,
          totalAmount: currentState.totalAmount,
        ));
      }
    } catch (e) {
      debugPrint('Error sorting meters: $e');
      emit(MeterError(e.toString()));
    }
  }
}
