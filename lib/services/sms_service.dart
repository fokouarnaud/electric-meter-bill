import 'package:url_launcher/url_launcher.dart';
import '../domain/entities/bill.dart';
import '../domain/entities/meter.dart';

class SmsService {
  static Future<void> sendBillSms({
    required Bill bill,
    required Meter meter,
    required String phoneNumber,
  }) async {
    final message = _formatBillMessage(bill, meter);
    final uri =
        Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch SMS app');
    }
  }

  static Future<void> sendBulkBillSms({
    required List<Bill> bills,
    required Meter meter,
    required String phoneNumber,
  }) async {
    final message = _formatBulkBillsMessage(bills, meter);
    final uri =
        Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch SMS app');
    }
  }

  static String _formatBillMessage(Bill bill, Meter meter) {
    final startDate = _formatDate(bill.startDate);
    final endDate = _formatDate(bill.endDate);
    final dueDate = _formatDate(bill.dueDate);

    return '''
Dear ${meter.clientName},

Your electricity bill for meter ${meter.name} is ready:

Period: $startDate - $endDate
Consumption: ${bill.consumption.toStringAsFixed(2)} kWh
Amount: €${bill.amount.toStringAsFixed(2)}

Due date: $dueDate

Location: ${meter.location}
''';
  }

  static String _formatBulkBillsMessage(List<Bill> bills, Meter meter) {
    final totalAmount = bills.fold(0.0, (sum, bill) => sum + bill.amount);
    final totalConsumption =
        bills.fold(0.0, (sum, bill) => sum + bill.consumption);

    return '''
Dear ${meter.clientName},

You have ${bills.length} unpaid electricity bills for meter ${meter.name}:

Total consumption: ${totalConsumption.toStringAsFixed(2)} kWh
Total amount due: €${totalAmount.toStringAsFixed(2)}

Location: ${meter.location}

Please contact us for payment arrangements.
''';
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
