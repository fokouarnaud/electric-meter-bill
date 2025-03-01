import '../../../domain/entities/bill.dart';

abstract class BillEvent {
  const BillEvent();
}

class LoadBills extends BillEvent {
  final String meterId;

  const LoadBills(this.meterId);
}

class AddBill extends BillEvent {
  final Bill bill;

  const AddBill(this.bill);
}

class UpdateBill extends BillEvent {
  final Bill bill;

  const UpdateBill(this.bill);
}

class DeleteBill extends BillEvent {
  final String id;

  const DeleteBill(this.id);
}

class UpdateBillPaymentStatus extends BillEvent {
  final Bill bill;
  final bool isPaid;

  const UpdateBillPaymentStatus({
    required this.bill,
    required this.isPaid,
  });
}

class RefreshBills extends BillEvent {
  final String meterId;

  const RefreshBills(this.meterId);
}
