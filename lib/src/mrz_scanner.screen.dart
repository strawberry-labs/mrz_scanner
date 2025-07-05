import 'dart:async';

import 'package:flutter/material.dart' hide Preview;
import 'package:flutter/services.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:mrz_scanner/src/camera_overlay_widget.dart';
import 'package:mrz_scanner/src/extensions/mlkit_extension.dart';
import 'package:mrz_scanner/src/models/process_isolate.dart';
import 'package:mrz_scanner/src/models/process_text_image.model.dart';
import 'package:mrz_scanner/src/mrz_navigator.dart';

class MRZScannerScreen extends StatefulWidget {
  final ScanMode scanMode;
  final bool enableVibration;
  
  const MRZScannerScreen({
    super.key,
    this.scanMode = ScanMode.back,
    this.enableVibration = true,
  });

  @override
  State<MRZScannerScreen> createState() => _MRZScannerScreenState();
}

class _MRZScannerScreenState extends State<MRZScannerScreen> {
  final _imageStreamController = StreamController<AnalysisImage>.broadcast();
  StreamSubscription<AnalysisImage>? processImageSubscription;
  StreamSubscription<String>? resultListener;
  PhotoCameraState? cameraState;
  ProcessIsolate processIsolate = ProcessIsolate();
  ProcessTextImage processTextImage = ProcessTextImage();
  bool isTorchOn = false;

  @override
  void dispose() {
    _cleanupResources();
    // Re-enable all orientations when leaving the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Lock orientation for a consistent scanning experience
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
    ]);
    
    // Set vibration preference
    processIsolate.enableVibration = widget.enableVibration;
    
    processIsolate.createIsolate();
    _analysisImageStream();
    _resultListener();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        CameraAwesomeBuilder.custom(
          onImageForAnalysis: (img) async {
            if (!_imageStreamController.isClosed) {
              _imageStreamController.add(img);
            }
          },
          imageAnalysisConfig: AnalysisConfig(maxFramesPerSecond: 5),
          sensorConfig:
              SensorConfig.single(aspectRatio: CameraAspectRatios.ratio_16_9),
          saveConfig: SaveConfig.photo(),
          builder: (state, preview) {
            return state.when(
              onPhotoMode: (photoCameraState) => CameraOverlayWidget(
                photoCameraState: photoCameraState,
                onPhotoCameraState: _setCameraStatet,
                scanMode: widget.scanMode,
              ),
              onVideoMode: (_) => const SizedBox.shrink(),
              onPreparingCamera: (state) => const SizedBox.shrink(),
            );
          },
        ),
        Positioned(
          top: 40, // Adjust the top position as needed
          left: 20, // Adjust the left position as needed
          child: GestureDetector(
            onTap: () {
              // Handle return button tap (e.g., navigate back)
              Navigator.pop(context);
            },
            child: Container(
              width: 50, // Adjust the size as needed
              height: 50, // Adjust the size as needed
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 24, // Adjust the icon size as needed
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 40, // Adjust the top position as needed
          left:
              90, // Adjust the left position to place it beside the back button
          child: GestureDetector(
            onTap: () {
              // Add your torch functionality here
              if (isTorchOn) {
                cameraState?.sensorConfig.setFlashMode(FlashMode.none);
              } else {
                cameraState?.sensorConfig.setFlashMode(FlashMode.always);
              }
              setState(() {
                isTorchOn = !isTorchOn;
              });
            },
            child: Container(
              width: 50, // Adjust the size as needed
              height: 50, // Adjust the size as needed
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isTorchOn
                      ? Icons.flashlight_off
                      : Icons.flashlight_on, // Use a flashlight icon
                  color: Colors.black,
                  size: 24, // Adjust the icon size as needed
                ),
              ),
            ),
          ),
        ),
      ],
    ));
  }

  void _setCameraStatet(PhotoCameraState state) {
    cameraState ??= state;
  }

  void _analysisImageStream() {
    // Simplified: no more filtering logic needed
    // The rotation is now corrected at the source in mlkit_extension.dart
    processImageSubscription = _imageStreamController.stream.listen((image) {
      processIsolate.sendImage(image.toInputImage(), widget.scanMode);
    });
  }

  void _resultListener() {
    resultListener = processIsolate.resultListener().listen((mrzData) {
      // debugPrint("\n\n----------------------MRZ DATA $mrzData");
      _cleanupResources();
      if (mounted) {
        Navigator.pop(context, mrzData);
      }
    });
  }

  void _cleanupResources() {
    processImageSubscription?.cancel();
    processIsolate.closeIsolate();
    if (!_imageStreamController.isClosed) {
      _imageStreamController.close();
    }
    // processTextImage.dispose(); // REMOVED: dispose method no longer exists
    resultListener?.cancel();
  }
}
