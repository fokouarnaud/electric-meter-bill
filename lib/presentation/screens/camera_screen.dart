import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<String?> _takePicture() async {
    if (!_isInitialized || _controller == null) return null;

    try {
      final XFile image = await _controller!.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final String name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = '${directory.path}/$name';
      
      // Copy the image to the app's directory
      await image.saveTo(path);
      return path;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Meter Reading'),
      ),
      body: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.flash_on),
                  onPressed: () async {
                    final FlashMode currentMode = _controller!.value.flashMode;
                    await _controller!.setFlashMode(
                      currentMode == FlashMode.off ? FlashMode.torch : FlashMode.off,
                    );
                    setState(() {});
                  },
                ),
                FloatingActionButton(
                  onPressed: () async {
                    final imagePath = await _takePicture();
                    if (imagePath != null && mounted) {
                      Navigator.pop(context, imagePath);
                    }
                  },
                  child: const Icon(Icons.camera),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}