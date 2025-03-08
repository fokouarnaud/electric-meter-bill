// lib/presentation/screens/bills_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
import '../widgets/common_widgets.dart';
import '../widgets/communication_dialog.dart';
import '../bloc/currency/currency_bloc.dart';

class BillsScreen extends StatefulWidget {
  final Meter meter;

  const BillsScreen({
    super.key,
    required this.meter,
  });

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedFilter = 'all'; // 'all', 'paid', 'unpaid'
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedFilter = 'all';
            break;
          case 1:
            _selectedFilter = 'unpaid';
            break;
          case 2:
            _selectedFilter = 'paid';
            break;
        }
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<BillBloc>()..add(LoadBills(widget.meter.id)),
        ),
        BlocProvider(
          create: (context) => getIt<MeterReadingBloc>()..add(LoadMeterReadings(widget.meter.id)),
        ),
      ],
      child: BlocListener<BillBloc, BillState>(
        listener: _handleBillStateChanges,
        child: Scaffold(
          appBar: _buildAppBar(l10n),
          body: BlocBuilder<BillBloc, BillState>(
            builder: (context, state) {
              if (state is BillLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is BillsLoaded) {
                final filteredBills = _filterBills(state.bills);
                
                if (filteredBills.isEmpty) {
                  return _buildEmptyState(context, state);
                }
                
                return Column(
                  children: [
                    _buildBillingSummaryCard(context, state),
                    Expanded(child: _buildEnhancedBillsList(context, filteredBills)),
                  ],
                );
              } else if (state is BillError) {
                return _buildErrorState(context, state.message, l10n);
              }
              
              return Center(
                child: Text(l10n?.noBillsAvailable ?? 'No bills available'),
              );
            },
          ),
          floatingActionButton: _buildFloatingActionButton(),
        ),
      ),
    );
  }

  void _handleBillStateChanges(BuildContext context, BillState state) {
    final l10n = AppLocalizations.of(context);
    
    if (state is BillError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n?.error ?? "Error"}: ${state.message}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (state is BillOperationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  PreferredSizeWidget _buildAppBar(AppLocalizations? l10n) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n?.bills ?? 'Bills'),
          Text(
            widget.meter.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: l10n?.all ?? 'All'),
          Tab(text: l10n?.unpaid ?? 'Unpaid'),
          Tab(text: l10n?.paid ?? 'Paid'),
        ],
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).colorScheme.primary,
      ),
      actions: [
        BlocBuilder<BillBloc, BillState>(
          builder: (context, state) {
            if (state is BillsLoaded && state.bills.isNotEmpty) {
              return _buildBillActionsMenu(context, state.bills, l10n);
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
  
  Widget _buildBillActionsMenu(BuildContext context, List<Bill> bills, AppLocalizations? l10n) {
    return PopupMenuButton<String>(
      tooltip: l10n?.billActions ?? 'Bill Actions',
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (context.mounted) {
          switch (value) {
            case 'send_all':
              _showCommunicationDialog(context, bills, isBulk: true);
              break;
            case 'send_unpaid':
              _showCommunicationDialog(
                context,
                bills.where((b) => !b.isPaid).toList(),
                isBulk: true,
              );
              break;
          }
        }
      },
      itemBuilder: (context) => <PopupMenuItem<String>>[
        PopupMenuItem<String>(
          value: 'send_all',
          child: Row(
            children: [
              const Icon(Icons.send, size: 20),
              const SizedBox(width: 8),
              Text(l10n?.sendAllBills ?? 'Send All Bills'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'send_unpaid',
          child: Row(
            children: [
              const Icon(Icons.send, size: 20),
              const SizedBox(width: 8),
              Text(l10n?.sendUnpaidBills ?? 'Send Unpaid Bills'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFloatingActionButton() {
    return BlocBuilder<MeterReadingBloc, MeterReadingState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        if (state is MeterReadingsLoaded && state.readings.length >= 2) {
          return FloatingActionButton.extended(
            onPressed: () => _showGenerateBillDialog(context, state.readings),
            tooltip: l10n?.generateBill ?? 'Generate New Bill',
            icon: const Icon(Icons.add),
            label: Text(l10n?.generateBill ?? 'Generate Bill'),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  List<Bill> _filterBills(List<Bill> bills) {
    switch (_selectedFilter) {
      case 'paid':
        return bills.where((bill) => bill.isPaid).toList();
      case 'unpaid':
        return bills.where((bill) => !bill.isPaid).toList();
      case 'all':
      default:
        return bills;
    }
  }

  Widget _buildErrorState(BuildContext context, String message, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            '${l10n?.error ?? "Error"}: $message',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(l10n?.tryAgain ?? "Try Again"),
            onPressed: () {
              context.read<BillBloc>().add(LoadBills(widget.meter.id));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, BillsLoaded state) {
    final l10n = AppLocalizations.of(context);
    
    String message;
    String buttonText;
    VoidCallback? action;
    
    // Different messages based on filter and state
    switch (_selectedFilter) {
      case 'paid':
        message = l10n?.noPaidBills ?? 'No paid bills';
        buttonText = l10n?.viewAllBills ?? 'View All Bills';
        action = () => _tabController.animateTo(0); // Go to "All"
        break;
      case 'unpaid':
        message = l10n?.noUnpaidBills ?? 'No unpaid bills';
        buttonText = l10n?.viewAllBills ?? 'View All Bills';
        action = () => _tabController.animateTo(0); // Go to "All"
        break;
      case 'all':
      default:
        message = l10n?.noBillsAvailable ?? 'No bills available';
        buttonText = l10n?.generateFirstBill ?? 'Generate Your First Bill';
        
        // Check if we can generate a bill
        final meterReadingState = context.read<MeterReadingBloc>().state;
        if (meterReadingState is MeterReadingsLoaded && meterReadingState.readings.length >= 2) {
          action = () => _showGenerateBillDialog(context, meterReadingState.readings);
        } else {
          buttonText = l10n?.addMoreReadings ?? 'Add More Readings First';
          action = null;
        }
        break;
    }
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CommonWidgets.buildPulseAnimation(
            child: Icon(
              Icons.receipt_long,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(153), // 0.6 * 255 = 153
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _selectedFilter == 'all'
                  ? (l10n?.generateBillInstructions ?? 'Generate a bill from your meter readings')
                  : (l10n?.changeFilterInstructions ?? 'Try changing the filter to see all bills'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          if (action != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: Text(buttonText),
              onPressed: action,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBillingSummaryCard(BuildContext context, BillsLoaded state) {
    final l10n = AppLocalizations.of(context);
    final numberFormat = NumberFormat('#,##0.00');
    // Get the active currency from the BLoC
    final currencyBloc = BlocProvider.of<CurrencyBloc>(context);
    final currency = currencyBloc.state.activeCurrency;
    
    // Don't display summary if there are no bills, or if filtered bills are empty
    if (state.bills.isEmpty || _filterBills(state.bills).isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: const EdgeInsets.all(16.0),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: CommonWidgets.buildEnhancedStatIndicator(
                    context: context,
                    label: l10n?.totalAmount ?? 'Total Amount',
                    value: '${numberFormat.format(state.totalAmount)} ${currency.symbol ?? "FCFA"}',
                    icon: Icons.payments,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: CommonWidgets.buildEnhancedStatIndicator(
                    context: context,
                    label: l10n?.unpaidAmount ?? 'Unpaid Amount',
                    value: '${numberFormat.format(state.unpaidAmount)} ${currency.symbol ?? "FCFA"}',
                    icon: Icons.money_off,
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: CommonWidgets.buildEnhancedStatIndicator(
                    context: context,
                    label: l10n?.unpaidBillsCount ?? 'Unpaid Bills',
                    value: '${state.unpaidBills}/${state.totalBills}',
                    icon: Icons.receipt_long,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBillsList(BuildContext context, List<Bill> bills) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.00');
    // Get the active currency from the BLoC
    final currencyBloc = BlocProvider.of<CurrencyBloc>(context);
    final currency = currencyBloc.state.activeCurrency;

    return ListView.separated(
      itemCount: bills.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final bill = bills[index];
        return _buildBillCard(context, bill, l10n, dateFormat, numberFormat, currency);
      },
    );
  }
  
  Widget _buildBillCard(
    BuildContext context, 
    Bill bill, 
    AppLocalizations? l10n, 
    DateFormat dateFormat, 
    NumberFormat numberFormat,
    dynamic currency
  ) {
    final isPaid = bill.isPaid;
    final statusColor = isPaid ? Colors.green : Colors.red;
    
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header with status
          _buildBillHeader(bill, l10n, dateFormat, statusColor),
          
          // Bill content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount and period row
                _buildAmountAndPeriodRow(bill, l10n, numberFormat, dateFormat, currency),
                
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                
                // Consumption and rate row
                _buildConsumptionAndRateRow(context, bill, l10n, numberFormat),
                
                // Notes (if present)
                if (bill.notes != null && bill.notes!.isNotEmpty)
                  _buildNotesSection(bill, l10n),
              ],
            ),
          ),
          
          // Action buttons
          _buildActionButtons(context, bill, l10n),
        ],
      ),
    );
  }
  
  Widget _buildBillHeader(Bill bill, AppLocalizations? l10n, DateFormat dateFormat, Color statusColor) {
    return Container(
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            bill.isPaid ? Icons.check_circle : Icons.pending,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Text(
            bill.isPaid ? (l10n?.paid ?? 'Paid') : (l10n?.unpaid ?? 'Unpaid'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const Spacer(),
          Text(
            dateFormat.format(bill.generatedDate),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAmountAndPeriodRow(
    Bill bill, 
    AppLocalizations? l10n, 
    NumberFormat numberFormat, 
    DateFormat dateFormat,
    dynamic currency
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.amount ?? 'Amount',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${numberFormat.format(bill.amount)} ${currency.symbol ?? "FCFA"}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Period
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.period ?? 'Period',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${dateFormat.format(bill.startDate)} - ${dateFormat.format(bill.endDate)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildConsumptionAndRateRow(
    BuildContext context, 
    Bill bill, 
    AppLocalizations? l10n, 
    NumberFormat numberFormat
  ) {
    return Row(
      children: [
        // Consumption
        Expanded(
          child: _buildDataContainer(
            context,
            label: l10n?.consumption ?? 'Consumption',
            value: numberFormat.format(bill.consumption),
            unit: l10n?.kWh ?? 'kWh',
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Rate
        Expanded(
          child: _buildDataContainer(
            context,
            label: l10n?.rate ?? 'Rate',
            value: numberFormat.format(widget.meter.pricePerKwh),
            unit: l10n?.perKwh ?? '/kWh',
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDataContainer(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
                    color: color.withAlpha(26), // 0.1 * 255 = 26
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotesSection(Bill bill, AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, size: 16),
                const SizedBox(width: 4),
                Text(
                  l10n?.notes ?? 'Notes',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              bill.notes!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context, Bill bill, AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Toggle payment status button
          Expanded(
            child: TextButton.icon(
              icon: Icon(
                bill.isPaid ? Icons.money_off : Icons.paid,
                size: 18,
                color: bill.isPaid ? Colors.orange : Colors.green,
              ),
              label: Text(
                bill.isPaid 
                    ? (l10n?.markAsUnpaid ?? 'Mark Unpaid')
                    : (l10n?.markAsPaid ?? 'Mark Paid'),
                style: TextStyle(
                  color: bill.isPaid ? Colors.orange : Colors.green,
                ),
              ),
              onPressed: () => _togglePaidStatus(context, bill),
            ),
          ),
          
          // Send bill button
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.send, size: 18),
              label: Text(l10n?.send ?? 'Send'),
              onPressed: () => _showCommunicationDialog(context, [bill]),
            ),
          ),
          
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            tooltip: l10n?.delete ?? 'Delete',
            onPressed: () => _showDeleteBillDialog(context, bill),
          ),
        ],
      ),
    );
  }

  void _togglePaidStatus(BuildContext context, Bill bill) {
    final l10n = AppLocalizations.of(context);
    
    context.read<BillBloc>().add(UpdateBillPaymentStatus(
      bill: bill,
      isPaid: !bill.isPaid,
    ));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          bill.isPaid
              ? (l10n?.markedAsUnpaid ?? 'Marked as unpaid')
              : (l10n?.markedAsPaid ?? 'Marked as paid')
        ),
        backgroundColor: bill.isPaid ? Colors.orange : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showCommunicationDialog(
    BuildContext context,
    List<Bill> bills, {
    bool isBulk = false,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => CommunicationDialog(
        bills: bills,
        meter: widget.meter,
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              l10n?.deleteBillConfirmation ??
              'Are you sure you want to delete this bill? This action cannot be undone.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Text(l10n?.deleting ?? 'Deleting...'),
            ],
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      context.read<BillBloc>().add(DeleteBill(bill.id));
    }
  }

  void _showGenerateBillDialog(BuildContext context, List<MeterReading> readings) {
    final l10n = AppLocalizations.of(context);
    final numberFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    final currentReading = readings[0];
    final previousReading = readings[1];
    final consumption = currentReading.value - previousReading.value;
    
    if (consumption <= 0) {
      _showInvalidConsumptionDialog(context, l10n);
      return;
    }

    final amount = consumption * widget.meter.pricePerKwh;
    final billBloc = context.read<BillBloc>();
    final notesController = TextEditingController();
    final currencyBloc = BlocProvider.of<CurrencyBloc>(context);
    final currency = currencyBloc.state.activeCurrency;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.generateBill ?? 'Generate New Bill'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reading details card
              _buildReadingDetailsCard(context, currentReading, previousReading, l10n, numberFormat, dateFormat),
              
              const SizedBox(height: 16),
              
              // Calculation card
              _buildCalculationCard(context, consumption, amount, l10n, numberFormat, currency),
              
              const SizedBox(height: 24),
              
              // Notes field
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: l10n?.notes ?? 'Notes (Optional)',
                  border: const OutlineInputBorder(),
                  hintText: l10n?.notesHint ?? 'Add any additional information',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _generateBill(
              dialogContext, 
              billBloc, 
              currentReading, 
              previousReading, 
              consumption, 
              amount, 
              notesController.text
            ),
            child: Text(l10n?.generateBill ?? 'Generate'),
          ),
        ],
      ),
    ).then((_) => notesController.dispose());
  }
  
  void _generateBill(
    BuildContext dialogContext,
    BillBloc billBloc,
    MeterReading currentReading,
    MeterReading previousReading,
    double consumption,
    double amount,
    String notes
  ) {
    final l10n = AppLocalizations.of(dialogContext);
    final now = DateTime.now();
    
    final bill = BillModel(
      id: now.millisecondsSinceEpoch.toString(),
      meterId: widget.meter.id,
      clientName: widget.meter.clientName,
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
      notes: notes.isEmpty ? null : notes,
    );
    
    billBloc.add(AddBill(bill));
    Navigator.pop(dialogContext);
    
    if (dialogContext.mounted) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text(l10n?.billGenerated ?? 'Bill generated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _showInvalidConsumptionDialog(BuildContext context, AppLocalizations? l10n) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.error ?? 'Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              l10n?.invalidConsumption ?? 
              'Invalid consumption: current reading must be greater than previous reading',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.ok ?? 'OK'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReadingDetailsCard(
    BuildContext context,
    MeterReading currentReading,
    MeterReading previousReading,
    AppLocalizations? l10n,
    NumberFormat numberFormat,
    DateFormat dateFormat
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n?.readingDetails ?? 'Reading Details',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CommonWidgets.buildInfoRow(
              label: l10n?.currentReading ?? "Current Reading",
              value: "${numberFormat.format(currentReading.value)} kWh (${dateFormat.format(currentReading.readingDate)})",
              icon: Icons.arrow_upward,
            ),
            CommonWidgets.buildInfoRow(
              label: l10n?.previousReading ?? "Previous Reading",
              value: "${numberFormat.format(previousReading.value)} kWh (${dateFormat.format(previousReading.readingDate)})",
              icon: Icons.arrow_downward,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCalculationCard(
    BuildContext context,
    double consumption,
    double amount,
    AppLocalizations? l10n,
    NumberFormat numberFormat,
    dynamic currency
  ) {
    return Card(
      margin: EdgeInsets.zero,
                    color: Theme.of(context).colorScheme.primary.withAlpha(26), // 0.1 * 255 = 26
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonWidgets.buildInfoRow(
              label: l10n?.consumption ?? "Consumption",
              value: "${numberFormat.format(consumption)} kWh",
            ),
            CommonWidgets.buildInfoRow(
              label: l10n?.rate ?? "Rate",
              value: "${numberFormat.format(widget.meter.pricePerKwh)} ${l10n?.perKwh ?? '/kWh'}",
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    l10n?.totalAmount ?? "Total Amount",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: Text(
                    "${numberFormat.format(amount)} ${currency.symbol ?? "FCFA"}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}