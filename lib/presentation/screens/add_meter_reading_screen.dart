// lib/presentation/screens/add_meter_reading_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/meter_reading_model.dart';
import '../../domain/entities/meter.dart';
import '../bloc/meter_reading/meter_reading_bloc.dart';
import '../bloc/meter_reading/meter_reading_event.dart';
import '../bloc/meter_reading/meter_reading_state.dart';
import '../widgets/common_widgets.dart';
import 'meter_reading_image_screen.dart';

class AddMeterReadingScreen extends StatefulWidget {
  final Meter meter;
  final String? meterId;

  const AddMeterReadingScreen({
    super.key,
    required this.meter,
    this.meterId,
  });

  @override
  State<AddMeterReadingScreen> createState() => _AddMeterReadingScreenState();
}

class _AddMeterReadingScreenState extends State<AddMeterReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _readingDate = DateTime.now();
  File? _imageFile;
  String? _recognizedValue;
  bool _isLoading = false;

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n?.addReading ?? 'Add Meter Reading'),
            Text(
              widget.meter.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: BlocListener<MeterReadingBloc, MeterReadingState>(
        listener: (context, state) {
          if (state is MeterReadingOperationSuccess) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          } else if (state is MeterReadingError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Étape 1: Capture d'image
                  CommonWidgets.buildStepCard(
                    context: context,
                    stepNumber: 1,
                    title: l10n?.takePhoto ?? 'Take a Photo',
                    content: _buildImageSection(),
                  ),
                  
                  // Étape 2: Valeur du relevé
                  CommonWidgets.buildStepCard(
                    context: context,
                    stepNumber: 2,
                    title: l10n?.enterReadingValue ?? 'Enter Reading Value',
                    content: _buildReadingValueField(),
                  ),
                  
                  // Étape 3: Date du relevé
                  CommonWidgets.buildStepCard(
                    context: context,
                    stepNumber: 3,
                    title: l10n?.selectDate ?? 'Select Date',
                    content: _buildDatePicker(),
                  ),
                  
                  // Étape 4: Notes (optionnel)
                  CommonWidgets.buildStepCard(
                    context: context,
                    stepNumber: 4,
                    title: l10n?.addNotes ?? 'Add Notes',
                    content: _buildNotesField(),
                    isOptional: true,
                  ),
                  
                  // Bouton de sauvegarde
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitReading,
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 20, 
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                      label: Text(
                        _isLoading
                          ? (l10n?.saving ?? 'Saving...')
                          : (l10n?.saveReading ?? 'Save Reading'),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            
            // Indicateur de chargement
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final l10n = AppLocalizations.of(context);
    
    if (_imageFile != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _imageFile!,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _takePicture(ImageSource.camera),
                icon: const Icon(Icons.refresh),
                label: Text(l10n?.retakePhoto ?? 'Retake Photo'),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.takePhotoInstructions ?? 'Take a photo of your meter',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _takePicture(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(l10n?.takePhoto ?? 'Take Photo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _takePicture(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text(l10n?.choosePhoto ?? 'Choose Photo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildReadingValueField() {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recognizedValue != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.valueRecognized ?? 'Value recognized',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n?.autoRecognizedValue != null
                            ? l10n!.autoRecognizedValue(_recognizedValue!)
                            : 'We detected the value: $_recognizedValue',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        TextFormField(
          controller: _valueController,
          decoration: InputDecoration(
            labelText: l10n?.readingValue ?? 'Reading Value (kWh)',
            hintText: l10n?.enterValue ?? 'Enter the meter reading value',
            prefixIcon: const Icon(Icons.speed),
            suffixIcon: _recognizedValue != null
                ? Tooltip(
                    message: l10n?.useRecognizedValue ?? 'Use recognized value',
                    child: IconButton(
                      icon: const Icon(Icons.auto_awesome),
                      onPressed: () {
                        _valueController.text = _recognizedValue!;
                      },
                    ),
                  )
                : null,
          ),
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 18),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n?.requiredField ?? 'Please enter a reading value';
            }
            final number = double.tryParse(value);
            if (number == null || number < 0) {
              return l10n?.invalidReadingValue ?? 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    final l10n = AppLocalizations.of(context);
    final localizedDate = "${_readingDate.day}/${_readingDate.month}/${_readingDate.year}";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.currentSelectedDate ?? 'Currently selected date:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 16),
                Text(
                  localizedDate,
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Text(
                  l10n?.tapToChange ?? 'Tap to change',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    final l10n = AppLocalizations.of(context);
    
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: l10n?.notes ?? 'Notes',
        hintText: l10n?.notesHint ?? 'Add any additional information',
        alignLabelWithHint: true,
        prefixIcon: const Icon(Icons.note),
      ),
      maxLines: 3,
      minLines: 3,
    );
  }

  Future<void> _takePicture(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    
    try {
      setState(() => _isLoading = true);
      
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isLoading = false;
        });

        if (context.mounted) {
          // Afficher un snackbar pour indiquer que l'OCR est en cours
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
                  const SizedBox(width: 12),
                  Text(l10n?.analyzingImage ?? 'Analyzing image...'),
                ],
              ),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Navigate to image verification screen
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => MeterReadingImageScreen(
                imageFile: _imageFile!,
              ),
            ),
          );

          if (result != null) {
            setState(() {
              _recognizedValue = result;
              _valueController.text = result;
            });
          }
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.errorCapturingImage != null 
                ? l10n!.errorCapturingImage(e.toString())
                : 'Error capturing image: ${e.toString()}'
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final l10n = AppLocalizations.of(context);
    
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _readingDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: l10n?.selectDate ?? 'Select reading date',
      cancelText: l10n?.cancel ?? 'Cancel',
      confirmText: l10n?.confirm ?? 'Confirm',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _readingDate) {
      setState(() {
        _readingDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _readingDate.hour,
          _readingDate.minute,
        );
      });
    }
  }

  void _submitReading() {
    final l10n = AppLocalizations.of(context);
    
    if (_formKey.currentState?.validate() ?? false) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.pleaseAddPhoto ?? 'Please take a photo of the meter'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      
      final now = DateTime.now();
      final reading = MeterReadingModel(
        id: now.millisecondsSinceEpoch.toString(),
        meterId: widget.meter.id,
        value: double.parse(_valueController.text),
        imageUrl: _imageFile!.path,
        readingDate: _readingDate,
        isVerified: true,
        createdAt: now,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      context.read<MeterReadingBloc>().add(AddMeterReading(reading));
    }
  }
}