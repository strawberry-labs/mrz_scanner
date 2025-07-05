# MRZ Scanner SDK - Integration Examples

This document provides detailed examples of how to integrate and use the MRZ Scanner SDK in your Flutter application.

## Features Overview

The SDK includes:
- **Dual scan modes**: Front (ID card front) and Back (MRZ code) scanning
- **Instructional overlay**: Clear "Scan your Emirates ID" text with side indication
- **Vibration feedback**: Configurable haptic response on successful scans
- **Platform-specific processing**: Optimized image handling for iOS and Android
- **Base64 output**: JPEG images encoded as data URIs

## Quick Start Example

### 1. Basic Integration

```dart
import 'package:flutter/material.dart';
import 'package:mrz_scanner/mrz_scanner.dart';
import 'dart:convert';

class MRZScannerExample extends StatefulWidget {
  @override
  _MRZScannerExampleState createState() => _MRZScannerExampleState();
}

class _MRZScannerExampleState extends State<MRZScannerExample> {
  String? _result;
  bool _isScanning = false;

  Future<void> _scanDocument() async {
    setState(() => _isScanning = true);
    
    try {
      final result = await NavigationHelper.navigateToMRZScanner(
        context,
        scanMode: ScanMode.back, // or ScanMode.front
        enableVibration: true, // Enable haptic feedback on scan completion
      );
      
      setState(() {
        _result = result;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      _showError('Scan failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MRZ Scanner')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isScanning ? null : _scanDocument,
              child: _isScanning 
                ? CircularProgressIndicator()
                : Text('Scan Document'),
            ),
            if (_result != null) ...[
              SizedBox(height: 20),
              Text('Result:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_result!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

## Advanced Examples

### 2. Dual Mode Scanner with Result Processing

```dart
import 'package:flutter/material.dart';
import 'package:mrz_scanner/mrz_scanner.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class AdvancedMRZScanner extends StatefulWidget {
  @override
  _AdvancedMRZScannerState createState() => _AdvancedMRZScannerState();
}

class _AdvancedMRZScannerState extends State<AdvancedMRZScanner> {
  Map<String, dynamic>? _scanResult;
  String? _imageBase64;
  bool _isProcessing = false;

