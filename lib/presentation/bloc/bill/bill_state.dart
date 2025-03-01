import '../../../domain/entities/bill.dart';

abstract class BillState {
  const BillState();
}

class BillInitial extends BillState {
  const BillInitial();
}

class BillLoading extends BillState {
  const BillLoading();
}

class BillsLoaded extends BillState {
  final List<Bill> bills;
  final int totalBills;
  final int unpaidBills;
  final double totalAmount;
  final double unpaidAmount;

  const BillsLoaded({
    required this.bills,
    required this.totalBills,
    required this.unpaidBills,
    required this.totalAmount,
    required this.unpaidAmount,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BillsLoaded &&
        other.bills == bills &&
        other.totalBills == totalBills &&
        other.unpaidBills == unpaidBills &&
        other.totalAmount == totalAmount &&
        other.unpaidAmount == unpaidAmount;
  }

  @override
  int get hashCode {
    return bills.hashCode ^
        totalBills.hashCode ^
        unpaidBills.hashCode ^
        totalAmount.hashCode ^
        unpaidAmount.hashCode;
  }
}

class BillError extends BillState {
  final String message;

  const BillError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BillError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class BillOperationSuccess extends BillState {
  final String message;

  const BillOperationSuccess(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BillOperationSuccess && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
