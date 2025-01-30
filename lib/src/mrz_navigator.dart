import 'package:flutter/material.dart';
import 'package:mrz_scanner/src/mrz_scanner.screen.dart';

class NavigationHelper {
  static Future<String?> navigateToMRZScanner(BuildContext context) async {
    // Navigate to the InputScreen and wait for the result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MRZScannerScreen()),
    );

    // Return the result to the caller
    return result;
  }
}
