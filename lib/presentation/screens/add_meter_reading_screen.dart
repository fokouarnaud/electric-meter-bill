import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/meter_reading_model.dart';
import '../../domain/entities/meter.dart';
import '../bloc/meter_reading/meter_reading_bloc.dart';
import '../bloc/meter_reading/meter_reading_event.dart';
import '../bloc/meter_reading/meter_reading_state.dart';
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

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Meter Reading'),
      ),
      body: BlocListener<MeterReadingBloc, MeterReadingState>(
        listener: (context, state) {
          if (state is MeterReadingOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context);
          } else if (state is MeterReadingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageSection(),
                const SizedBox(height: 16),
                _buildReadingValueField(),
                const SizedBox(height: 16),
                _buildDatePicker(),
                const SizedBox(height: 16),
                _buildNotesField(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitReading,
                  child: const Text('Save Reading'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imageFile != null) ...[
              Image.file(
                _imageFile!,
                height: 200,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _takePicture(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _takePicture(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose Photo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingValueField() {
    return TextFormField(
      controller: _valueController,
      decoration: InputDecoration(
        labelText: 'Reading Value (kWh)',
        suffixIcon: _recognizedValue != null
            ? Tooltip(
                message: 'OCR detected value',
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a reading value';
        }
        final number = double.tryParse(value);
        if (number == null || number < 0) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Reading Date',
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_readingDate.day}/${_readingDate.month}/${_readingDate.year}',
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (Optional)',
        alignLabelWithHint: true,
      ),
      maxLines: 3,
    );
  }

  Future<void> _takePicture(ImageSource source) async {
    try {
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
              _recognizedValue = result;
              _valueController.text = result;
            });
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _readingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _readingDate = picked;
      });
    }
  }

  void _submitReading() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please take a photo of the meter')),
        );
        return;
      }

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
