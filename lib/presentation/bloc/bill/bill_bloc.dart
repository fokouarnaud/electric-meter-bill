import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/bill.dart';
import '../../../domain/repositories/bill_repository.dart';
import 'bill_event.dart';
import 'bill_state.dart';

class BillBloc extends Bloc<BillEvent, BillState> {
  final BillRepository repository;

  BillBloc({required this.repository}) : super(const BillInitial()) {
    on<LoadBills>(_onLoadBills);
    on<AddBill>(_onAddBill);
    on<UpdateBill>(_onUpdateBill);
    on<DeleteBill>(_onDeleteBill);
    on<UpdateBillPaymentStatus>(_onUpdateBillPaymentStatus);
    on<RefreshBills>(_onRefreshBills);
  }

  Future<void> _onLoadBills(LoadBills event, Emitter<BillState> emit) async {
    try {
      emit(const BillLoading());
      final bills = await repository.getBills(event.meterId);
      final totalAmount = await repository.getTotalAmount(event.meterId);
      final unpaidAmount = await repository.getUnpaidAmount(event.meterId);
      final unpaidBills = await repository.getUnpaidBills(event.meterId);

      emit(BillsLoaded(
        bills: bills,
        totalBills: bills.length,
        unpaidBills: unpaidBills.length,
        totalAmount: totalAmount,
        unpaidAmount: unpaidAmount,
      ));
    } catch (e) {
      emit(BillError(e.toString()));
    }
  }

  Future<void> _onAddBill(AddBill event, Emitter<BillState> emit) async {
    try {
      emit(const BillLoading());
      await repository.addBill(event.bill);
      final bills = await repository.getBills(event.bill.meterId);
      final totalAmount = await repository.getTotalAmount(event.bill.meterId);
      final unpaidAmount = await repository.getUnpaidAmount(event.bill.meterId);
      final unpaidBills = await repository.getUnpaidBills(event.bill.meterId);

      emit(const BillOperationSuccess('Bill added successfully'));
      emit(BillsLoaded(
        bills: bills,
        totalBills: bills.length,
        unpaidBills: unpaidBills.length,
        totalAmount: totalAmount,
        unpaidAmount: unpaidAmount,
      ));
    } catch (e) {
      emit(BillError(e.toString()));
    }
  }

  Future<void> _onUpdateBill(UpdateBill event, Emitter<BillState> emit) async {
    try {
      emit(const BillLoading());
      await repository.updateBill(event.bill);
      final bills = await repository.getBills(event.bill.meterId);
      final totalAmount = await repository.getTotalAmount(event.bill.meterId);
      final unpaidAmount = await repository.getUnpaidAmount(event.bill.meterId);
      final unpaidBills = await repository.getUnpaidBills(event.bill.meterId);

      emit(const BillOperationSuccess('Bill updated successfully'));
      emit(BillsLoaded(
        bills: bills,
        totalBills: bills.length,
        unpaidBills: unpaidBills.length,
        totalAmount: totalAmount,
        unpaidAmount: unpaidAmount,
      ));
    } catch (e) {
      emit(BillError(e.toString()));
    }
  }

  Future<void> _onDeleteBill(DeleteBill event, Emitter<BillState> emit) async {
    try {
      emit(const BillLoading());

      // Get the current state to access meterId
      if (state is BillsLoaded) {
        final currentState = state as BillsLoaded;
        final bills = currentState.bills;
        final meterId = bills.firstWhere((b) => b.id == event.id).meterId;

        await repository.deleteBill(event.id);
        final updatedBills = await repository.getBills(meterId);
        final totalAmount = await repository.getTotalAmount(meterId);
        final unpaidAmount = await repository.getUnpaidAmount(meterId);
        final unpaidBills = await repository.getUnpaidBills(meterId);

        emit(const BillOperationSuccess('Bill deleted successfully'));
        emit(BillsLoaded(
          bills: updatedBills,
          totalBills: updatedBills.length,
          unpaidBills: unpaidBills.length,
          totalAmount: totalAmount,
          unpaidAmount: unpaidAmount,
        ));
      }
    } catch (e) {
      emit(BillError(e.toString()));
    }
  }

  Future<void> _onUpdateBillPaymentStatus(
    UpdateBillPaymentStatus event,
    Emitter<BillState> emit,
  ) async {
    try {
      emit(const BillLoading());
      final updatedBill = event.bill.copyWith(isPaid: event.isPaid);
      await repository.updateBill(updatedBill);
      final bills = await repository.getBills(event.bill.meterId);
      final totalAmount = await repository.getTotalAmount(event.bill.meterId);
      final unpaidAmount = await repository.getUnpaidAmount(event.bill.meterId);
      final unpaidBills = await repository.getUnpaidBills(event.bill.meterId);

      emit(const BillOperationSuccess('Payment status updated successfully'));
      emit(BillsLoaded(
        bills: bills,
        totalBills: bills.length,
        unpaidBills: unpaidBills.length,
        totalAmount: totalAmount,
        unpaidAmount: unpaidAmount,
      ));
    } catch (e) {
      emit(BillError(e.toString()));
    }
  }

  Future<void> _onRefreshBills(
      RefreshBills event, Emitter<BillState> emit) async {
    try {
      final bills = await repository.getBills(event.meterId);
      final totalAmount = await repository.getTotalAmount(event.meterId);
      final unpaidAmount = await repository.getUnpaidAmount(event.meterId);
      final unpaidBills = await repository.getUnpaidBills(event.meterId);

      emit(BillsLoaded(
        bills: bills,
        totalBills: bills.length,
        unpaidBills: unpaidBills.length,
        totalAmount: totalAmount,
        unpaidAmount: unpaidAmount,
      ));
    } catch (e) {
      emit(BillError(e.toString()));
    }
  }
}
