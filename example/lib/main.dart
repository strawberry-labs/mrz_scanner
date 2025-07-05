import 'dart:convert'; // For JSON decoding
import 'package:flutter/material.dart';
// Use the main library export
import 'package:mrz_scanner/mrz_scanner.dart';
import 'package:flutter/services.dart'; // For Clipboard

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MRZ Scanner Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'MRZ Scanner Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Store the result from the scanner
  Object? _scanResult;
  String? _errorMessage;
  bool _isProcessing = false; // Keep track if navigation is in progress
  String? _lastScanMode; // Track which scan mode was used
  bool _enableVibration = true; // Control vibration feedback

  Future<void> _navigateToScanner(ScanMode scanMode) async {
    setState(() {
      _isProcessing = true;
      _scanResult = null;
      _errorMessage = null;
      _lastScanMode = scanMode.name;
    });

    try {
      // Call the library's navigation helper with scan mode and vibration setting
      final result = await NavigationHelper.navigateToMRZScanner(
        context,
        scanMode: scanMode,
        enableVibration: _enableVibration,
      );

      setState(() {
        if (result != null) {
          // Assign the result
          _scanResult = result;
          _errorMessage = null;
          debugPrint('Scanner Result (${scanMode.name}): $result');

          // Extract and copy only the base64 image to clipboard
          try {
            final Map<String, dynamic> resultJson = json.decode(result);
            final String? imageBase64 = resultJson['imageBase64'];
            
            if (imageBase64 != null) {
              Clipboard.setData(ClipboardData(text: imageBase64))
                  .then((value) {
                    // Use context safely after async gap
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Base64 image copied to clipboard'),
                        ),
                      );
                    }
                  })
                  .catchError((error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to copy image: $error')),
                      );
                    }
                  });
            } else {
              // Fallback to copying the entire result if no imageBase64 found
              Clipboard.setData(ClipboardData(text: result))
                  .then((value) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${scanMode.name.toUpperCase()} scan result copied to clipboard'),
                        ),
                      );
                    }
                  });
            }
          } catch (e) {
            // If JSON parsing fails, fallback to copying the entire result
            debugPrint('Failed to parse result JSON: $e');
            Clipboard.setData(ClipboardData(text: result))
                .then((value) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${scanMode.name.toUpperCase()} scan result copied to clipboard'),
                      ),
                    );
                  }
                });
          }
        } else {
          // Handle case where the scanner was dismissed or returned null
          _scanResult = null;
          _errorMessage = 'Scanner was dismissed or returned no result.';
          debugPrint('Scanner returned null');
        }
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _scanResult = null;
        _isProcessing = false;
      });
      debugPrint('Error navigating to scanner: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Front scan button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _navigateToScanner(ScanMode.front),
                  icon: const Icon(Icons.credit_card),
                  label: _isProcessing && _lastScanMode == 'front'
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Scanning Front...'),
                          ],
                        )
                      : const Text('Scan Front (ID Card Front)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Back scan button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _navigateToScanner(ScanMode.back),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: _isProcessing && _lastScanMode == 'back'
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Scanning Back...'),
                          ],
                        )
                      : const Text('Scan Back (MRZ Code)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Vibration toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Vibration Feedback',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Vibrate when scan completes successfully',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _enableVibration,
                  onChanged: (value) {
                    setState(() => _enableVibration = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 16),
              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Choose scan mode:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Front: Scans ID card front for Name, ID Number, Date of Birth, Nationality',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Back: Scans MRZ code with full validation and parsing',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Display the result
              if (_scanResult != null)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan Result ($_lastScanMode):',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _scanResult.toString(),
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
