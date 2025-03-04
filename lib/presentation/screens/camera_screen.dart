import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    try {
      final hasPermission = await Permission.camera.request();
      if (!hasPermission.isGranted) {
        if (!mounted) return;
        final BuildContext currentContext = this.context;
        final l10n = AppLocalizations.of(currentContext);
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(l10n?.cameraPermissionRequired ?? 'Camera permission is required'),
          ),
        );
        return;
      }

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
      if (!mounted) return;
      final BuildContext currentContext = this.context;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(currentContext)?.error ?? 'Error initializing camera'
          ),
        ),
      );
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
  Widget build(BuildContext context) {
    final BuildContext currentContext = this.context;
    final l10n = AppLocalizations.of(currentContext);
    
    if (!_isInitialized || _controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n?.scanReading ?? 'Scan Reading'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n?.processingImage ?? 'Processing...')
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.scanReading ?? 'Scan Reading'),
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
                  icon: Icon(
                    _controller!.value.flashMode == FlashMode.off
                      ? Icons.flash_off
                      : Icons.flash_on,
                  ),
                  onPressed: () async {
                    try {
                      final FlashMode currentMode = _controller!.value.flashMode;
                      await _controller!.setFlashMode(
                        currentMode == FlashMode.off ? FlashMode.torch : FlashMode.off,
                      );
                      setState(() {});
                    } catch (e) {
                      debugPrint('Error toggling flash: $e');
                    }
                  },
                ),
                FloatingActionButton(
                  onPressed: () async {
                    try {
                      final imagePath = await _takePicture();
                      if (imagePath != null && mounted) {
                        Navigator.pop(currentContext, imagePath);
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(
                          content: Text(l10n?.error ?? 'Error taking picture'),
                        ),
                      );
                    }
                  },
                  tooltip: l10n?.takePhoto ?? 'Take Photo',
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