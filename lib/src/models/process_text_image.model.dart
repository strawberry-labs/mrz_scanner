import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mrz_scanner/src/models/mrz_parser.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mrz_scanner/src/utils/image_utils.dart';

class ProcessTextImage {
  static final textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  // MRZ patterns moved from string.extension.dart
  static final firstLineRegex =
      RegExp(r"([ACI])([A-Z0-9<])([A-Z]{3})([A-Z0-9<]{9})(\d)([A-Z0-9<]{15})");
  static final secondLineRegex =
      RegExp(r"(\d{6})(\d)([MFX<])(\d{6})(\d)([A-Z]{3})([A-Z0-9<]{11})(\d)");
  static final thirdLineRegex = RegExp(r"([A-Z0-9<]{30})");

  Future<String?> firstDetectingProcess({
    required RecognizedText recognizedText,
    required InputImage originalImage,
  }) async {
    try {
      debugPrint("I AM IN firstDetectingProcess");
      final lines = recognizedText.blocks
          .expand<TextLine>((block) => block.lines)
          .toList();

      // Look for consecutive lines matching MRZ patterns
      for (int i = 0; i < lines.length - 2; i++) {
        String line1 = lines[i].text.replaceAll(' ', '').toUpperCase();
        String line2 = lines[i + 1].text.replaceAll(' ', '').toUpperCase();
        String line3 = lines[i + 2].text.replaceAll(' ', '').toUpperCase();

        if (firstLineRegex.hasMatch(line1) &&
            secondLineRegex.hasMatch(line2) &&
            thirdLineRegex.hasMatch(line3)) {
          debugPrint("\n=== Found potential MRZ lines ===");
          debugPrint("Line 1: $line1");
          debugPrint("Line 2: $line2");
          debugPrint("Line 3: $line3");
          debugPrint("================================\n");

          try {
            // Attempt to parse and validate the MRZ
            final mrz = MRZParser.parse([line1, line2, line3]);
            final errors = MRZValidator.validate(mrz);

            if (errors.isEmpty) {
              debugPrint("\n✓ MRZ validation successful!");

              // Compress and encode image to base64 using the utility function
              String? imageBase64;
              try {
                imageBase64 = await inputImageToBase64(originalImage);
                debugPrint(
                    "\n✓ Image compressed and converted to base64 successfully!");
              } catch (e) {
                debugPrint("\n✗ Failed to compress/encode image: $e");
              }

              return jsonEncode({
                'line1': line1,
                'line2': line2,
                'line3': line3,
                'imageBase64': imageBase64,
                'parsedData': {
                  'documentType': mrz.documentType,
                  'countryCode': mrz.countryCode,
                  'documentNumber': mrz.documentNumber,
                  'nationality': mrz.nationality,
                  'expiryDate': mrz.expiryDate,
                  'gender': mrz.sex,
                  'birthDate': mrz.birthDate,
                  'primaryName': mrz.primaryName,
                  'secondaryName': mrz.secondaryName,
                  // 'nameUser': '${mrz.primaryName} ${mrz.secondaryName}',
                }
              });
            } else {
              debugPrint("\n✗ MRZ validation failed:");
              for (var error in errors) {
                debugPrint("  - $error");
              }
            }
          } catch (e) {
            debugPrint("\n✗ MRZ parsing error: $e");
            continue;
          }
        }
      }
      return null;
    } catch (error) {
      debugPrint("Isolate process: has error $error");
      return null;
    }
  }

  Future<String?>? photoTextProcess(
    InputImage message,
  ) async {
    try {
      RecognizedText recognizedText =
          await textRecognizer.processImage(message);

      final lines = recognizedText.blocks
          .expand<TextLine>((block) => block.lines)
          .toList();

      // Find MRZ lines using pattern matching
      List<String> mrzLines = [];

      // Look for consecutive lines matching MRZ patterns
      for (int i = 0; i < lines.length - 2; i++) {
        String line1 = lines[i].text.replaceAll(' ', '').toUpperCase();
        String line2 = lines[i + 1].text.replaceAll(' ', '').toUpperCase();
        String line3 = lines[i + 2].text.replaceAll(' ', '').toUpperCase();

        if (firstLineRegex.hasMatch(line1) &&
            secondLineRegex.hasMatch(line2) &&
            thirdLineRegex.hasMatch(line3)) {
          debugPrint("\n=== Found potential MRZ lines ===");
          debugPrint("Line 1: $line1");
          debugPrint("Line 2: $line2");
          debugPrint("Line 3: $line3");
          debugPrint("================================\n");

          try {
            // Attempt to parse and validate the MRZ
            final mrz = MRZParser.parse([line1, line2, line3]);
            final errors = MRZValidator.validate(mrz);

            if (errors.isEmpty) {
              debugPrint("\n✓ MRZ validation successful!");
              mrzLines = [line1, line2, line3];
              return formatMRZResult(mrz);
            } else {
              debugPrint("\n✗ MRZ validation failed:");
              for (var error in errors) {
                debugPrint("  - $error");
              }
            }
          } catch (e) {
            debugPrint("\n✗ MRZ parsing error: $e");
            // Continue searching if this set of lines fails validation
            continue;
          }
        }
      }

      return null;
    } catch (error) {
      debugPrint("Isolate result: has error $error");
      return null;
    }
  }

  String formatMRZResult(MRZ mrz) {
    return '''
Found MRZ Lines:
${mrz.line1}
${mrz.line2}
${mrz.line3}

Parsed Data:
expiryDate: ${mrz.expiryDate}
gender: ${mrz.sex}
birthDate: ${mrz.birthDate}
fiscalNumber: ${mrz.documentNumber}
nameUser: ${mrz.primaryName} ${mrz.secondaryName}
typeDoc: ${mrz.documentType}
countryCode: ${mrz.countryCode}''';
  }

  void dispose() {
    textRecognizer.close();
  }
}
