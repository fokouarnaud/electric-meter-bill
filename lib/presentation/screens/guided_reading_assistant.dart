// lib/presentation/screens/guided_reading_assistant.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../data/models/meter_reading_model.dart';
import '../../domain/entities/meter.dart';
import '../bloc/meter_reading/meter_reading_bloc.dart';
import '../bloc/meter_reading/meter_reading_event.dart';
import 'meter_reading_image_screen.dart';

class GuidedReadingAssistant extends StatefulWidget {
  final Meter meter;

  const GuidedReadingAssistant({super.key, required this.meter});

  @override
  State<GuidedReadingAssistant> createState() => _GuidedReadingAssistantState();
}

class _GuidedReadingAssistantState extends State<GuidedReadingAssistant> {
  int _currentStep = 0;
  final _steps = [
    'camera',    // Étape 1: Prendre photo
    'verify',    // Étape 2: Vérifier la valeur
    'date',      // Étape 3: Confirmer date
    'notes',     // Étape 4: Ajouter notes (optionnel)
    'confirm',   // Étape 5: Confirmer et sauvegarder
  ];
  
  // Données collectées
  File? _imageFile;
  String? _readingValue;
  DateTime _readingDate = DateTime.now();
  String? _notes;
  final _notesController = TextEditingController();
  bool _isLoading = false;
  
