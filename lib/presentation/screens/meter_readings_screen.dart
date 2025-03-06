// lib/presentation/screens/meter_readings_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../data/models/meter_reading_model.dart';
import '../../domain/entities/meter.dart';
import '../../domain/entities/meter_reading.dart';
import '../bloc/meter_reading/meter_reading_bloc.dart';
import '../bloc/meter_reading/meter_reading_event.dart';
import '../bloc/meter_reading/meter_reading_state.dart';
import '../widgets/common_widgets.dart';
import 'add_meter_reading_screen.dart';
import 'meter_reading_image_screen.dart';
import '../../injection.dart';

class MeterReadingsScreen extends StatelessWidget {
  final Meter meter;

  const MeterReadingsScreen({
    super.key,
    required this.meter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n?.readings ?? "Readings"),
            Text(
              meter.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Bouton de filtre
          BlocBuilder<MeterReadingBloc, MeterReadingState>(
            builder: (context, state) {
              if (state is MeterReadingsLoaded && state.readings.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: l10n?.filter ?? 'Filter',
                  onPressed: () => _showFilterOptions(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<MeterReadingBloc, MeterReadingState>(
        builder: (context, state) {
          if (state is MeterReadingLoading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n?.loadingReadings ?? "Loading readings..."),
                ],
              ),
            );
          } else if (state is MeterReadingsLoaded) {
            if (state.readings.isEmpty) {
              return _buildEmptyState(context);
            }
            
            return Column(
              children: [
                // Statistiques en haut de l'écran
                if (state.readings.length >= 2)
                  _buildConsumptionStatsCard(context, state.readings),
                
                // Liste des relevés
                Expanded(
                  child: _buildReadingsList(context, state.readings),
                ),
              ],
            );
          } else if (state is MeterReadingError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '${l10n?.error ?? "Error"}: ${state.message}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n?.tryAgain ?? "Try Again"),
                    onPressed: () {
                      context.read<MeterReadingBloc>().add(LoadMeterReadings(meter.id));
                    },
                  ),
                ],
              ),
            );
          }
          