  Future<void> _scanDocument(ScanMode mode) async {
    setState(() {
      _isProcessing = true;
      _scanResult = null;
      _imageBase64 = null;
    });

    try {
      final result = await NavigationHelper.navigateToMRZScanner(
        context,
        scanMode: mode,
      );

      if (result != null) {
        final parsedResult = json.decode(result);
        setState(() {
          _scanResult = parsedResult;
          _imageBase64 = parsedResult['imageBase64'];
        });

        // Process based on scan mode
        if (mode == ScanMode.front) {
          _processFrontScan(parsedResult);
        } else {
          _processBackScan(parsedResult);
        }
      }
    } catch (e) {
      _showError('Scan failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _processFrontScan(Map<String, dynamic> result) {
    final foundFields = result['foundFields'] as List<dynamic>?;
    if (foundFields != null) {
      _showSuccess('Front scan completed. Found ${foundFields.length} fields.');
    }
  }

  void _processBackScan(Map<String, dynamic> result) {
    final parsedData = result['parsedData'] as Map<String, dynamic>?;
    if (parsedData != null) {
      final name = '${parsedData['primaryName']} ${parsedData['secondaryName']}';
      _showSuccess('MRZ scan completed for: $name');
    }
  }

  Future<void> _saveImage() async {
    if (_imageBase64 == null) return;

    try {
      // Extract base64 data (remove data URI prefix if present)
      String base64Data = _imageBase64!;
      if (base64Data.startsWith('data:image/jpeg;base64,')) {
        base64Data = base64Data.substring('data:image/jpeg;base64,'.length);
      }

      final bytes = base64Decode(base64Data);
      
      // Save to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/scanned_document_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);
      
      _showSuccess('Image saved to: ${file.path}');
    } catch (e) {
      _showError('Failed to save image: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Advanced MRZ Scanner')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scan Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _scanDocument(ScanMode.front),
                    icon: Icon(Icons.credit_card),
                    label: Text('Scan Front'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _scanDocument(ScanMode.back),
                    icon: Icon(Icons.qr_code_scanner),
                    label: Text('Scan Back'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
            
            // Processing Indicator
            if (_isProcessing) ...[
              SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Processing...'),
                  ],
                ),
              ),
            ],

            // Results Display
            if (_scanResult != null) ...[
              SizedBox(height: 20),
              _buildResultCard(),
            ],

            // Image Actions
            if (_imageBase64 != null) ...[
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saveImage,
                icon: Icon(Icons.save),
                label: Text('Save Image'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final scanMode = _scanResult!['scanMode'] ?? 'back';
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Result (${scanMode.toUpperCase()})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            
            if (scanMode == 'front') 
              _buildFrontResult()
            else 
              _buildBackResult(),
              
            SizedBox(height: 12),
            Text(
              'Image: ${_imageBase64 != null ? "✓ Captured" : "✗ Not available"}',
              style: TextStyle(
                color: _imageBase64 != null ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontResult() {
    final foundFields = _scanResult!['foundFields'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Found Fields:', style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 4),
        ...foundFields.map((field) => Text('• $field')),
      ],
    );
  }

  Widget _buildBackResult() {
    final parsedData = _scanResult!['parsedData'] as Map<String, dynamic>?;
    
    if (parsedData == null) {
      return Text('No parsed data available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataRow('Name', '${parsedData['primaryName']} ${parsedData['secondaryName']}'),
        _buildDataRow('Document Type', parsedData['documentType']),
        _buildDataRow('Country', parsedData['countryCode']),
        _buildDataRow('Document Number', parsedData['documentNumber']),
        _buildDataRow('Birth Date', _formatDate(parsedData['birthDate'])),
        _buildDataRow('Expiry Date', _formatDate(parsedData['expiryDate'])),
        _buildDataRow('Gender', parsedData['gender']),
        _buildDataRow('Nationality', parsedData['nationality']),
      ],
    );
  }

  Widget _buildDataRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.length != 6) return date ?? 'N/A';
    
    try {
      final year = int.parse(date.substring(0, 2));
      final month = int.parse(date.substring(2, 4));
      final day = int.parse(date.substring(4, 6));
      
      // Assume 20xx for years 00-30, 19xx for years 31-99
      final fullYear = year <= 30 ? 2000 + year : 1900 + year;
      
      return '$day/${month.toString().padLeft(2, '0')}/$fullYear';
    } catch (e) {
      return date;
    }
  }
}
```

### 3. Custom Result Handler

```dart
class MRZResultHandler {
  static Future<DocumentData?> processResult(String result) async {
    try {
      final Map<String, dynamic> json = jsonDecode(result);
      final scanMode = json['scanMode'] ?? 'back';
      
      if (scanMode == 'front') {
        return _processFrontResult(json);
      } else {
        return _processBackResult(json);
      }
    } catch (e) {
      print('Error processing result: $e');
      return null;
    }
  }

  static DocumentData? _processFrontResult(Map<String, dynamic> json) {
    final foundFields = json['foundFields'] as List<dynamic>? ?? [];
    final imageBase64 = json['imageBase64'] as String?;
    
    return DocumentData(
      scanMode: ScanMode.front,
      imageBase64: imageBase64,
      foundFields: foundFields.cast<String>(),
    );
  }

  static DocumentData? _processBackResult(Map<String, dynamic> json) {
    final parsedData = json['parsedData'] as Map<String, dynamic>?;
    final imageBase64 = json['imageBase64'] as String?;
    
    if (parsedData == null) return null;
    
    return DocumentData(
      scanMode: ScanMode.back,
      imageBase64: imageBase64,
      documentType: parsedData['documentType'],
      countryCode: parsedData['countryCode'],
      documentNumber: parsedData['documentNumber'],
      primaryName: parsedData['primaryName'],
      secondaryName: parsedData['secondaryName'],
      birthDate: parsedData['birthDate'],
      expiryDate: parsedData['expiryDate'],
      gender: parsedData['gender'],
      nationality: parsedData['nationality'],
    );
  }
}

class DocumentData {
  final ScanMode scanMode;
  final String? imageBase64;
  final List<String>? foundFields;
  final String? documentType;
  final String? countryCode;
  final String? documentNumber;
  final String? primaryName;
  final String? secondaryName;
  final String? birthDate;
  final String? expiryDate;
  final String? gender;
  final String? nationality;

  DocumentData({
    required this.scanMode,
    this.imageBase64,
    this.foundFields,
    this.documentType,
    this.countryCode,
    this.documentNumber,
    this.primaryName,
    this.secondaryName,
    this.birthDate,
    this.expiryDate,
    this.gender,
    this.nationality,
  });

  String get fullName => '${primaryName ?? ''} ${secondaryName ?? ''}'.trim();
  
  bool get isValid => scanMode == ScanMode.front 
    ? (foundFields?.length ?? 0) >= 4
    : documentNumber != null && primaryName != null;
}
```

### 4. Integration with Form

```dart
class DocumentFormPage extends StatefulWidget {
  @override
  _DocumentFormPageState createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  
  DocumentData? _documentData;

  Future<void> _scanAndFillForm() async {
    try {
      final result = await NavigationHelper.navigateToMRZScanner(
        context,
        scanMode: ScanMode.back,
      );

      if (result != null) {
        final documentData = await MRZResultHandler.processResult(result);
        if (documentData != null && documentData.isValid) {
          _fillFormFromDocument(documentData);
        }
      }
    } catch (e) {
      _showError('Failed to scan document: $e');
    }
  }

  void _fillFormFromDocument(DocumentData data) {
    setState(() {
      _documentData = data;
      _nameController.text = data.fullName;
      _documentController.text = data.documentNumber ?? '';
      _birthDateController.text = _formatDate(data.birthDate);
      _expiryDateController.text = _formatDate(data.expiryDate);
    });
    
    _showSuccess('Form filled from scanned document');
  }

  String _formatDate(String? date) {
    if (date == null || date.length != 6) return '';
    
    try {
      final year = int.parse(date.substring(0, 2));
      final month = int.parse(date.substring(2, 4));
      final day = int.parse(date.substring(4, 6));
      final fullYear = year <= 30 ? 2000 + year : 1900 + year;
      
      return '$day/$month/$fullYear';
    } catch (e) {
      return date;
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Document Form')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Scan Button
              ElevatedButton.icon(
                onPressed: _scanAndFillForm,
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Scan Document to Fill Form'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Form Fields
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              
              SizedBox(height: 16),
              
              TextFormField(
                controller: _documentController,
                decoration: InputDecoration(
                  labelText: 'Document Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Document number is required' : null,
              ),
              
              SizedBox(height: 16),
              
              TextFormField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Birth Date',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              
              SizedBox(height: 16),
              
              TextFormField(
                controller: _expiryDateController,
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              
              SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _showSuccess('Form submitted successfully');
                  }
                },
                child: Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Vibration Control

### Enabling/Disabling Vibration Feedback

```dart
class VibrationControlExample extends StatefulWidget {
  @override
  _VibrationControlExampleState createState() => _VibrationControlExampleState();
}

class _VibrationControlExampleState extends State<VibrationControlExample> {
  bool _enableVibration = true;

  Future<void> _scanWithVibrationControl(ScanMode mode) async {
    try {
      final result = await NavigationHelper.navigateToMRZScanner(
        context,
        scanMode: mode,
        enableVibration: _enableVibration, // Use the toggle state
      );

      if (result != null) {
        _showSuccess('Scan completed ${_enableVibration ? 'with' : 'without'} vibration');
      }
    } catch (e) {
      _showError('Scan failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vibration Control')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Vibration Toggle
            SwitchListTile(
              title: Text('Enable Vibration Feedback'),
              subtitle: Text('Vibrate when scan completes successfully'),
              value: _enableVibration,
              onChanged: (value) {
                setState(() => _enableVibration = value);
              },
            ),
            
            SizedBox(height: 24),
            
            // Scan Buttons
            ElevatedButton(
              onPressed: () => _scanWithVibrationControl(ScanMode.back),
              child: Text('Scan with Current Setting'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
```

## Integration Tips

### 1. Error Handling Best Practices

```dart
Future<void> _scanWithRetry(ScanMode mode, {int maxRetries = 3}) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      final result = await NavigationHelper.navigateToMRZScanner(
        context,
        scanMode: mode,
      );
      
      if (result != null) {
        // Success - process result
        _processResult(result);
        return;
      } else if (attempt < maxRetries) {
        // Retry
        final retry = await _showRetryDialog(attempt, maxRetries);
        if (!retry) break;
      }
    } catch (e) {
      if (attempt == maxRetries) {
        _showError('Failed after $maxRetries attempts: $e');
      }
    }
  }
}

Future<bool> _showRetryDialog(int attempt, int maxRetries) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Scan Failed'),
      content: Text('Attempt $attempt of $maxRetries failed. Try again?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Retry'),
        ),
      ],
    ),
  ) ?? false;
}
```

### 2. Performance Optimization

```dart
class MRZScannerOptimized extends StatefulWidget {
  @override
  _MRZScannerOptimizedState createState() => _MRZScannerOptimizedState();
}

class _MRZScannerOptimizedState extends State<MRZScannerOptimized> {
  Timer? _debounceTimer;
  bool _isScanning = false;

  Future<void> _debouncedScan(ScanMode mode) async {
    if (_isScanning) return;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      _performScan(mode);
    });
  }

  Future<void> _performScan(ScanMode mode) async {
    if (_isScanning) return;
    
    setState(() => _isScanning = true);
    
    try {
      final result = await NavigationHelper.navigateToMRZScanner(
        context,
        scanMode: mode,
      );
      
      if (result != null) {
        // Process result in background
        _processResultInBackground(result);
      }
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _processResultInBackground(String result) async {
    // Use compute for heavy processing
    final processedData = await compute(_processResultData, result);
    
    if (mounted) {
      setState(() {
        // Update UI with processed data
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Top-level function for compute
Map<String, dynamic> _processResultData(String result) {
  // Heavy processing logic here
  return jsonDecode(result);
}
```

These examples demonstrate various ways to integrate the MRZ Scanner SDK into your Flutter application, from basic usage to advanced scenarios with error handling, form integration, and performance optimization.