  @override
  void dispose() {
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
            Text(l10n?.guidedReading ?? 'Reading Assistant'),
            Text(
              widget.meter.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        leading: _currentStep > 0 
          ? BackButton(onPressed: _goToPreviousStep)
          : null,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Indicateur de progression
              _buildProgressIndicator(),
              
              // Contenu de l'étape actuelle
              Expanded(child: _buildCurrentStep()),
              
              // Boutons de navigation
              _buildNavigationButtons(),
            ],
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
    );
  }
  
  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: List.generate(
          _steps.length,
          (index) => Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              decoration: BoxDecoration(
                color: index <= _currentStep 
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCurrentStep() {
    final l10n = AppLocalizations.of(context);
    
    // Titre de l'étape actuelle
    String stepTitle;
    switch (_steps[_currentStep]) {
      case 'camera':
        stepTitle = l10n?.takePhoto ?? 'Take a Photo of the Meter';
        break;
      case 'verify':
        stepTitle = l10n?.verifyReading ?? 'Verify the Reading Value';
        break;
      case 'date':
        stepTitle = l10n?.confirmDate ?? 'Confirm Reading Date';
        break;
      case 'notes':
        stepTitle = l10n?.addNotes ?? 'Add Optional Notes';
        break;
      case 'confirm':
        stepTitle = l10n?.reviewAndSave ?? 'Review and Save';
        break;
      default:
        stepTitle = '';
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de l'étape
          Text(
            '${l10n?.step ?? 'Step'} ${_currentStep + 1}: $stepTitle',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Contenu de l'étape
          switch (_steps[_currentStep]) {
            'camera' => _buildCameraStep(),
            'verify' => _buildVerifyStep(),
            'date' => _buildDateStep(),
            'notes' => _buildNotesStep(),
            'confirm' => _buildConfirmStep(),
            _ => const SizedBox.shrink(),
          },
          
          // Espace en bas pour le scrolling
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  Widget _buildNavigationButtons() {
    final l10n = AppLocalizations.of(context);
    final isLastStep = _currentStep == _steps.length - 1;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n?.previous ?? 'Back'),
              onPressed: _goToPreviousStep,
            )
          else
            const SizedBox.shrink(),
          
          ElevatedButton.icon(
            icon: Icon(isLastStep ? Icons.save : Icons.arrow_forward),
            label: Text(
              isLastStep 
                ? (l10n?.saveReading ?? 'Save Reading') 
                : (l10n?.next ?? 'Next')
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
            ),
            onPressed: _canProceed() ? _goToNextStep : null,
          ),
        ],
      ),
    );
  }
  
  bool _canProceed() {
    switch (_steps[_currentStep]) {
      case 'camera':
        return _imageFile != null;
      case 'verify':
        return _readingValue != null && _readingValue!.isNotEmpty;
      case 'date':
        return true; // Date is always valid
      case 'notes':
        return true; // Notes are optional
      case 'confirm':
        return true; // Can always finish
      default:
        return false;
    }
  }
  
  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }
  
  void _goToNextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _saveReading();
    }
  }
  
  Widget _buildCameraStep() {
    final l10n = AppLocalizations.of(context);
    
    if (_imageFile != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _imageFile!,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.photoTaken ?? 'Photo taken successfully!',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _takePicture(ImageSource.camera),
            icon: const Icon(Icons.refresh),
            label: Text(l10n?.retake ?? 'Take another photo'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 200,
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
                    l10n?.takePhotoInstructions ?? 'Take a clear photo of your meter reading',
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _takePicture(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: Text(l10n?.takePhoto ?? 'Take Photo'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _takePicture(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: Text(l10n?.choosePhoto ?? 'Choose from Gallery'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.cameraTip ?? 'Tip: Make sure the numbers are clearly visible and well-lit.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }
  
  Widget _buildVerifyStep() {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Petite image pour rappel
        if (_imageFile != null)
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _imageFile!,
                  height: 80,
                  width: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n?.verifyValuePrompt ?? 'Verify or edit the reading value detected from your image.',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        
        const SizedBox(height: 24),
          
        // Champ pour la valeur
        TextField(
          decoration: InputDecoration(
            labelText: l10n?.meterReading ?? 'Meter Reading Value (kWh)',
            hintText: l10n?.enterValue ?? 'Enter the value shown on the meter',
            prefixIcon: const Icon(Icons.speed),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          controller: TextEditingController(text: _readingValue),
          onChanged: (value) {
            setState(() {
              _readingValue = value;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        Text(
          l10n?.verifyTip ?? 'Tip: Enter only the numbers before the decimal point if there is no decimal part.',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDateStep() {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.dateExplanation ?? 'When was this reading taken?',
          style: const TextStyle(fontSize: 16),
        ),
        
        const SizedBox(height: 24),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      l10n?.selectedDate ?? 'Selected Date',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  dateFormat.format(_readingDate),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.edit_calendar),
                  label: Text(l10n?.changeDate ?? 'Change Date'),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          l10n?.dateTip ?? 'Tip: Make sure the date is correct for accurate billing periods.',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildNotesStep() {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.notesExplanation ?? 'Add any additional information about this reading (optional).',
          style: const TextStyle(fontSize: 16),
        ),
        
        const SizedBox(height: 24),
        
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: l10n?.notes ?? 'Notes',
            hintText: l10n?.notesHint ?? 'E.g., "Meter reset", "Special circumstances", etc.',
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          onChanged: (value) {
            setState(() {
              _notes = value.isEmpty ? null : value;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        Text(
          l10n?.notesTip ?? 'Tip: Notes will be displayed on bills and reports.',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildConfirmStep() {
    final l10n = AppLocalizations.of(context);
    
    // Rien à afficher si les données manquent
    if (_imageFile == null || _readingValue == null) {
      return Center(
        child: Text(l10n?.missingData ?? 'Missing data. Please go back and complete previous steps.'),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.confirmPrompt ?? 'Please review the information below before saving.',
          style: const TextStyle(fontSize: 16),
        ),
        
        const SizedBox(height: 24),
        
        // Résumé de la lecture
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.summarize),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.readingSummary ?? 'Reading Summary',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const Divider(),
                
                // Image miniature
                if (_imageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _imageFile!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Informations
                _buildSummaryItem(
                  label: l10n?.meter ?? 'Meter',
                  value: widget.meter.name,
                  icon: Icons.electric_meter,
                ),
                
                _buildSummaryItem(
                  label: l10n?.readingValue ?? 'Reading Value',
                  value: '$_readingValue kWh',
                  icon: Icons.speed,
                ),
                
                _buildSummaryItem(
                  label: l10n?.date ?? 'Date',
                  value: DateFormat('dd/MM/yyyy').format(_readingDate),
                  icon: Icons.calendar_today,
                ),
                
                if (_notes != null && _notes!.isNotEmpty)
                  _buildSummaryItem(
                    label: l10n?.notes ?? 'Notes',
                    value: _notes!,
                    icon: Icons.note,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              _readingValue = result;
            });
            
            // Aller automatiquement à l'étape suivante
            _goToNextStep();
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
              l10n?.errorCapturingImage(e.toString()) ?? 
              'Error capturing image: ${e.toString()}',
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
  
 void _saveReading() {
    final l10n = AppLocalizations.of(context);
    
    if (_imageFile == null || _readingValue == null || _readingValue!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.missingData ?? 'Missing required data'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final double readingValue = double.parse(_readingValue!);
      final now = DateTime.now();
      
      final reading = MeterReadingModel(
        id: now.millisecondsSinceEpoch.toString(),
        meterId: widget.meter.id,
        value: readingValue,
        imageUrl: _imageFile!.path,
        readingDate: _readingDate,
        isVerified: true,
        createdAt: now,
        notes: _notes,
      );

      context.read<MeterReadingBloc>().add(AddMeterReading(reading));
      
      // Afficher message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.readingSaved ?? 'Reading saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Retourner à l'écran précédent
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.errorSavingReading(e.toString()) ?? 
          'Error saving reading: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}