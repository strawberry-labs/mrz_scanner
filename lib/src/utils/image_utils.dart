import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Added for Uint8List
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:image/image.dart' as imglib; // Import image package

// Adapted NV21 conversion function
imglib.Image _convertNV21(InputImage image) {
  final width = image.metadata!.size.width.toInt();
  final height = image.metadata!.size.height.toInt();
  final yuvBytes = image.bytes!; // Assuming InputImage.bytes contains NV21 data

  // Create an image directly using the image package's NV21 support if available,
  // otherwise, fall back to manual conversion.
  // NOTE: The 'image' package might have direct NV21 support, check its docs.
  // For now, using manual conversion based on provided logic.

  final outImg =
      imglib.Image(width: width, height: height); // Create Image instance
  final int frameSize = width * height;

  for (int j = 0, yp = 0; j < height; j++) {
    int uvp = frameSize + (j >> 1) * width, u = 0, v = 0;
    for (int i = 0; i < width; i++, yp++) {
      int y = (0xff & yuvBytes[yp]) - 16;
      if (y < 0) y = 0;
      if ((i & 1) == 0) {
        // Adjust UV offset calculation if needed, assuming interleaved V then U plane
        v = (0xff & yuvBytes[uvp++]) - 128;
        u = (0xff & yuvBytes[uvp++]) - 128;
      }
      int y1192 = 1192 * y;
      int r = (y1192 + 1634 * v);
      int g = (y1192 - 833 * v - 400 * u);
      int b = (y1192 + 2066 * u);

      // Clamp values
      r = r.clamp(0, 262143);
      g = g.clamp(0, 262143);
      b = b.clamp(0, 262143);

      // Assign pixel with corrections for bit shifts from original logic
      outImg.setPixelRgb(i, j, ((r << 6) & 0xff0000) >> 16,
          ((g >> 2) & 0xff00) >> 8, (b >> 10) & 0xff);
    }
  }

  // Handle rotation if necessary based on image.metadata.rotation
  // Example: if (image.metadata?.rotation == InputImageRotation.rotation90deg) ...
  // For simplicity, assuming rotation handled elsewhere or not needed for compression format.

  return outImg;
}

/// Takes an ML-Kit [InputImage], converts if necessary, compresses, and returns a Base64 string.
Future<String> inputImageToBase64(InputImage originalImage) async {
  Uint8List bytesToCompress;
  final format = originalImage.metadata?.format;
  final rotation = originalImage.metadata?.rotation.name ?? 'unknown';
  final size = originalImage.metadata?.size;
  debugPrint(
      'Attempting to compress image. Format: ${format?.name ?? 'unknown'}, Rotation: $rotation, Size: $size');

  if (format == InputImageFormat.nv21 && originalImage.bytes != null) {
    debugPrint('NV21 format detected. Converting to JPEG before compression.');
    try {
      // 1. Convert NV21 to Image object
      imglib.Image convertedImage = _convertNV21(originalImage);

      // 2. Encode Image object to JPEG bytes
      bytesToCompress = Uint8List.fromList(
          imglib.encodeJpg(convertedImage, quality: 85)); // Encode to JPEG
      debugPrint(
          'NV21 converted to JPEG. Size: ${(bytesToCompress.length / 1024).toStringAsFixed(2)}KB');
    } catch (e) {
      debugPrint('Error during NV21 conversion/encoding: $e');
      throw Exception('Failed to convert NV21 image');
    }
  } else if (originalImage.bytes != null) {
    debugPrint('Using original bytes for compression.');
    bytesToCompress = originalImage.bytes!;
  } else if (originalImage.filePath != null) {
    debugPrint('Reading bytes from file path for compression.');
    bytesToCompress = await File(originalImage.filePath!).readAsBytes();
  } else {
    throw Exception('No image data available in InputImage');
  }

  debugPrint(
      'Bytes before compression: ${(bytesToCompress.length / (1024)).toStringAsFixed(2)}KB');

  // 2) Compress (either original bytes or converted JPEG bytes)
  final Uint8List? compressed = await FlutterImageCompress.compressWithList(
    bytesToCompress, // Use the prepared bytes
    minWidth: 800,
    minHeight: 600,
    quality: 70,
    // Consider format: CompressFormat.jpeg if needed, default is often JPEG
  );

  if (compressed == null) {
    // Add more details if compression fails
    debugPrint('FlutterImageCompress.compressWithList returned null.');
    throw Exception('Image compression failed');
  }

  debugPrint(
      'Bytes after compression: ${(compressed.length / 1024).toStringAsFixed(2)}KB');

  // 3) Encode final compressed bytes
  return base64Encode(compressed);
}
