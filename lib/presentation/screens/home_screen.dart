// lib/presentation/screens/home_screen.dart

import 'package:electric_meter_bill/data/models/meter_model.dart';
import 'package:electric_meter_bill/domain/entities/meter.dart';
import 'package:electric_meter_bill/injection.dart';
import 'package:electric_meter_bill/presentation/bloc/currency/currency_bloc.dart';
import 'package:electric_meter_bill/presentation/bloc/meter/meter_bloc.dart';
import 'package:electric_meter_bill/presentation/bloc/meter/meter_event.dart';
import 'package:electric_meter_bill/presentation/bloc/meter/meter_state.dart';
import 'package:electric_meter_bill/presentation/bloc/meter_reading/meter_reading_bloc.dart';
import 'package:electric_meter_bill/presentation/bloc/meter_reading/meter_reading_event.dart';
import 'package:electric_meter_bill/presentation/screens/add_meter_reading_screen.dart';
import 'package:electric_meter_bill/presentation/screens/bills_screen.dart';
import 'package:electric_meter_bill/presentation/screens/meter_readings_screen.dart';
import 'package:electric_meter_bill/presentation/screens/settings_screen.dart';
import 'package:electric_meter_bill/presentation/widgets/common_widgets.dart';
import 'package:electric_meter_bill/presentation/widgets/contact_picker_dialog.dart';
import 'package:electric_meter_bill/services/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(l10n?.appTitle ?? 'Electric Meter Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n?.settings ?? 'Settings',
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
            return CommonWidgets.buildFadeTransition(
              child: Column(
                children: [
                  // Carte de statistiques améliorée
                  _buildEnhancedStatsCard(context, state),

                  // En-tête de la liste avec comptage
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '${l10n?.yourMeters ?? 'Your Meters'}'
                          ' (${state.totalMeters})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (state.meters.isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(Icons.sort),
                            label: Text(l10n?.sort ?? 'Sort'),
                            onPressed: () => _showSortOptions(context),
                          ),
                      ],
                    ),
                  ),

                  // Liste des compteurs améliorée
                  Expanded(
                    child: state.meters.isEmpty
                        ? _buildEmptyState(context)
                        : _buildEnhancedMetersList(context, state.meters),
                  ),
                ],
              ),
            );
          } else if (state is MeterError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '${l10n?.error ?? 'Error'}: ${state.message}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n?.tryAgain ?? 'Try Again'),
                    onPressed: () {
                      context.read<MeterBloc>().add(const LoadMeters());
                    },
                  ),
                ],
              ),
            );
          }
          return _buildEmptyState(context);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMeterDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n?.addMeter ?? 'Add Meter'),
        tooltip: l10n?.addMeter ?? 'Add Meter',
      ),
    );
  }

  Widget _buildEnhancedStatsCard(BuildContext context, MetersLoaded state) {
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.overview ?? 'Overview',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CommonWidgets.buildEnhancedStatIndicator(
                  context: context,
                  label: l10n?.totalMeters ?? 'Total Meters',
                  value: state.totalMeters.toString(),
                  icon: Icons.electric_meter,
                  color: Theme.of(context).colorScheme.primary,
                ),
                CommonWidgets.buildEnhancedStatIndicator(
                  context: context,
                  label: l10n?.totalConsumption ?? 'Total Consumption',
                  value: '${state.totalConsumption.toStringAsFixed(2)} '
                      '${l10n?.kWh ?? 'kWh'}',
                  icon: Icons.bolt,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                CommonWidgets.buildEnhancedStatIndicator(
                  context: context,
                  label: l10n?.totalAmount ?? 'Total Amount',
                  value: getIt<CurrencyService>().formatAmount(
                    state.totalAmount,
                    context.watch<CurrencyBloc>().state.activeCurrency,
                  ),
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: CommonWidgets.buildActionButton(
              context: context,
              icon: Icons.bolt,
              label: l10n?.addReading ?? 'Add Reading',
              onTap: () => _showMeterSelectionForReading(context),
              iconSize: 28,
            ),
          ),
          Expanded(
            child: CommonWidgets.buildActionButton(
              context: context,
              icon: Icons.receipt_long,
              label: l10n?.viewBills ?? 'View Bills',
              onTap: () => _showMeterSelectionForBills(context),
              iconSize: 28,
            ),
          ),
          Expanded(
            child: CommonWidgets.buildActionButton(
              context: context,
              icon: Icons.history,
              label: l10n?.viewReadings ?? 'View Readings',
              onTap: () => _showMeterSelectionForReadings(context),
              iconSize: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CommonWidgets.buildPulseAnimation(
            child: Icon(
              Icons.electric_meter,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(153),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.noMetersAvailable ?? 'No meters available',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.addMeterToStart ??
                'Add a meter to start tracking your electricity usage',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n?.addFirstMeter ?? 'Add Your First Meter'),
            onPressed: () => _showAddMeterDialog(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMetersList(BuildContext context, List<Meter> meters) {
    return ListView.builder(
      itemCount: meters.length,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemBuilder: (context, index) {
        final meter = meters[index];
        return _buildMeterCard(context, meter);
      },
    );
  }

  Widget _buildMeterCard(BuildContext context, Meter meter) {
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du compteur avec icône et nom
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.electric_meter, color: Colors.white),
            ),
            title: Text(
              meter.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              meter.location,
              style: const TextStyle(fontSize: 16),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: l10n?.moreOptions ?? 'More Options',
              onPressed: () => _showMeterOptionsMenu(context, meter),
            ),
          ),

          // Informations sur le client
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  meter.clientName,
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '${meter.pricePerKwh} ${l10n?.perKwh ?? '/kWh'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Boutons d'action
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMeterActionButton(
                  context,
                  icon: Icons.add_chart,
                  label: l10n?.addReading ?? 'Reading',
                  onTap: () => _navigateToAddReading(context, meter),
                ),
                _buildMeterActionButton(
                  context,
                  icon: Icons.history,
                  label: l10n?.readings ?? 'History',
                  onTap: () => _navigateToReadings(context, meter),
                ),
                _buildMeterActionButton(
                  context,
                  icon: Icons.receipt,
                  label: l10n?.bills ?? 'Bills',
                  onTap: () => _navigateToBills(context, meter),
                ),
                _buildMeterActionButton(
                  context,
                  icon: Icons.edit,
                  label: l10n?.edit ?? 'Edit',
                  onTap: () => _showEditMeterDialog(context, meter),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showMeterOptionsMenu(BuildContext context, Meter meter) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                meter.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(meter.location),
              leading: const CircleAvatar(
                child: Icon(Icons.electric_meter),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_chart),
              title: Text(l10n?.addReading ?? 'Add Reading'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddReading(context, meter);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(l10n?.readings ?? 'View Readings'),
              onTap: () {
                Navigator.pop(context);
                _navigateToReadings(context, meter);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(l10n?.bills ?? 'View Bills'),
              onTap: () {
                Navigator.pop(context);
                _navigateToBills(context, meter);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n?.edit ?? 'Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditMeterDialog(context, meter);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                l10n?.delete ?? 'Delete',
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteMeterDialog(context, meter);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n?.sortBy ?? 'Sort By',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: Text(l10n?.name ?? 'Name'),
              onTap: () {
                Navigator.pop(context);
                context.read<MeterBloc>().add(const SortMeters('name'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n?.dateCreated ?? 'Date Created'),
              onTap: () {
                Navigator.pop(context);
                context.read<MeterBloc>().add(const SortMeters('date'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(l10n?.location ?? 'Location'),
              onTap: () {
                Navigator.pop(context);
                context.read<MeterBloc>().add(const SortMeters('location'));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMeterDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final clientNameController = TextEditingController();
    final pricePerKwhController = TextEditingController();
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
                  CommonWidgets.buildAccessibleFormField(
                    context: context,
                    label: l10n?.meterName ?? 'Meter Name',
                    controller: nameController,
                    prefixIcon: Icons.electric_meter,
                    validator: (value) => value?.isEmpty ?? true
                        ? l10n?.requiredField ?? 'Required field'
                        : null,
                    hintText:
                        l10n?.meterNameHint ?? 'Enter a name for this meter',
                  ),
                  CommonWidgets.buildAccessibleFormField(
                    context: context,
                    label: l10n?.location ?? 'Location',
                    controller: locationController,
                    prefixIcon: Icons.location_on,
                    validator: (value) => value?.isEmpty ?? true
                        ? l10n?.requiredField ?? 'Required field'
                        : null,
                    hintText:
                        l10n?.locationHint ?? 'Where is this meter located?',
                  ),
                  CommonWidgets.buildAccessibleFormField(
                    context: context,
                    label: l10n?.clientName ?? 'Client Name',
                    controller: clientNameController,
                    prefixIcon: Icons.person,
                    validator: (value) => value?.isEmpty ?? true
                        ? l10n?.requiredField ?? 'Required field'
                        : null,
                    hintText: l10n?.clientNameHint ?? 'Who is the client?',
                  ),
                  CommonWidgets.buildAccessibleFormField(
                    context: context,
                    label: l10n?.pricePerKwh ?? 'Price per kWh',
                    controller: pricePerKwhController,
                    prefixIcon: Icons.monetization_on,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return l10n?.requiredField ?? 'Required field';
                      }
                      final price = double.tryParse(value!);
                      if (price == null || price <= 0) {
                        return l10n?.invalidPrice ?? 'Enter a valid price';
                      }
                      return null;
                    },
                    hintText: l10n?.pricePerKwhHint ?? 'Ex: 79.0',
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.contact_phone,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n?.contactInformation ??
                                    'Contact Information',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                l10n?.optional ?? 'Optional',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          ListTile(
                            title: Text(
                              contactName ??
                                  (l10n?.selectContact ?? 'Select Contact'),
                              style: TextStyle(
                                color: contactName == null ? Colors.grey : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (contactPhone != null)
                                  Text(
                                    [
                                      AppLocalizations.of(context)?.phone ??
                                          'Phone',
                                      contactPhone,
                                    ].join(': '),
                                  ),
                                if (contactEmail != null)
                                  Text(
                                    [
                                      AppLocalizations.of(context)?.email ??
                                          'Email',
                                      contactEmail,
                                    ].join(': '),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.person_add),
                                  tooltip: AppLocalizations.of(context)
                                          ?.selectContact ??
                                      'Select Contact',
                                  onPressed: () async {
                                    final result =
                                        await showDialog<Map<String, String?>>(
                                      context: dialogContext,
                                      builder: (_) =>
                                          const ContactPickerDialog(),
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
                                    tooltip: AppLocalizations.of(context)
                                            ?.clearContact ??
                                        'Clear Contact',
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  final now = DateTime.now();
                  final meter = MeterModel(
                    id: now.millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    location: locationController.text,
                    clientName: clientNameController.text,
                    pricePerKwh: double.parse(pricePerKwhController.text),
                    createdAt: now,
                    updatedAt: now,
                    contactName: contactName,
                    contactPhone: contactPhone,
                    contactEmail: contactEmail,
                  );
                  context.read<MeterBloc>().add(AddMeter(meter));
                  Navigator.pop(dialogContext);

                  // Afficher un message de confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(l10n?.meterAdded ?? 'Meter added successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(l10n?.save ?? 'Save'),
            ),
          ],
        ),
      ),
    );

    // Libérer les contrôleurs
    nameController.dispose();
    locationController.dispose();
    clientNameController.dispose();
    pricePerKwhController.dispose();
  }

  // Reste des méthodes: _showEditMeterDialog, _showDeleteMeterDialog, etc.

  Future<void> _showEditMeterDialog(BuildContext context, Meter meter) async {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: meter.name);
    final locationController = TextEditingController(text: meter.location);
    final clientNameController = TextEditingController(text: meter.clientName);
    final pricePerKwhController = TextEditingController(
        text: meter.pricePerKwh.toString());
    String? contactName = meter.contactName;
    String? contactPhone = meter.contactPhone;
    String? contactEmail = meter.contactEmail;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n?.editMeter ?? 'Edit Meter'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CommonWidgets.buildAccessibleFormField(
                    context: context,
                    label: l10n?.meterName ?? 'Meter Name',
                    controller: nameController,
                    prefixIcon: Icons.electric_meter,
                    validator: (value) => value?.isEmpty ?? true
                        ? l10n?.requiredField ?? 'Required field'
                        : null,
                    hintText:
                        l10n?.meterNameHint ?? 'Enter a name for this meter',
                  ),
                  CommonWidgets.buildAccessibleFormField(
                    context: context,
                    label: l10n?.location ?? 'Location',
                    controller: locationController,
                    prefixIcon: Icons.location_on,
                    validator: (value) => value?.isEmpty ?? true
                        ? l10n?.requiredField ?? 'Required field'
                        : null,
                    hintText:
                        l10n?.locationHint ?? 'Where is this meter located?',
                  ),
                  CommonWidgets.buildAccessibleFormField(
                    context: context,
                    label: l10n?.clientName ?? 'Client Name',
                    controller: clientNameController,
                    prefixIcon: Icons.person,
                    validator: (value) => value?.isEmpty ?? true
                        ? l10n?.requiredField ?? 'Required field'
                        : null,
                    hintText: l10n?.clientNameHint ?? 'Who is the client?',
                  ),
                  CommonWidgets.buildAccessibleFormField(
                    context: context,
                    label: l10n?.pricePerKwh ?? 'Price per kWh',
                    controller: pricePerKwhController,
                    prefixIcon: Icons.monetization_on,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return l10n?.requiredField ?? 'Required field';
                      }
                      final price = double.tryParse(value!);
                      if (price == null || price <= 0) {
                        return l10n?.invalidPrice ?? 'Enter a valid price';
                      }
                      return null;
                    },
                    hintText: l10n?.pricePerKwhHint ?? 'Ex: 79.0',
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.contact_phone,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n?.contactInformation ??
                                    'Contact Information',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                l10n?.optional ?? 'Optional',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          ListTile(
                            title: Text(
                              contactName ??
                                  (l10n?.selectContact ?? 'Select Contact'),
                              style: TextStyle(
                                color: contactName == null ? Colors.grey : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (contactPhone != null)
                                  Text(
                                    [
                                      AppLocalizations.of(context)?.phone ??
                                          'Phone',
                                      contactPhone,
                                    ].join(': '),
                                  ),
                                if (contactEmail != null)
                                  Text(
                                    [
                                      AppLocalizations.of(context)?.email ??
                                          'Email',
                                      contactEmail,
                                    ].join(': '),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.person_add),
                                  tooltip: AppLocalizations.of(context)
                                          ?.selectContact ??
                                      'Select Contact',
                                  onPressed: () async {
                                    final result =
                                        await showDialog<Map<String, String?>>(
                                      context: dialogContext,
                                      builder: (_) =>
                                          const ContactPickerDialog(),
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
                                    tooltip: AppLocalizations.of(context)
                                            ?.clearContact ??
                                        'Clear Contact',
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  final updatedMeter = MeterModel(
                    id: meter.id,
                    name: nameController.text,
                    location: locationController.text,
                    clientName: clientNameController.text,
                    pricePerKwh: double.parse(pricePerKwhController.text),
                    createdAt: meter.createdAt,
                    updatedAt: DateTime.now(),
                    contactName: contactName,
                    contactPhone: contactPhone,
                    contactEmail: contactEmail,
                  );
                  context.read<MeterBloc>().add(UpdateMeter(updatedMeter));
                  Navigator.pop(dialogContext);

                  // Show confirmation message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          l10n?.meterUpdated ?? 'Meter updated successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(l10n?.save ?? 'Save'),
            ),
          ],
        ),
      ),
    );

    // Dispose of controllers
    nameController.dispose();
    locationController.dispose();
    clientNameController.dispose();
    pricePerKwhController.dispose();
  }

  Future<void> _showDeleteMeterDialog(BuildContext context, Meter meter) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.deleteMeter ?? 'Delete Meter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              l10n?.deleteConfirmation != null
                  ? l10n!.deleteConfirmation(meter.name)
                  : 'Are you sure you want to delete ${meter.name}? '
                      'This will also delete all associated readings '
                      'and bills.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      context.read<MeterBloc>().add(DeleteMeter(meter.id));

      // Afficher un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.meterDeleted ?? 'Meter deleted successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Navigation methods
  void _navigateToAddReading(BuildContext context, Meter meter) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => BlocProvider(
          create: (context) => getIt<MeterReadingBloc>(),
          child: AddMeterReadingScreen(meter: meter),
        ),
      ),
    );
  }

  void _navigateToReadings(BuildContext context, Meter meter) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => BlocProvider(
          create: (context) =>
              getIt<MeterReadingBloc>()..add(LoadMeterReadings(meter.id)),
          child: MeterReadingsScreen(meter: meter),
        ),
      ),
    );
  }

  void _navigateToBills(BuildContext context, Meter meter) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => BillsScreen(meter: meter),
      ),
    );
  }

  void _showMeterSelectionForBills(BuildContext context) {
    final state = context.read<MeterBloc>().state;
    if (state is MetersLoaded && state.meters.isNotEmpty) {
      if (state.meters.length == 1) {
        _navigateToBills(context, state.meters.first);
      } else {
        _showMeterSelectionBottomSheet(
          context: context,
          title: AppLocalizations.of(context)?.selectMeter ?? 'Select Meter',
          onMeterSelected: (meter) {
            _navigateToBills(context, meter);
          },
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.noMetersAvailable ??
              'No meters available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Sélection de compteur pour actions rapides
  void _showMeterSelectionForReading(BuildContext context) {
    final state = context.read<MeterBloc>().state;
    if (state is MetersLoaded && state.meters.isNotEmpty) {
      if (state.meters.length == 1) {
        // S'il n'y a qu'un seul compteur, aller directement à l'ajout de relevé
        _navigateToAddReading(context, state.meters.first);
      } else {
        _showMeterSelectionBottomSheet(
          context: context,
          title: AppLocalizations.of(context)?.selectMeter ?? 'Select Meter',
          onMeterSelected: (meter) {
            _navigateToAddReading(context, meter);
          },
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.noMetersAvailable ??
              'No meters available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showMeterSelectionForReadings(BuildContext context) {
    final state = context.read<MeterBloc>().state;
    if (state is MetersLoaded && state.meters.isNotEmpty) {
      if (state.meters.length == 1) {
        _navigateToReadings(context, state.meters.first);
      } else {
        _showMeterSelectionBottomSheet(
          context: context,
          title: AppLocalizations.of(context)?.selectMeter ?? 'Select Meter',
          onMeterSelected: (meter) {
            _navigateToReadings(context, meter);
          },
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.noMetersAvailable ??
              'No meters available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

// Afficher une bottom sheet pour sélectionner un compteur (plus moderne qu'un dialogue)
  void _showMeterSelectionBottomSheet({
    required BuildContext context,
    required String title,
    required void Function(Meter) onMeterSelected,
  }) {
    final state = context.read<MeterBloc>().state;
    if (state is MetersLoaded) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.meters.length,
                  itemBuilder: (context, index) {
                    final meter = state.meters[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.electric_meter,
                            color: Colors.white),
                      ),
                      title: Text(meter.name),
                      subtitle: Text(meter.location),
                      onTap: () {
                        Navigator.pop(context);
                        onMeterSelected(meter);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }
  }
}
