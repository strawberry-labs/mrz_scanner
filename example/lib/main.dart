import 'package:flutter/material.dart';
// Use the main library export
import 'package:mrz_scanner/mrz_scanner.dart';

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
          // Assuming the helper returns the processed result directly
          // You might need to adjust how you display this based on what 'result' contains
          _scanResult = result;
          _errorMessage = null;
          debugPrint('Scanner Result: $result');
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
              // Display the result (converting to string for display)
              if (_scanResult != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      'Scan Result:\n${_scanResult.toString()}', // Display result object as string
                      textAlign: TextAlign.center,
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
