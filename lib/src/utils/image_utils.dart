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

  var outImg =
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

  // Note: Rotation correction is now handled at the ML Kit level
  // in mlkit_extension.dart, so we don't need to rotate the image here

  return outImg;
}

/// Calculates the overlay rectangle dimensions with 5.5:8.5 aspect ratio
/// This matches the camera overlay rectangle from camera_overlay_widget.dart
Map<String, double> calculateOverlayRect(double screenWidth, double screenHeight) {
  // 5.5:8.5 aspect ratio for landscape rectangle (height:width)
  const aspectRatio = 5.5 / 8.5; // height / width for landscape rectangle
  
  double rectWidth, rectHeight;
  final isPortrait = screenHeight > screenWidth;
  
  if (isPortrait) {
    // In portrait mode: fit the rectangle within screen bounds
    rectWidth = screenWidth * 0.85;
    rectHeight = rectWidth * aspectRatio;
    
    // If calculated height is too tall, adjust based on height
    if (rectHeight > screenHeight * 0.4) {
      rectHeight = screenHeight * 0.4;
      rectWidth = rectHeight / aspectRatio;
    }
  } else {
    // In landscape mode: maintain the aspect ratio
    rectWidth = screenWidth * 0.75;
    rectHeight = rectWidth * aspectRatio;
    
    // If calculated height is too tall, adjust based on height
    if (rectHeight > screenHeight * 0.6) {
      rectHeight = screenHeight * 0.6;
      rectWidth = rectHeight / aspectRatio;
    }
  }
  
  // Calculate center position
  final centerX = screenWidth / 2;
  final centerY = screenHeight / 2;
  
  return {
    'x': centerX - (rectWidth / 2),
    'y': centerY - (rectHeight / 2),
    'width': rectWidth,
    'height': rectHeight,
  };
}

/// Encodes an image to JPEG with consistent quality settings
Uint8List encodeToJpeg(imglib.Image image, {int quality = 85}) {
  return Uint8List.fromList(imglib.encodeJpg(image, quality: quality));
}

/// Crops an image to the overlay rectangle area
imglib.Image cropToOverlayRect(imglib.Image image) {
  imglib.Image processedImage;
  
  // Only rotate 90 degrees clockwise if NOT on iOS
  if (Platform.isIOS) {
    debugPrint('iOS platform detected - skipping rotation');
    processedImage = image;
  } else {
    debugPrint('Non-iOS platform detected - rotating image 90 degrees clockwise before cropping');
    processedImage = imglib.copyRotate(image, angle: 90);
    debugPrint('Image rotated from ${image.width}x${image.height} to ${processedImage.width}x${processedImage.height}');
  }
  
  final imageWidth = processedImage.width.toDouble();
  final imageHeight = processedImage.height.toDouble();
  
  // Calculate overlay rectangle for the processed image size
  final overlayRect = calculateOverlayRect(imageWidth, imageHeight);
  
  // Convert to integer coordinates for cropping
  final cropX = overlayRect['x']!.round().clamp(0, processedImage.width - 1);
  final cropY = overlayRect['y']!.round().clamp(0, processedImage.height - 1);
  final cropWidth = overlayRect['width']!.round().clamp(1, processedImage.width - cropX);
  final cropHeight = overlayRect['height']!.round().clamp(1, processedImage.height - cropY);
  
  debugPrint('Cropping ${Platform.isIOS ? 'original' : 'rotated'} image from ${processedImage.width}x${processedImage.height} to ${cropWidth}x${cropHeight} at ($cropX, $cropY)');
  
  // Crop the processed image to the overlay rectangle
  return imglib.copyCrop(processedImage, 
    x: cropX, 
    y: cropY, 
    width: cropWidth, 
    height: cropHeight
  );
}

