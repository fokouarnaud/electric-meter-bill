import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/bill_model.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/meter.dart';
import '../../domain/entities/meter_reading.dart';
import '../../injection.dart';
import '../bloc/bill/bill_bloc.dart';
import '../bloc/bill/bill_event.dart';
import '../bloc/bill/bill_state.dart';
import '../bloc/meter_reading/meter_reading_bloc.dart';
import '../bloc/meter_reading/meter_reading_event.dart';
import '../bloc/meter_reading/meter_reading_state.dart';
import '../widgets/communication_dialog.dart';

class BillsScreen extends StatelessWidget {
  final Meter meter;

  const BillsScreen({
    super.key,
    required this.meter,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<BillBloc>()..add(LoadBills(meter.id)),
        ),
        BlocProvider(
          create: (context) =>
              getIt<MeterReadingBloc>()..add(LoadMeterReadings(meter.id)),
        ),
      ],
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Bills - ${meter.name}'),
            actions: [
              BlocBuilder<BillBloc, BillState>(
                builder: (context, state) {
                  if (state is BillsLoaded && state.bills.isNotEmpty) {
                    return PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Send All Bills'),
                          onTap: () => _showCommunicationDialog(
                            context,
                            state.bills,
                            isBulk: true,
                          ),
                        ),
                        PopupMenuItem(
                          child: const Text('Send Unpaid Bills'),
                          onTap: () => _showCommunicationDialog(
                            context,
                            state.bills.where((b) => !b.isPaid).toList(),
                            isBulk: true,
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          body: BlocBuilder<BillBloc, BillState>(
            builder: (context, state) {
              if (state is BillLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is BillsLoaded) {
                return Column(
                  children: [
                    _buildStatisticsCard(state),
                    Expanded(child: _buildBillsList(context, state.bills)),
                  ],
                );
              } else if (state is BillError) {
                return Center(child: Text('Error: ${state.message}'));
              }
              return const Center(child: Text('No bills available'));
            },
          ),
          floatingActionButton:
              BlocBuilder<MeterReadingBloc, MeterReadingState>(
            builder: (context, state) {
              if (state is MeterReadingsLoaded && state.readings.length >= 2) {
                return FloatingActionButton(
                  onPressed: () =>
                      _showGenerateBillDialog(context, state.readings),
                  child: const Icon(Icons.add),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(BillsLoaded state) {
    final numberFormat = NumberFormat('#,##0.00');
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Billing Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Total Amount',
                  '${numberFormat.format(state.totalAmount)} €',
                  Colors.blue,
                ),
                _buildStatItem(
                  'Unpaid Amount',
                  '${numberFormat.format(state.unpaidAmount)} €',
                  Colors.red,
                ),
                _buildStatItem(
                  'Unpaid Bills',
                  '${state.unpaidBills}/${state.totalBills}',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBillsList(BuildContext context, List<Bill> bills) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    return ListView.builder(
      itemCount: bills.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final bill = bills[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: bill.isPaid ? Colors.green : Colors.red,
              child: Icon(
                bill.isPaid ? Icons.check : Icons.pending,
                color: Colors.white,
              ),
            ),
            title: Text(
              '${numberFormat.format(bill.amount)} €',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Period: ${dateFormat.format(bill.startDate)} - ${dateFormat.format(bill.endDate)}',
                ),
                Text(
                  'Consumption: ${numberFormat.format(bill.consumption)} kWh',
                ),
                if (bill.notes != null && bill.notes!.isNotEmpty)
                  Text('Notes: ${bill.notes}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text(bill.isPaid ? 'Mark as Unpaid' : 'Mark as Paid'),
                  onTap: () {
                    context.read<BillBloc>().add(
                          UpdateBillPaymentStatus(
                            bill: bill,
                            isPaid: !bill.isPaid,
                          ),
                        );
                  },
                ),
                PopupMenuItem(
                  child: const Text('Send Bill'),
                  onTap: () => _showCommunicationDialog(context, [bill]),
                ),
                PopupMenuItem(
                  child: const Text('Delete'),
                  onTap: () => _showDeleteBillDialog(context, bill),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCommunicationDialog(
    BuildContext context,
    List<Bill> bills, {
    bool isBulk = false,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => CommunicationDialog(
        bills: bills,
        meter: meter,
        isBulk: isBulk,
      ),
    );
  }

  Future<void> _showDeleteBillDialog(BuildContext context, Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: const Text(
          'Are you sure you want to delete this bill? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<BillBloc>().add(DeleteBill(bill.id));
    }
  }

  void _showGenerateBillDialog(
      BuildContext context, List<MeterReading> readings) {
    final currentReading = readings[0];
    final previousReading = readings[1];
    final consumption = currentReading.value - previousReading.value;
    final amount = consumption * meter.pricePerKwh;
    final billBloc = context.read<BillBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Generate New Bill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latest Reading: ${currentReading.value} kWh'),
            Text('Previous Reading: ${previousReading.value} kWh'),
            const SizedBox(height: 16),
            Text(
              'Consumption: $consumption kWh',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Amount: $amount €',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              final bill = BillModel(
                id: now.millisecondsSinceEpoch.toString(),
                meterId: meter.id,
                clientName: meter.clientName,
                previousReading: previousReading.value,
                currentReading: currentReading.value,
                consumption: consumption,
                amount: amount,
                startDate: previousReading.readingDate,
                endDate: currentReading.readingDate,
                generatedDate: now,
                date: now,
                dueDate: now.add(const Duration(days: 30)),
                isPaid: false,
                createdAt: now,
              );
              billBloc.add(AddBill(bill));
              Navigator.pop(dialogContext);
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}
