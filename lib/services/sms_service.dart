import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/entities/bill.dart';
import '../domain/entities/meter.dart';
import '../domain/entities/currency.dart';

class SmsService {
  static Future<void> sendBillSms({
    required Bill bill,
    required Meter meter,
    required String phoneNumber,
    required BuildContext context,
    required Currency currency,
  }) async {
    final message = _formatBillMessage(context, bill, meter, currency);
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
    required BuildContext context,
    required Currency currency,
  }) async {
    final message = _formatBulkBillsMessage(context, bills, meter, currency);
    final uri =
        Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch SMS app');
    }
  }

 static String _formatBillMessage(BuildContext context, Bill bill, Meter meter, Currency currency) {
    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // Use the localization directly with all parameters
    return l10n.smsSingleBillMessage(
      meter.clientName,
      meter.name,
      dateFormat.format(bill.startDate),
      dateFormat.format(bill.endDate),
      numberFormat.format(bill.consumption),
      '${numberFormat.format(bill.amount)} ${currency.symbol}', // Use the currency symbol
      dateFormat.format(bill.dueDate),
      meter.location,
    );
  }

  static String _formatBulkBillsMessage(BuildContext context, List<Bill> bills, Meter meter, Currency currency) {
    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat('#,##0.00');
    
    final totalAmount = bills.fold(0.0, (sum, bill) => sum + bill.amount);
    final totalConsumption = bills.fold(0.0, (sum, bill) => sum + bill.consumption);

    // Use the localization directly with all parameters
    return l10n.smsBulkBillsMessage(
      meter.clientName,
      bills.length.toString(),
      meter.name,
      numberFormat.format(totalConsumption),
     '${numberFormat.format(totalAmount)}${currency.symbol}',
      meter.location,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
