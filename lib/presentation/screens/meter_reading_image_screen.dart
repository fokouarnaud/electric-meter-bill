// lib/presentation/screens/meter_reading_image_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

class _MeterReadingImageScreenState extends State<MeterReadingImageScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  bool _isProcessing = true;
  String? _recognizedText;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  TextBlock? _selectedBlock;
  double _imageWidth = 0;
  double _imageHeight = 0;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialReading ?? '';

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });

    _processImage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
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
      TextBlock? selectedBlock;

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            final text = element.text;
            // Essayer de parser comme un nombre et trouver la lecture de compteur la plus probable
            final number = double.tryParse(text.replaceAll(',', '.'));
            if (number != null) {
              if (bestMatchValue == null || number > bestMatchValue) {
                bestMatchValue = number;
                bestMatch = text;
                selectedBlock = block;
              }
            }
          }
        }
      }

      setState(() {
        _selectedBlock = selectedBlock;
        if (bestMatch != null) {
          _recognizedText = bestMatch;
          _controller.text = bestMatch;
          _animationController.forward();
        }
        _isProcessing = false;
      });

      await textRecognizer.close();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  void _onImageLoad(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      _imageWidth = imageInfo.image.width.toDouble();
      _imageHeight = imageInfo.image.height.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.verifyReading ?? 'Verify Reading'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check),
            label: Text(l10n?.confirm ?? 'Confirm'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context, _controller.text);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withAlpha(76),
                child: Text(
                  l10n?.verifyReadingInstructions ??
                      'Verify the reading value extracted from the meter image.'
                          ' You can adjust it if needed.',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),

              // Image avec overlay
              Stack(
                children: [
                  // Image
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.file(
                      widget.imageFile,
                      fit: BoxFit.cover,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                        if (frame == null) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          );
                        }

                        if (!wasSynchronouslyLoaded) {
                          // Obtenir les dimensions de l'image
                          Image image = Image.file(widget.imageFile);
                          image.image
                              .resolve(ImageConfiguration.empty)
                              .addListener(ImageStreamListener(_onImageLoad));
                        }

                        return child;
                      },
                    ),
                  ),

                  // Overlay pour le texte reconnu
                  if (_selectedBlock != null &&
                      _imageWidth > 0 &&
                      _imageHeight > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: TextBlockPainter(
                            block: _selectedBlock!,
                            imageWidth: _imageWidth,
                            imageHeight: _imageHeight,
                            viewportWidth: MediaQuery.of(context).size.width,
                            viewportHeight:
                                MediaQuery.of(context).size.width * 9 / 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Résultat de la reconnaissance
              _buildRecognitionResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecognitionResultCard() {
    final l10n = AppLocalizations.of(context);

    if (_isProcessing) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n?.processingImage ?? 'Processing image...'),
              const SizedBox(height: 8),
              Text(
                l10n?.processingImageHint ?? 'This may take a moment',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_error != null) {
      return Card(
        margin: const EdgeInsets.all(16),
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.errorProcessingImage ?? 'Error processing image',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n?.tryAgain ?? 'Try Again'),
                onPressed: () {
                  setState(() {
                    _isProcessing = true;
                    _error = null;
                  });
                  _processImage();
                },
              ),
            ],
          ),
        ),
      );
    } else {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Card(
          margin: const EdgeInsets.all(16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône
                Row(
                  children: [
                    Icon(
                      _recognizedText != null
                          ? Icons.check_circle
                          : Icons.help_outline,
                      color: _recognizedText != null
                          ? Colors.green
                          : Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _recognizedText != null
                            ? (l10n?.valueRecognized ?? 'Value Recognized')
                            : (l10n?.enterManually ?? 'Enter value manually'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _recognizedText != null
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Champ pour la valeur reconnue
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: l10n?.readingValue ?? 'Reading Value (kWh)',
                    helperText: _recognizedText != null
                        ? (l10n?.autoRecognized ?? 'Auto-recognized from image')
                        : (l10n?.manualEntry ??
                            'Please enter the reading value manually'),
                    prefixIcon: const Icon(Icons.speed),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (_recognizedText != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n?.recognizedExplanation ??
                        'We recognized this value from your photo. '
                        'Edit if it\'s incorrect.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
  }
}

class TextBlockPainter extends CustomPainter {
  final TextBlock block;
  final double imageWidth;
  final double imageHeight;
  final double viewportWidth;
  final double viewportHeight;

  TextBlockPainter({
    required this.block,
    required this.imageWidth,
    required this.imageHeight,
    required this.viewportWidth,
    required this.viewportHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withAlpha(76)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Calculate scale ratio
    final ratioX = viewportWidth / imageWidth;
    final ratioY = viewportHeight / imageHeight;

    // Convert block bounding box to viewport coordinates
    final rect = block.boundingBox;
    final scaledRect = Rect.fromLTRB(
      rect.left * ratioX,
      rect.top * ratioY,
      rect.right * ratioX,
      rect.bottom * ratioY,
    );

    // Draw semi-transparent background
    canvas.drawRect(scaledRect, paint);

    // Draw border
    canvas.drawRect(scaledRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
