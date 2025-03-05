//presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../data/models/meter_model.dart';
import '../../domain/entities/meter.dart';
import '../bloc/meter/meter_bloc.dart';
import '../bloc/meter/meter_event.dart';
import '../bloc/meter/meter_state.dart';
import '../bloc/currency/currency_bloc.dart';
import '../bloc/currency/currency_state.dart';
import '../../services/currency_service.dart';
import '../bloc/meter_reading/meter_reading_bloc.dart';
import '../bloc/meter_reading/meter_reading_event.dart';
import '../widgets/contact_picker_dialog.dart';
import 'add_meter_reading_screen.dart';
import 'bills_screen.dart';
import 'meter_readings_screen.dart';
import 'settings_screen.dart';
import '../../injection.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.appTitle ?? 'Electric Meter Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: AppLocalizations.of(context)?.settings ?? 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<MeterBloc, MeterState>(
        builder: (context, state) {
          if (state is MeterLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is MetersLoaded) {
            return Column(
              children: [
                _buildStatisticsCard(context, state),
                Expanded(child: _buildMetersList(context, state.meters)),
              ],
            );
          } else if (state is MeterError) {
            return Center(
              child: Text(
                '${AppLocalizations.of(context)?.error ?? 'Error'}: ${state.message}',
              ),
            );
          }
          return Center(
            child: Text(AppLocalizations.of(context)?.noMetersAvailable ?? 'No meters available'),
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () => _showAddMeterDialog(context),
          tooltip: AppLocalizations.of(context)?.addMeter ?? 'Add Meter',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context, MetersLoaded state) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.overview ?? 'Overview',
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
                  l10n?.totalMeters ?? 'Total Meters',
                  state.totalMeters.toString(),
                  Icons.electric_meter,
                  Colors.blue,
                ),
                _buildStatItem(
                  l10n?.totalConsumption ?? 'Total Consumption',
                  '${state.totalConsumption.toStringAsFixed(2)} ${l10n?.kWh ?? 'kWh'}',
                  Icons.bolt,
                  Colors.orange,
                ),
                _buildStatItem(
                  l10n?.totalAmount ?? 'Total Amount',
                  getIt<CurrencyService>().formatAmount(
                    state.totalAmount,
                    context.watch<CurrencyBloc>().state.activeCurrency,
                  ),
                  Icons.currency_exchange,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMetersList(BuildContext context, List<Meter> meters) {
    final l10n = AppLocalizations.of(context);
    return ListView.builder(
      itemCount: meters.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final meter = meters[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.electric_meter),
            ),
            title: Text(meter.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meter.location),
                Text(meter.clientName),
                if (meter.contactName != null)
                  Text('${l10n?.contact ?? 'Contact'}: ${meter.contactName}'),
                if (meter.contactPhone != null)
                  Text('${l10n?.phone ?? 'Phone'}: ${meter.contactPhone}'),
                if (meter.contactEmail != null)
                  Text('${l10n?.email ?? 'Email'}: ${meter.contactEmail}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  child: Text(l10n?.addReading ?? 'Add Reading'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<Widget>(
                      builder: (context) => BlocProvider(
                        create: (context) => getIt<MeterReadingBloc>(),
                        child: AddMeterReadingScreen(meter: meter),
                      ),
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  child: Text(l10n?.readings ?? 'View Readings'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => getIt<MeterReadingBloc>()
                          ..add(LoadMeterReadings(meter.id)),
                        child: MeterReadingsScreen(meter: meter),
                      ),
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  child: Text(l10n?.bills ?? 'View Bills'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BillsScreen(meter: meter),
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  child: Text(l10n?.edit ?? 'Edit'),
                  onTap: () => _showEditMeterDialog(context, meter),
                ),
                PopupMenuItem<String>(
                  child: Text(l10n?.delete ?? 'Delete'),
                  onTap: () => _showDeleteMeterDialog(context, meter),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddMeterDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    String name = '';
    String location = '';
    String clientName = '';
    double pricePerKwh = 0.0;
    String? contactName;
    String? contactPhone;
    String? contactEmail;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n?.addMeter ?? 'Add New Meter'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: l10n?.meterName ?? 'Meter Name'
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? l10n?.requiredField ?? 'Required field' : null,
                    onSaved: (value) => name = value ?? '',
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: l10n?.location ?? 'Location'
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? l10n?.requiredField ?? 'Required field' : null,
                    onSaved: (value) => location = value ?? '',
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: l10n?.clientName ?? 'Client Name'
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? l10n?.requiredField ?? 'Required field' : null,
                    onSaved: (value) => clientName = value ?? '',
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: l10n?.pricePerKwh ?? 'Price per kWh'
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return l10n?.requiredField ?? 'Required field';
                      final price = double.tryParse(value!);
                      if (price == null || price <= 0) {
                        return l10n?.invalidPrice ?? 'Enter a valid price';
                      }
                      return null;
                    },
                    onSaved: (value) => pricePerKwh = double.parse(value!),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      contactName ?? (l10n?.selectContact ?? 'Select Contact'),
                      style: TextStyle(
                        color: contactName == null ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (contactPhone != null) Text('${AppLocalizations.of(context)?.phone ?? 'Phone'}: $contactPhone'),
                        if (contactEmail != null) Text('${AppLocalizations.of(context)?.email ?? 'Email'}: $contactEmail'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person_add),
                          tooltip: AppLocalizations.of(context)?.selectContact ?? 'Select Contact',
                          onPressed: () async {
                            final result =
                                await showDialog<Map<String, String?>>(
                              context: dialogContext,
                              builder: (_) => const ContactPickerDialog(),
                            );
                            if (result != null) {
                              setDialogState(() {
                                contactName = result['name'];
                                contactPhone = result['phone'];
                                contactEmail = result['email'];
                              });
                            }
                          },
                        ),
                        if (contactName != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: AppLocalizations.of(context)?.clearContact ?? 'Clear Contact',
                            onPressed: () {
                              setDialogState(() {
                                contactName = null;
                                contactPhone = null;
                                contactEmail = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  final now = DateTime.now();
                  final meter = MeterModel(
                    id: now.millisecondsSinceEpoch.toString(),
                    name: name,
                    location: location,
                    clientName: clientName,
                    pricePerKwh: pricePerKwh,
                    createdAt: now,
                    updatedAt: now,
                    contactName: contactName,
                    contactPhone: contactPhone,
                    contactEmail: contactEmail,
                  );
                  context.read<MeterBloc>().add(AddMeter(meter));
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(l10n?.save ?? 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditMeterDialog(BuildContext context, Meter meter) async {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    String name = meter.name;
    String location = meter.location;
    String clientName = meter.clientName;
    double pricePerKwh = meter.pricePerKwh;
    String? contactName = meter.contactName;
    String? contactPhone = meter.contactPhone;
    String? contactEmail = meter.contactEmail;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n?.edit ?? 'Edit Meter'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: InputDecoration(
                      labelText: l10n?.meterName ?? 'Meter Name',
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? l10n?.requiredField ?? 'Required field' : null,
                    onSaved: (value) => name = value ?? '',
                  ),
                  TextFormField(
                    initialValue: location,
                    decoration: InputDecoration(
                      labelText: l10n?.location ?? 'Location',
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? l10n?.requiredField ?? 'Required field' : null,
                    onSaved: (value) => location = value ?? '',
                  ),
                  TextFormField(
                    initialValue: clientName,
                    decoration: InputDecoration(
                      labelText: l10n?.clientName ?? 'Client Name',
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? l10n?.requiredField ?? 'Required field' : null,
                    onSaved: (value) => clientName = value ?? '',
                  ),
                  TextFormField(
                    initialValue: pricePerKwh.toString(),
                    decoration: InputDecoration(
                      labelText: l10n?.pricePerKwh ?? 'Price per kWh',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return l10n?.requiredField ?? 'Required field';
                      final price = double.tryParse(value!);
                      if (price == null || price <= 0) {
                        return l10n?.invalidPrice ?? 'Enter a valid price';
                      }
                      return null;
                    },
                    onSaved: (value) => pricePerKwh = double.parse(value!),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      contactName ?? (l10n?.selectContact ?? 'Select Contact'),
                      style: TextStyle(
                        color: contactName == null ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (contactPhone != null)
                          Text('${l10n?.phone ?? 'Phone'}: $contactPhone'),
                        if (contactEmail != null)
                          Text('${l10n?.email ?? 'Email'}: $contactEmail'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person_add),
                          onPressed: () async {
                            final result =
                                await showDialog<Map<String, String?>>(
                              context: dialogContext,
                              builder: (_) => const ContactPickerDialog(),
                            );
                            if (result != null) {
                              setDialogState(() {
                                contactName = result['name'];
                                contactPhone = result['phone'];
                                contactEmail = result['email'];
                              });
                            }
                          },
                        ),
                        if (contactName != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setDialogState(() {
                                contactName = null;
                                contactPhone = null;
                                contactEmail = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  final updatedMeter = MeterModel(
                    id: meter.id,
                    name: name,
                    location: location,
                    clientName: clientName,
                    pricePerKwh: pricePerKwh,
                    createdAt: meter.createdAt,
                    updatedAt: DateTime.now(),
                    contactName: contactName,
                    contactPhone: contactPhone,
                    contactEmail: contactEmail,
                  );
                  context.read<MeterBloc>().add(UpdateMeter(updatedMeter));
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(l10n?.save ?? 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteMeterDialog(BuildContext context, Meter meter) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.deleteMeter ?? 'Delete Meter'),
        content: Text(
          l10n?.deleteConfirmation != null
              ? l10n!.deleteConfirmation(meter.name)
              : 'Are you sure you want to delete ${meter.name}? This will also delete all associated readings and bills.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<MeterBloc>().add(DeleteMeter(meter.id));
    }
  }
}
