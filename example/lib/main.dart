import 'package:flutter/material.dart';
// Use the main library export
import 'package:mrz_scanner/mrz_scanner.dart';
import 'dart:convert'; // For jsonDecode
import 'package:flutter/services.dart'; // For Clipboard
import 'package:clipboard/clipboard.dart'; // For FlutterClipboard

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

  Future<void> _navigateToScanner() async {
    setState(() {
      _isProcessing = true;
      _scanResult = null;
      _errorMessage = null;
    });

    try {
      // Call the library's navigation helper
      final result = await NavigationHelper.navigateToMRZScanner(context);

      setState(() {
        if (result != null) {
          // Assign the result
          _scanResult = result;
          _errorMessage = null;
          debugPrint('Scanner Result: $result');

          // Automatically copy the raw result string to clipboard
          FlutterClipboard.copy(result)
              .then((value) {
                // Use context safely after async gap
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Scan result copied to clipboard'),
                    ),
                  );
                }
              })
              .catchError((error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to auto-copy: $error')),
                  );
                }
              });
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

  // No need for dispose if we are not managing recognizers here directly

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
              ElevatedButton(
                // Call the new navigation method
                onPressed: _isProcessing ? null : _navigateToScanner,
                child:
                    _isProcessing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        // Update button text
                        : const Text('Open MRZ Scanner'),
              ),
              const SizedBox(height: 20),
              // Display the result and add copy button
              if (_scanResult != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      'Scan Result:\n${_scanResult.toString()}', // Display raw result string
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              if (_errorMessage != null)
                Text(
                  'Error: $_errorMessage',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
