import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../domain/entities/bill.dart';
import '../domain/entities/meter.dart';
import 'pdf_widgets.dart';

class PdfService {
  static Future<File> generateBillPdf(Bill bill, Meter meter) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          PDFWidgets.buildHeader('Electric Meter Bill'),
          pw.SizedBox(height: 20),
          PDFWidgets.buildCompanyInfo(),
          pw.SizedBox(height: 20),
          PDFWidgets.buildClientInfo(meter),
          pw.SizedBox(height: 20),
          PDFWidgets.buildBillDetails(bill),
          pw.SizedBox(height: 20),
          PDFWidgets.buildConsumptionDetails(bill),
          pw.SizedBox(height: 20),
          PDFWidgets.buildTotalSection(bill),
          if (bill.notes != null && bill.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            PDFWidgets.buildNotes(bill),
          ],
          pw.SizedBox(height: 40),
          PDFWidgets.buildFooter(),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/bill_${bill.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> previewPdf(File file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception('Could not open PDF: ${result.message}');
    }
  }

  static Future<void> sharePdf(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Electric Meter Bill',
    );
  }

  static Future<File> generateBulkBillsPdf(
      List<Bill> bills, Meter meter) async {
    final pdf = pw.Document();

    for (var i = 0; i < bills.length; i++) {
      final bill = bills[i];
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            PDFWidgets.buildHeader('Electric Meter Bill'),
            pw.SizedBox(height: 20),
            PDFWidgets.buildCompanyInfo(),
            pw.SizedBox(height: 20),
            PDFWidgets.buildClientInfo(meter),
            pw.SizedBox(height: 20),
            PDFWidgets.buildBillDetails(bill),
            pw.SizedBox(height: 20),
            PDFWidgets.buildConsumptionDetails(bill),
            pw.SizedBox(height: 20),
            PDFWidgets.buildTotalSection(bill),
            if (bill.notes != null && bill.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              PDFWidgets.buildNotes(bill),
            ],
            pw.SizedBox(height: 40),
            PDFWidgets.buildFooter(),
          ],
        ),
      );

      // Add a page break between bills, except for the last one
      if (i < bills.length - 1) {
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Container(),
        ));
      }
    }

    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/bills_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> generateMonthlyReport({
    required Meter meter,
    required List<Bill> bills,
    required DateTime startDate,
    required DateTime endDate,
    required double totalConsumption,
    required double totalAmount,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          PDFWidgets.buildHeader('Monthly Consumption Report'),
          pw.SizedBox(height: 20),
          PDFWidgets.buildCompanyInfo(),
          pw.SizedBox(height: 20),
          PDFWidgets.buildClientInfo(meter),
          pw.SizedBox(height: 20),
          _buildMonthlyReportDetails(
            startDate: startDate,
            endDate: endDate,
            totalConsumption: totalConsumption,
            totalAmount: totalAmount,
          ),
          pw.SizedBox(height: 20),
          _buildBillsTable(bills),
          pw.SizedBox(height: 40),
          PDFWidgets.buildFooter(),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildMonthlyReportDetails({
    required DateTime startDate,
    required DateTime endDate,
    required double totalConsumption,
    required double totalAmount,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');
    final currencyFormat = NumberFormat.currency(symbol: '€', locale: 'fr_FR');

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Report Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Period:'),
              pw.Text(
                '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Consumption:'),
              pw.Text('${numberFormat.format(totalConsumption)} kWh'),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Amount:'),
              pw.Text(currencyFormat.format(totalAmount)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBillsTable(List<Bill> bills) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');
    final currencyFormat = NumberFormat.currency(symbol: '€', locale: 'fr_FR');

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
          ),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Consumption (kWh)', isHeader: true),
            _buildTableCell('Amount', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        // Data rows
        ...bills.map((bill) => pw.TableRow(
              children: [
                _buildTableCell(dateFormat.format(bill.date)),
                _buildTableCell(numberFormat.format(bill.consumption)),
                _buildTableCell(currencyFormat.format(bill.amount)),
                _buildTableCell(
                  bill.isPaid ? 'Paid' : 'Unpaid',
                  textColor: bill.isPaid ? PdfColors.green : PdfColors.red,
                ),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          color: textColor,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
