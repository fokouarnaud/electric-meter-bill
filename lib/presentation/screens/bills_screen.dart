//presentation/screens/bills_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
      child: BlocListener<BillBloc, BillState>(
        listener: (context, state) {
          if (state is BillError) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n?.error ?? "Error"}: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
           title: Builder(
             builder: (context) {
               final l10n = AppLocalizations.of(context);
               return Text('${l10n?.bills ?? "Bills"} - ${meter.name}');
             },
           ),
            actions: [
              BlocBuilder<BillBloc, BillState>(
                builder: (context, state) {
                  if (state is BillsLoaded && state.bills.isNotEmpty) {
                    final l10n = AppLocalizations.of(context);
                    return PopupMenuButton<int>(
                      tooltip: l10n?.bills ?? 'Bill Actions',
                      onSelected: (value) {
                        if (context.mounted) {
                          switch (value) {
                            case 0:
                              _showCommunicationDialog(context, state.bills, isBulk: true);
                              break;
                            case 1:
                              _showCommunicationDialog(
                                context,
                                state.bills.where((b) => !b.isPaid).toList(),
                                isBulk: true,
                              );
                              break;
                          }
                        }
                      },
                      itemBuilder: (context) => <PopupMenuItem<int>>[
                        PopupMenuItem<int>(
                          value: 0,
                          child: Text(l10n?.sendAllBills ?? 'Send All Bills'),
                        ),
                        PopupMenuItem<int>(
                          value: 1,
                          child: Text(l10n?.sendUnpaidBills ?? 'Send Unpaid Bills'),
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
                    _buildStatisticsCard(context, state),
                    Expanded(child: _buildBillsList(context, state.bills)),
                  ],
                );
              } else if (state is BillError) {
               final l10n = AppLocalizations.of(context);
               return Center(
                 child: Text('${l10n?.error ?? "Error"}: ${state.message}')
               );
             }
             final l10n = AppLocalizations.of(context);
             return Center(
               child: Text(l10n?.noBillsAvailable ?? 'No bills available')
             );
            },
          ),
          floatingActionButton:
              BlocBuilder<MeterReadingBloc, MeterReadingState>(
            builder: (context, state) {
              if (state is MeterReadingsLoaded && state.readings.length >= 2) {
                return FloatingActionButton(
                  onPressed: () {
                    if (context.mounted) {
                      _showGenerateBillDialog(context, state.readings);
                    }
                  },
                  tooltip: AppLocalizations.of(context)?.generateBill ?? 'Generate New Bill',
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

  Widget _buildStatisticsCard(BuildContext context, BillsLoaded state) {
    final l10n = AppLocalizations.of(context);
    final numberFormat = NumberFormat('#,##0.00');
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.billingSummary ?? 'Billing Summary',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  l10n?.totalAmount ?? 'Total Amount',
                  l10n?.formattedAmount(numberFormat.format(state.totalAmount)) ??
                  '${numberFormat.format(state.totalAmount)} FCFA',
                  Colors.blue,
                ),
                _buildStatItem(
                  l10n?.unpaidAmount ?? 'Unpaid Amount',
                  l10n?.formattedAmount(numberFormat.format(state.unpaidAmount)) ??
                  '${numberFormat.format(state.unpaidAmount)} FCFA',
                  Colors.red,
                ),
                _buildStatItem(
                  l10n?.unpaidBillsCount ?? 'Unpaid Bills',
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
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');

    return ListView.separated(
      itemCount: bills.length,
      padding: const EdgeInsets.all(8.0),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final bill = bills[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: bill.isPaid ? Colors.green : Colors.red,
              child: Icon(
                bill.isPaid ? Icons.check : Icons.pending,
                color: Colors.white,
              ),
            ),
            title: Text(
              l10n?.formattedAmount(numberFormat.format(bill.amount)) ??
              '${numberFormat.format(bill.amount)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n?.period ?? "Period"}: ${dateFormat.format(bill.startDate)} - ${dateFormat.format(bill.endDate)}',
                ),
                Text(
                  '${l10n?.consumption ?? "Consumption"}: ${numberFormat.format(bill.consumption)} ${l10n?.kWh ?? "kWh"}',
                ),
                if (bill.notes != null && bill.notes!.isNotEmpty)
                  Text('${l10n?.notes ?? "Notes"}: ${bill.notes}'),
              ],
            ),
            trailing: PopupMenuButton<int>(
              tooltip: l10n?.billActions ?? 'Bill Actions',
              onSelected: (value) {
                if (context.mounted) {
                  switch (value) {
                    case 0:
                      context.read<BillBloc>().add(UpdateBillPaymentStatus(
                        bill: bill,
                        isPaid: !bill.isPaid,
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                          !bill.isPaid ?
                            (l10n?.markAsPaid ?? 'Marked as paid') :
                            (l10n?.markAsUnpaid ?? 'Marked as unpaid')
                        ),
                        backgroundColor: !bill.isPaid ? Colors.green : Colors.orange,
                        duration: const Duration(seconds: 2),
                      ));
                      break;
                    case 1:
                      _showCommunicationDialog(context, [bill]);
                      break;
                    case 2:
                      _showDeleteBillDialog(context, bill);
                      break;
                  }
                }
              },
              itemBuilder: (context) => <PopupMenuItem<int>>[
                PopupMenuItem<int>(
                  value: 0,
                  child: Text(bill.isPaid ?
                    l10n?.markAsUnpaid ?? 'Mark as Unpaid' :
                    l10n?.markAsPaid ?? 'Mark as Paid'
                  ),
                ),
                PopupMenuItem<int>(
                  value: 1,
                  child: Text(l10n?.sendBill ?? 'Send Bill'),
                ),
                PopupMenuItem<int>(
                  value: 2,
                  child: Text(l10n?.delete ?? 'Delete'),
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.deleteBill ?? 'Delete Bill'),
        content: Text(
          l10n?.deleteBillConfirmation ??
          'Are you sure you want to delete this bill? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Afficher un indicateur de chargement
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        // Supprimer la facture
        context.read<BillBloc>().add(DeleteBill(bill.id));

        // Attendre un court instant pour la suppression
        await Future.delayed(const Duration(milliseconds: 500));

        // Fermer l'indicateur de chargement
        if (context.mounted) {
          Navigator.pop(context);
          
          // Afficher le message de confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.billDeleted ?? 'Bill deleted'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // En cas d'erreur, afficher un message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.actionError ?? 'Error deleting bill'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _showGenerateBillDialog(
      BuildContext context, List<MeterReading> readings) {
    final l10n = AppLocalizations.of(context);
    final numberFormat = NumberFormat('#,##0.00');
    final currentReading = readings[0];
    final previousReading = readings[1];
    final dateFormat = DateFormat('dd/MM/yyyy');
    final consumption = currentReading.value - previousReading.value;
    
    if (consumption < 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n?.error ?? 'Error'),
          content: Text(l10n?.invalidPrice ?? 'Invalid value: current reading must be greater than previous reading'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n?.ok ?? 'OK'),
            ),
          ],
        ),
      );
      return;
    }

    final amount = consumption * meter.pricePerKwh;
    final billBloc = context.read<BillBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.generateBill ?? 'Generate New Bill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n?.currentReading ?? "Current Reading"} (${dateFormat.format(currentReading.readingDate)}): ' +
              (l10n?.consumptionFormat(numberFormat.format(currentReading.value), l10n?.kWh ?? "kWh") ??
              "${numberFormat.format(currentReading.value)} kWh")),
            Text('${l10n?.previousReading ?? "Previous Reading"} (${dateFormat.format(previousReading.readingDate)}): ' +
              (l10n?.consumptionFormat(numberFormat.format(previousReading.value), l10n?.kWh ?? "kWh") ??
              "${numberFormat.format(previousReading.value)} kWh")),
            const SizedBox(height: 16),
            Text(
              '${l10n?.consumption ?? "Consumption"}: ' +
              (l10n?.consumptionFormat(numberFormat.format(consumption), l10n?.kWh ?? "kWh") ??
              "${numberFormat.format(consumption)} kWh"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${l10n?.amount ?? "Amount"}: ' +
              (l10n?.formattedAmount(numberFormat.format(amount)) ??
              "${numberFormat.format(amount)} FCFA"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n?.cancel ?? 'Cancel'),
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
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n?.billGenerated ?? 'Bill generated'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(l10n?.generateBill ?? 'Generate'),
          ),
        ],
      ),
    );
  }
}
