import '../entities/bill.dart';

abstract class BillRepository {
  Future<List<Bill>> getBills(String meterId);
  Future<Bill?> getBillById(String id);
  Future<void> addBill(Bill bill);
  Future<void> updateBill(Bill bill);
  Future<void> deleteBill(String id);
  Future<bool> billExists(String id);
  Future<int> getBillCount(String meterId);
  Future<List<Bill>> getUnpaidBills(String meterId);
  Future<double> getTotalAmount(String meterId);
  Future<double> getUnpaidAmount(String meterId);
  Future<List<Bill>> getBillsForPeriod({
    required String meterId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<void> updatePaymentStatus({
    required String billId,
    required bool isPaid,
  });
}
