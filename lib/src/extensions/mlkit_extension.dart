import 'dart:io' show Platform; // Import for platform checking
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

extension MLKitUtils on AnalysisImage {
  InputImage toInputImage() {
    final planeData =
        when(nv21: (img) => img.planes, bgra8888: (img) => img.planes)?.map(
      (plane) {
        return plane.bytesPerRow;
      },
    ).first;

    return when(nv21: (image) {
      return InputImage.fromBytes(
        bytes: image.bytes,
        metadata: InputImageMetadata(
          rotation: inputImageRotation,
          format: InputImageFormat.nv21,
          bytesPerRow: planeData!,
          size: image.size,
        ),
      );
    }, bgra8888: (image) {
      final inputImageData = InputImageMetadata(
        size: size,
        rotation: inputImageRotation,
        format: inputImageFormat,
        bytesPerRow: planeData!,
      );

      return InputImage.fromBytes(
        bytes: image.bytes,
        metadata: inputImageData,
      );
    })!;
  }

  /// Corrects the rotation for iOS and provides a consistent value to ML Kit.
  InputImageRotation get inputImageRotation {
    // On iOS, the camera orientation is rotated by 90 degrees compared to Android.
    // We need to apply a correction to normalize the rotation value.
    if (Platform.isIOS) {
      // Add 90 degrees to the reported rotation on iOS.
      switch (rotation) {
        case InputAnalysisImageRotation.rotation0deg:
          return InputImageRotation.rotation90deg;
        case InputAnalysisImageRotation.rotation90deg:
          return InputImageRotation.rotation180deg;
        case InputAnalysisImageRotation.rotation180deg:
          return InputImageRotation.rotation270deg;
        case InputAnalysisImageRotation.rotation270deg:
          return InputImageRotation.rotation0deg;
      }
    }

    // For Android, the rotation is already correct.
    return InputImageRotation.values.byName(rotation.name);
  }

  InputImageFormat get inputImageFormat {
    switch (format) {
      case InputAnalysisImageFormat.bgra8888:
        return InputImageFormat.bgra8888;
      case InputAnalysisImageFormat.nv21:
        return InputImageFormat.nv21;
      default:
        return InputImageFormat.yuv420;
    }
  }
}
