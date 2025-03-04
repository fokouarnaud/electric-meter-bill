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
    return Scaffold(
      appBar: AppBar(
        title: Text('${AppLocalizations.of(context)?.readings ?? "Readings"} - ${meter.name}'),
      ),
      body: BlocBuilder<MeterReadingBloc, MeterReadingState>(
        builder: (context, state) {
          if (state is MeterReadingLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MeterReadingsLoaded) {
            return _buildReadingsList(context, state.readings);
          } else if (state is MeterReadingError) {
            return Center(
              child: Text('${AppLocalizations.of(context)?.error ?? "Error"}: ${state.message}')
            );
          }
          return Center(
            child: Text(AppLocalizations.of(context)?.meterReadings ?? 'No readings available')
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => getIt<MeterReadingBloc>(),
              child: AddMeterReadingScreen(meter: meter),
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReadingsList(BuildContext context, List<MeterReading> readings) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final numberFormat = NumberFormat('#,##0.00');

    return ListView.builder(
      itemCount: readings.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final reading = readings[index];
        final previousReading =
            index < readings.length - 1 ? readings[index + 1] : null;
        final consumption = previousReading != null
            ? reading.value - previousReading.value
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      reading.isVerified ? Colors.green : Colors.orange,
                  child: Icon(
                    reading.isVerified ? Icons.check : Icons.pending,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  '${numberFormat.format(reading.value)} kWh',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${AppLocalizations.of(context)?.readingDate ?? "Date"}: ${dateFormat.format(reading.readingDate)}'),
                    if (consumption != null)
                      Text(
                        '${AppLocalizations.of(context)?.consumption ?? "Consumption"}: ${numberFormat.format(consumption)} ${AppLocalizations.of(context)?.kWh ?? "kWh"}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (reading.notes != null && reading.notes!.isNotEmpty)
                      Text('${AppLocalizations.of(context)?.notes ?? "Notes"}: ${reading.notes}'),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text(AppLocalizations.of(context)?.viewImage ?? 'View Image'),
                      onTap: () => _showReadingImage(context, reading),
                    ),
                    if (!reading.isVerified)
                      PopupMenuItem(
                        child: Text(AppLocalizations.of(context)?.verifyReading ?? 'Verify Reading'),
                        onTap: () => _verifyReading(context, reading),
                      ),
                    PopupMenuItem(
                      child: Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
                      onTap: () => _showDeleteDialog(context, reading),
                    ),
                  ],
                ),
              ),
              if (reading.imageUrl.isNotEmpty)
                InkWell(
                  onTap: () => _showReadingImage(context, reading),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      image: DecorationImage(
                        image: FileImage(File(reading.imageUrl)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showReadingImage(
      BuildContext context, MeterReading reading) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeterReadingImageScreen(
          imageFile: File(reading.imageUrl),
          initialReading: reading.value.toString(),
        ),
      ),
    );
  }

  Future<void> _verifyReading(
      BuildContext context, MeterReading reading) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.verifyReading ?? 'Verify Reading'),
        content: Text(
          AppLocalizations.of(context)?.verifyReadingConfirmation ??
          'Are you sure you want to verify this reading? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)?.verifyReading ?? 'Verify'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.confirmDelete ?? 'Delete Reading'),
        content: Text(
          AppLocalizations.of(context)?.deleteReadingConfirmation ??
          'Are you sure you want to delete this reading? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<MeterReadingBloc>().add(DeleteMeterReading(reading.id));
    }
  }
}