          return Center(
            child: Text(l10n?.noReadingsAvailable ?? 'No readings available'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddReading(context),
        icon: const Icon(Icons.add),
        label: Text(l10n?.addReading ?? 'Add Reading'),
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
              Icons.speed,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.noReadingsAvailable ?? 'No readings available',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              l10n?.addReadingToStart ?? 'Add your first reading to start tracking consumption',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n?.addFirstReading ?? 'Add Your First Reading'),
            onPressed: () => _navigateToAddReading(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionStatsCard(BuildContext context, List<MeterReading> readings) {
    final l10n = AppLocalizations.of(context);
    final numberFormat = NumberFormat('#,##0.00');
    
    // Calculate total consumption
    double totalConsumption = 0;
    for (int i = 0; i < readings.length - 1; i++) {
      final current = readings[i];
      final previous = readings[i + 1];
      final consumption = current.value - previous.value;
      if (consumption > 0) {
        totalConsumption += consumption;
      }
    }
    
    // Calculate latest consumption
    final latestConsumption = readings.length > 1 
        ? readings[0].value - readings[1].value 
        : 0;
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.consumptionStats ?? 'Consumption Statistics',
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
                    label: l10n?.totalConsumption ?? 'Total Consumption',
                    value: '${numberFormat.format(totalConsumption)} ${l10n?.kWh ?? "kWh"}',
                    icon: Icons.list_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: CommonWidgets.buildEnhancedStatIndicator(
                    context: context,
                    label: l10n?.latestReading ?? 'Latest Reading',
                    value: numberFormat.format(readings.isNotEmpty ? readings.first.value : 0),
                    icon: Icons.speed,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Expanded(
                  child: CommonWidgets.buildEnhancedStatIndicator(
                    context: context,
                    label: l10n?.lastConsumption ?? 'Last Consumption',
                    value: '${numberFormat.format(latestConsumption)} ${l10n?.kWh ?? "kWh"}',
                    icon: Icons.bolt,
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

  Widget _buildReadingsList(BuildContext context, List<MeterReading> readings) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final numberFormat = NumberFormat('#,##0.00');
    final l10n = AppLocalizations.of(context);

    return ListView.builder(
      itemCount: readings.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemBuilder: (context, index) {
        final reading = readings[index];
        final previousReading =
            index < readings.length - 1 ? readings[index + 1] : null;
        final consumption = previousReading != null
            ? reading.value - previousReading.value
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            children: [
              // En-tête du relevé
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      reading.isVerified ? Colors.green : Colors.orange,
                  child: Icon(
                    reading.isVerified ? Icons.check : Icons.pending,
                    color: Colors.white,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      numberFormat.format(reading.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n?.kWh ?? 'kWh',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${l10n?.date ?? "Date"}: ${dateFormat.format(reading.readingDate)}'),
                    if (consumption != null && consumption > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${l10n?.consumption ?? "Consumption"}: ${numberFormat.format(consumption)} ${l10n?.kWh ?? "kWh"}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton<void>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: l10n?.options ?? 'Options',
                  itemBuilder: (context) => [
                    PopupMenuItem<void>(
                      child: Row(
                        children: [
                          const Icon(Icons.image, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n?.viewImage ?? 'View Image'),
                        ],
                      ),
                      onTap: () => _showReadingImage(context, reading),
                    ),
                    if (!reading.isVerified)
                      PopupMenuItem<void>(
                        child: Row(
                          children: [
                            const Icon(Icons.verified, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n?.verifyReading ?? 'Verify Reading'),
                          ],
                        ),
                        onTap: () => _verifyReading(context, reading),
                      ),
                    PopupMenuItem<void>(
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 20, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.delete ?? 'Delete',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                      onTap: () => _showDeleteDialog(context, reading),
                    ),
                  ],
                ),
              ),
              
              // Afficher l'image du relevé
              if (reading.imageUrl.isNotEmpty)
                InkWell(
                  onTap: () => _showReadingImage(context, reading),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      image: DecorationImage(
                        image: FileImage(File(reading.imageUrl)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              
              // Notes (si présentes)
              if (reading.notes != null && reading.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reading.notes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showFilterOptions(BuildContext context) {
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
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n?.filterReadings ?? 'Filter Readings',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n?.lastMonth ?? 'Last Month'),
              onTap: () {
                Navigator.pop(context);
                // Ajouter la logique de filtrage
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(l10n?.last3Months ?? 'Last 3 Months'),
              onTap: () {
                Navigator.pop(context);
                // Ajouter la logique de filtrage
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_month),
              title: Text(l10n?.lastYear ?? 'Last Year'),
              onTap: () {
                Navigator.pop(context);
                // Ajouter la logique de filtrage
              },
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: Text(l10n?.allTime ?? 'All Time'),
              onTap: () {
                Navigator.pop(context);
                // Ajouter la logique de filtrage
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReadingImage(
      BuildContext context, MeterReading reading) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => MeterReadingImageScreen(
          imageFile: File(reading.imageUrl),
          initialReading: reading.value.toString(),
        ),
      ),
    );
  }

  Future<void> _verifyReading(
      BuildContext context, MeterReading reading) async {
    final l10n = AppLocalizations.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.verifyReading ?? 'Verify Reading'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              l10n?.verifyReadingConfirmation ??
              'Are you sure you want to verify this reading? This action cannot be undone.',
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(l10n?.verify ?? 'Verify'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Afficher un indicateur de chargement
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
              Text(l10n?.processing ?? 'Processing...'),
            ],
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      final now = DateTime.now();
      final readingModel = MeterReadingModel(
        id: reading.id,
        meterId: reading.meterId,
        value: reading.value,
        imageUrl: reading.imageUrl,
        readingDate: reading.readingDate,
        isVerified: true,
        createdAt: now,
        notes: reading.notes,
        consumption: reading.consumption,
      );
      context.read<MeterReadingBloc>().add(VerifyMeterReading(readingModel));
    }
  }

  Future<void> _showDeleteDialog(
      BuildContext context, MeterReading reading) async {
    final l10n = AppLocalizations.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.confirmDelete ?? 'Delete Reading'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              l10n?.deleteReadingConfirmation ??
              'Are you sure you want to delete this reading? This action cannot be undone.',
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
      // Afficher un indicateur de chargement
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
      
      context.read<MeterReadingBloc>().add(DeleteMeterReading(reading.id));
    }
  }

  void _navigateToAddReading(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => BlocProvider(
          create: (context) => getIt<MeterReadingBloc>(),
          child: AddMeterReadingScreen(meter: meter),
        ),
      ),
    );
  }
}