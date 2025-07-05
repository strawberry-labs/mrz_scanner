<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# MRZ Scanner Flutter Package

A Flutter package for scanning Machine Readable Zone (MRZ) codes and ID card fronts using ML Kit text recognition. This package provides both front-side document scanning (for extracting basic information) and back-side MRZ code scanning (for full document validation).

## Features

- **Dual Scan Modes**: Front scan for basic info extraction, back scan for full MRZ validation
- **Cross-Platform**: Works on iOS and Android
- **Image Processing**: Automatic rotation, cropping, and compression
- **Base64 Output**: Returns processed images as JPEG data URIs
- **Real-time Processing**: Live camera feed with overlay guidance
- **Instructional Text**: Clear on-screen guidance showing "Scan your Emirates ID" and side indication
- **Vibration Feedback**: Configurable haptic feedback on successful scans
- **Validation**: Full MRZ code validation with check digits

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  mrz_scanner: ^1.0.0
```

Run:
```bash
flutter pub get
```

## Platform Setup

### Android

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.VIBRATE" />
```

**Required Permissions Explained:**
- `CAMERA`: Required for document scanning functionality
- `WRITE_EXTERNAL_STORAGE`: Used for image processing and temporary file operations
- `VIBRATE`: Enables haptic feedback on successful scans (can be disabled via `enableVibration: false`)

### iOS

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan documents</string>
```

**Note**: iOS automatically handles vibration permissions. The camera permission is the only required setup.

## Usage

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:mrz_scanner/mrz_scanner.dart';
import 'dart:convert';

class DocumentScannerPage extends StatefulWidget {
  @override
  _DocumentScannerPageState createState() => _DocumentScannerPageState();
}

class _DocumentScannerPageState extends State<DocumentScannerPage> {
  String? _scanResult;
  
  Future<void> _scanDocument(ScanMode scanMode) async {
    try {
      final result = await NavigationHelper.navigateToMRZScanner(
        context,
        scanMode: scanMode,
        enableVibration: true, // Optional: enable/disable vibration feedback
      );
      
      if (result != null) {
        setState(() {
          _scanResult = result;
        });
        
        // Parse the JSON result
        final Map<String, dynamic> resultJson = json.decode(result);
        final String? imageBase64 = resultJson['imageBase64'];
        
        // Use the base64 image as needed
        if (imageBase64 != null) {
          print('Received base64 image: ${imageBase64.substring(0, 50)}...');
        }
      }
    } catch (e) {
      print('Error scanning document: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Document Scanner')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _scanDocument(ScanMode.front),
            child: Text('Scan Front (ID Card)'),
          ),
          ElevatedButton(
            onPressed: () => _scanDocument(ScanMode.back),
            child: Text('Scan Back (MRZ Code)'),
          ),
          if (_scanResult != null)
            Expanded(
              child: SingleChildScrollView(
                child: Text(_scanResult!),
              ),
            ),
        ],
      ),
    );
  }
}
```

### Scan Modes

#### Front Scan (`ScanMode.front`)
Scans the front of ID cards looking for these fields:
- ID Number
- Name
- Date of Birth
- Nationality

**Result Format:**
```json
{
  "scanMode": "front",
  "imageBase64": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ...",
  "foundFields": ["ID Number", "Name", "Date of Birth", "Nationality"]
}
```

#### Back Scan (`ScanMode.back`)
Scans MRZ codes with full validation and parsing.

**Result Format:**
```json
{
  "line1": "P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<",
  "line2": "L898902C36UTO7408122F1204159UTO<<<<<<<<<<<6",
  "line3": "ERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<<<<<",
  "imageBase64": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ...",
  "parsedData": {
    "documentType": "P",
    "countryCode": "UTO",
    "documentNumber": "L898902C3",
    "nationality": "UTO",
    "expiryDate": "121204",
    "gender": "F",
    "birthDate": "740812",
    "primaryName": "ERIKSSON",
    "secondaryName": "ANNA MARIA"
  }
}
```

### Advanced Usage

#### Extracting Base64 Image

