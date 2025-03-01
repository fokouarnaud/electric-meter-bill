import 'dart:io';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:intl/intl.dart';
import '../domain/entities/bill.dart';
import '../domain/entities/meter.dart';
import 'pdf_service.dart';

class EmailService {
  static Future<void> sendBillEmail({
    required Bill bill,
    required Meter meter,
    required String recipientEmail,
  }) async {
    try {
      // Generate PDF
      final pdfFile = await PdfService.generateBillPdf(bill, meter);

      // Prepare email
      final dateFormat = DateFormat('dd/MM/yyyy');
      final currencyFormat =
          NumberFormat.currency(symbol: '€', locale: 'fr_FR');

      final email = Email(
        subject:
            'Electric Meter Bill - ${meter.clientName} - ${dateFormat.format(bill.date)}',
        body: '''
Dear ${meter.clientName},

Please find attached your electric meter bill for the period ${dateFormat.format(bill.startDate)} to ${dateFormat.format(bill.endDate)}.

Bill Details:
- Meter Location: ${meter.location}
- Consumption: ${bill.consumption} kWh
- Amount: ${currencyFormat.format(bill.amount)}
- Due Date: ${dateFormat.format(bill.dueDate)}

If you have any questions, please don't hesitate to contact us.

Best regards,
Electric Meter Billing System
''',
        recipients: [recipientEmail],
        attachmentPaths: [pdfFile.path],
        isHTML: false,
      );

      // Send email
      await FlutterEmailSender.send(email);
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  static Future<void> sendBulkBillEmails({
    required List<Bill> bills,
    required Meter meter,
    required String recipientEmail,
  }) async {
    try {
      // Generate bulk PDF
      final pdfFile = await PdfService.generateBulkBillsPdf(bills, meter);

      // Calculate totals
      final totalConsumption = bills.fold<double>(
        0,
        (sum, bill) => sum + bill.consumption,
      );
      final totalAmount = bills.fold<double>(
        0,
        (sum, bill) => sum + bill.amount,
      );
      final unpaidAmount = bills
          .where((bill) => !bill.isPaid)
          .fold<double>(0, (sum, bill) => sum + bill.amount);

      // Prepare email
      final dateFormat = DateFormat('dd/MM/yyyy');
      final currencyFormat =
          NumberFormat.currency(symbol: '€', locale: 'fr_FR');
      final numberFormat = NumberFormat('#,##0.00');

      final email = Email(
        subject: 'Electric Meter Bills - ${meter.clientName}',
        body: '''
Dear ${meter.clientName},

Please find attached your electric meter bills.

Summary:
- Total Bills: ${bills.length}
- Total Consumption: ${numberFormat.format(totalConsumption)} kWh
- Total Amount: ${currencyFormat.format(totalAmount)}
- Unpaid Amount: ${currencyFormat.format(unpaidAmount)}

Meter Details:
- Location: ${meter.location}
- Meter ID: ${meter.id}

If you have any questions, please don't hesitate to contact us.

Best regards,
Electric Meter Billing System
''',
        recipients: [recipientEmail],
        attachmentPaths: [pdfFile.path],
        isHTML: false,
      );

      // Send email
      await FlutterEmailSender.send(email);
    } catch (e) {
      throw Exception('Failed to send bulk emails: $e');
    }
  }

  static Future<void> sendMonthlyReport({
    required Meter meter,
    required List<Bill> bills,
    required DateTime startDate,
    required DateTime endDate,
    required String recipientEmail,
  }) async {
    try {
      // Calculate totals
      final totalConsumption = bills.fold<double>(
        0,
        (sum, bill) => sum + bill.consumption,
      );
      final totalAmount = bills.fold<double>(
        0,
        (sum, bill) => sum + bill.amount,
      );

      // Generate report PDF
      final pdfFile = await PdfService.generateMonthlyReport(
        meter: meter,
        bills: bills,
        startDate: startDate,
        endDate: endDate,
        totalConsumption: totalConsumption,
        totalAmount: totalAmount,
      );

      // Prepare email
      final dateFormat = DateFormat('dd/MM/yyyy');
      final currencyFormat =
          NumberFormat.currency(symbol: '€', locale: 'fr_FR');
      final numberFormat = NumberFormat('#,##0.00');

      final email = Email(
        subject:
            'Monthly Consumption Report - ${meter.clientName} - ${dateFormat.format(startDate)}',
        body: '''
Dear ${meter.clientName},

Please find attached your monthly consumption report for the period ${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}.

Summary:
- Total Consumption: ${numberFormat.format(totalConsumption)} kWh
- Total Amount: ${currencyFormat.format(totalAmount)}
- Number of Bills: ${bills.length}

Meter Details:
- Location: ${meter.location}
- Meter ID: ${meter.id}

If you have any questions, please don't hesitate to contact us.

Best regards,
Electric Meter Billing System
''',
        recipients: [recipientEmail],
        attachmentPaths: [pdfFile.path],
        isHTML: false,
      );

      // Send email
      await FlutterEmailSender.send(email);
    } catch (e) {
      throw Exception('Failed to send monthly report: $e');
    }
  }
}
