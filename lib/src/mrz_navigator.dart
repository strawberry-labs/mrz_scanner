import 'package:flutter/material.dart';
import 'package:mrz_scanner/src/mrz_scanner.screen.dart';

enum ScanMode { front, back }

class NavigationHelper {
  static Future<String?> navigateToMRZScanner(
    BuildContext context, {
    ScanMode scanMode = ScanMode.back,
    bool enableVibration = true,
  }) async {
    // Navigate to the InputScreen and wait for the result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MRZScannerScreen(
          scanMode: scanMode,
          enableVibration: enableVibration,
        ),
      ),
    );

    // Return the result to the caller
    return result;
  }
}