```dart
Future<void> _processResult(String result) async {
  try {
    final Map<String, dynamic> resultJson = json.decode(result);
    final String? imageBase64 = resultJson['imageBase64'];
    
    if (imageBase64 != null) {
      // Remove data URI prefix if present
      String base64Data = imageBase64;
      if (imageBase64.startsWith('data:image/jpeg;base64,')) {
        base64Data = imageBase64.substring('data:image/jpeg;base64,'.length);
      }
      
      // Convert to bytes
      final bytes = base64Decode(base64Data);
      
      // Save to file or use as needed
      final file = File('path/to/save/image.jpg');
      await file.writeAsBytes(bytes);
      
      print('Image saved: ${file.path}');
    }
  } catch (e) {
    print('Error processing result: $e');
  }
}
```

#### Parsing MRZ Data

```dart
void _parseMRZResult(String result) {
  try {
    final Map<String, dynamic> resultJson = json.decode(result);
    final parsedData = resultJson['parsedData'];
    
    if (parsedData != null) {
      print('Document Type: ${parsedData['documentType']}');
      print('Country: ${parsedData['countryCode']}');
      print('Document Number: ${parsedData['documentNumber']}');
      print('Name: ${parsedData['primaryName']} ${parsedData['secondaryName']}');
      print('Birth Date: ${parsedData['birthDate']}');
      print('Expiry Date: ${parsedData['expiryDate']}');
      print('Gender: ${parsedData['gender']}');
      print('Nationality: ${parsedData['nationality']}');
    }
  } catch (e) {
    print('Error parsing MRZ data: $e');
  }
}
```

### Error Handling

```dart
Future<void> _scanWithErrorHandling(ScanMode scanMode) async {
  try {
    final result = await NavigationHelper.navigateToMRZScanner(
      context,
      scanMode: scanMode,
      enableVibration: true, // Optional: control vibration feedback
    );
    
    if (result != null) {
      _processResult(result);
    } else {
      _showError('Scan was cancelled or no result returned');
    }
  } catch (e) {
    _showError('Failed to scan document: $e');
  }
}

void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}
```

## Image Processing Details

The SDK automatically processes images with the following steps:

1. **Platform-specific Rotation**: Images are rotated 90 degrees clockwise on Android (iOS images remain unrotated)
2. **Cropping**: Images are cropped to the overlay rectangle area (5.5:8.5 aspect ratio)
3. **Compression**: Images are compressed to JPEG format with quality optimization
4. **Encoding**: Final images are encoded as base64 data URIs

**Output Format**: `data:image/jpeg;base64,<base64-encoded-image>`

## Camera Overlay

The scanner displays a landscape rectangle overlay with a 5.5:8.5 aspect ratio to guide document placement. The overlay automatically adapts to different screen orientations and includes:

- **Visual Guide**: Blue rectangle outline showing document placement area
- **Instructional Text**: "Scan your Emirates ID" with clear side indication
- **Dynamic Labels**: "FRONT SIDE" (blue) or "BACK SIDE" (green) based on scan mode
- **Responsive Design**: Adapts to portrait and landscape orientations

## Vibration Feedback

The SDK provides haptic feedback when a scan is completed successfully. This can be controlled using the `enableVibration` parameter:

```dart
// Enable vibration (default)
final result = await NavigationHelper.navigateToMRZScanner(
  context,
  scanMode: ScanMode.back,
  enableVibration: true,
);

// Disable vibration
final result = await NavigationHelper.navigateToMRZScanner(
  context,
  scanMode: ScanMode.back,
  enableVibration: false,
);
```

**Note**: Vibration requires the `VIBRATE` permission on Android (see Platform Setup section).

## Permissions

The package handles camera permissions automatically. Make sure to add the required permissions to your platform-specific configuration files as shown in the Platform Setup section.

## Troubleshooting

### Common Issues

1. **Camera not working**: Ensure camera permissions are granted
2. **No result returned**: Check if the document is properly aligned within the overlay
3. **MRZ validation fails**: Ensure the MRZ code is clean and properly formatted
4. **Image quality issues**: Ensure good lighting and stable camera position

### Debug Information

Enable debug prints to see processing details:

```dart
import 'package:flutter/foundation.dart';

// Debug prints are automatically enabled in debug mode
// Check console for detailed processing information
```

## Example App

See the `example/` folder for a complete implementation showing both scan modes with proper error handling and result processing.

## Dependencies

This package depends on:
- `camerawesome`: Camera functionality
- `google_mlkit_text_recognition`: Text recognition
- `flutter_image_compress`: Image compression
- `image`: Image processing
- `vibration`: Haptic feedback and vibration

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and feature requests, please use the GitHub issue tracker.
