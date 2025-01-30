> main.md

```dart
import 'package:flutter/material.dart';
import 'package:mrz_scanner/mrz_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MRZ Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomeScreen(),
    );
  }
}

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({
    super.key,
  });

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  // Store MRZ Data from the scanner
  String? mrzData;

  void openMRZScanner() async {
    // Open MRZScanner
    final result = await NavigationHelper.navigateToMRZScanner(context);
    if (result is String) {
      setState(() {
        mrzData = result;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('MRZ Demo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Button to open MRZ Scanner
              MaterialButton(
                onPressed: openMRZScanner,
                color: Colors.green,
                child: const Text(
                  'Test Package',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              // Display MRZ Data once document is scanned
              if (mrzData != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Scanned MRZ Data:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(mrzData!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```