/// Takes an ML-Kit [InputImage], converts if necessary, crops to overlay area, compresses, and returns a Base64 string with JPEG data URI prefix.
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
      
      // 2. Crop to overlay rectangle area
      imglib.Image croppedImage = cropToOverlayRect(convertedImage);

      // 3. Encode cropped Image object to JPEG bytes
      bytesToCompress = encodeToJpeg(croppedImage, quality: 100);
      debugPrint(
          'NV21 converted and cropped to JPEG. Size: ${(bytesToCompress.length / 1024).toStringAsFixed(2)}KB');
    } catch (e) {
      debugPrint('Error during NV21 conversion/encoding: $e');
      throw Exception('Failed to convert NV21 image');
    }
  } else if (format == InputImageFormat.bgra8888 && originalImage.bytes != null) {
    // =================================================================
    //  CRITICAL FIX FOR IOS - Handle BGRA8888 format properly with rotation
    // =================================================================
    debugPrint('BGRA8888 format detected. Converting to JPEG before compression.');
    try {
      imglib.Image image = imglib.Image.fromBytes(
        width: originalImage.metadata!.size.width.toInt(),
        height: originalImage.metadata!.size.height.toInt(),
        bytes: originalImage.bytes!.buffer,
        order: imglib.ChannelOrder.bgra, // Specify the byte order for iOS!
      );
      
      // Note: Rotation correction is now handled at the ML Kit level
      // in mlkit_extension.dart, so we don't need to rotate the image here
      
      // Crop to overlay rectangle area
      imglib.Image croppedImage = cropToOverlayRect(image);
      
      bytesToCompress = encodeToJpeg(croppedImage, quality: 100);
      debugPrint('BGRA8888 converted and cropped to JPEG. Size: ${(bytesToCompress.length / 1024).toStringAsFixed(2)}KB');
    } catch (e) {
      debugPrint('Error during BGRA8888 conversion/encoding: $e');
      throw Exception('Failed to convert BGRA8888 image');
    }
  } else if (originalImage.bytes != null) {
    // Fallback for other formats (e.g., if it's already a JPEG)
    debugPrint('Processing other format (not NV21 or BGRA8888) - attempting to decode and crop.');
    try {
      // Try to decode the image bytes
      imglib.Image? image = imglib.decodeImage(originalImage.bytes!);
      if (image != null) {
        // Crop to overlay rectangle area
        imglib.Image croppedImage = cropToOverlayRect(image);
        bytesToCompress = encodeToJpeg(croppedImage, quality: 100);
        debugPrint('Other format decoded, cropped and re-encoded. Size: ${(bytesToCompress.length / 1024).toStringAsFixed(2)}KB');
      } else {
        // If decoding fails, use original bytes
        debugPrint('Could not decode image, using original bytes.');
        bytesToCompress = originalImage.bytes!;
      }
    } catch (e) {
      debugPrint('Error processing other format: $e. Using original bytes.');
      bytesToCompress = originalImage.bytes!;
    }
  } else if (originalImage.filePath != null) {
    debugPrint('Reading and processing image from file path.');
    try {
      final fileBytes = await File(originalImage.filePath!).readAsBytes();
      imglib.Image? image = imglib.decodeImage(fileBytes);
      if (image != null) {
        // Crop to overlay rectangle area
        imglib.Image croppedImage = cropToOverlayRect(image);
        bytesToCompress = encodeToJpeg(croppedImage, quality: 100);
        debugPrint('File image decoded, cropped and re-encoded. Size: ${(bytesToCompress.length / 1024).toStringAsFixed(2)}KB');
      } else {
        debugPrint('Could not decode file image, using original bytes.');
        bytesToCompress = fileBytes;
      }
    } catch (e) {
      debugPrint('Error processing file image: $e');
      throw Exception('Failed to process image from file path');
    }
  } else {
    throw Exception('No image data available in InputImage');
  }

  debugPrint(
      'Cropped image bytes before compression: ${(bytesToCompress.length / (1024)).toStringAsFixed(2)}KB');

  // 2) Compress (either original bytes or converted JPEG bytes)
  final compressed = await FlutterImageCompress.compressWithList(
    bytesToCompress, // Use the prepared bytes
    minWidth: 800,
    minHeight: 600,
    quality: 70,
    format: CompressFormat.jpeg, // Explicitly specify JPEG format
  );

  if (compressed == null) {
    // Add more details if compression fails
    debugPrint('FlutterImageCompress.compressWithList returned null.');
    throw Exception('Image compression failed');
  }

  debugPrint(
      'Final cropped and compressed image: ${(compressed.length / 1024).toStringAsFixed(2)}KB');

  // 3) Encode final compressed bytes with JPEG data URI prefix
  final base64String = base64Encode(compressed);
  final dataUri = 'data:image/jpeg;base64,$base64String';
  
  debugPrint('Generated JPEG data URI with length: ${dataUri.length}');
  return dataUri;
}
