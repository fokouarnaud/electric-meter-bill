//presentation/screens/meter_reading_image_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MeterReadingImageScreen extends StatefulWidget {
  final File imageFile;
  final String? initialReading;

  const MeterReadingImageScreen({
    super.key,
    required this.imageFile,
    this.initialReading,
  });

  @override
  State<MeterReadingImageScreen> createState() =>
      _MeterReadingImageScreenState();
}

class _MeterReadingImageScreenState extends State<MeterReadingImageScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isProcessing = true;
  String? _recognizedText;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialReading ?? '';
    _processImage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processImage() async {
    try {
      final inputImage = InputImage.fromFile(widget.imageFile);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      String? bestMatch;
      double? bestMatchValue;

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            final text = element.text;
            // Try to parse as number and find the most likely meter reading
            final number = double.tryParse(text.replaceAll(',', '.'));
            if (number != null) {
              if (bestMatchValue == null || number > bestMatchValue) {
                bestMatchValue = number;
                bestMatch = text;
              }
            }
          }
        }
      }

      setState(() {
        _recognizedText = bestMatch;
        if (bestMatch != null) {
          _controller.text = bestMatch;
        }
        _isProcessing = false;
      });

      textRecognizer.close();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Reading'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _controller.text);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            if (_isProcessing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Processing image...'),
                  ],
                ),
              )
            else if (_error != null)
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recognized Reading',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          labelText: 'Reading Value (kWh)',
                          helperText:
                              'Edit the value if the recognition is not accurate',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      if (_recognizedText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Original recognized text: $_recognizedText',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
