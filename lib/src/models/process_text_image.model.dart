import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mrz_scanner/src/models/mrz_parser.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mrz_scanner/src/utils/image_utils.dart';
import 'package:mrz_scanner/src/mrz_navigator.dart';

class ProcessTextImage {
  // MRZ patterns moved from string.extension.dart
  static final firstLineRegex =
      RegExp(r"([ACI])([A-Z0-9<])([A-Z]{3})([A-Z0-9<]{9})(\d)([A-Z0-9<]{15})");
  static final secondLineRegex =
      RegExp(r"(\d{6})(\d)([MFX<])(\d{6})(\d)([A-Z]{3})([A-Z0-9<]{11})(\d)");
  static final thirdLineRegex = RegExp(r"([A-Z0-9<]{30})");

  Future<String?> firstDetectingProcess({
    required RecognizedText recognizedText,
    required InputImage originalImage,
    required ScanMode scanMode,
  }) async {
    try {
      debugPrint("I AM IN firstDetectingProcess");
      debugPrint("Image metadata - Format: ${originalImage.metadata?.format?.name}, Rotation: ${originalImage.metadata?.rotation?.name}, Size: ${originalImage.metadata?.size}");
      
      final lines = recognizedText.blocks
          .expand<TextLine>((block) => block.lines)
          .toList();
      
      debugPrint("Found ${lines.length} text lines:");
      for (int i = 0; i < lines.length && i < 10; i++) {
        debugPrint("Line $i: '${lines[i].text}'");
      }

      // Handle different scan modes
      if (scanMode == ScanMode.front) {
        return _processFrontScan(recognizedText, originalImage);
      }

      // Back scan mode - Look for consecutive lines matching MRZ patterns
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

  /// Process front scan - look for specific text values
  Future<String?> _processFrontScan(RecognizedText recognizedText, InputImage originalImage) async {
    try {
      debugPrint("Processing front scan - looking for required fields");
      
      // Required fields to find on the front of the card
      final requiredFields = ['ID Number', 'Name', 'Date of Birth', 'Nationality'];
      final foundFields = <String>[];
      
      // Get all text from the image
      final allText = recognizedText.text.toUpperCase();
      debugPrint("All detected text: $allText");
      
      // Check for each required field (case insensitive)
      for (final field in requiredFields) {
        final fieldUpper = field.toUpperCase();
        
        // Check various possible variations of the field names
        final variations = _getFieldVariations(fieldUpper);
        
        bool fieldFound = false;
        for (final variation in variations) {
          if (allText.contains(variation)) {
            foundFields.add(field);
            debugPrint("✓ Found field: $field (matched: $variation)");
            fieldFound = true;
            break;
          }
        }
        
        if (!fieldFound) {
          debugPrint("✗ Missing field: $field");
        }
      }
      
      debugPrint("Found ${foundFields.length}/${requiredFields.length} required fields");
      
      // If all required fields are found, return just the base64 image
      if (foundFields.length == requiredFields.length) {
        debugPrint("✓ All required fields found - processing front scan");
        
        // Compress and encode image to base64
        String? imageBase64;
        try {
          imageBase64 = await inputImageToBase64(originalImage);
          debugPrint("✓ Front scan image converted to base64 successfully!");
          
          return jsonEncode({
            'scanMode': 'front',
            'imageBase64': imageBase64,
            'foundFields': foundFields,
          });
        } catch (e) {
          debugPrint("✗ Failed to compress/encode front scan image: $e");
          return null;
        }
      } else {
        debugPrint("✗ Front scan failed - missing required fields");
        return null;
      }
    } catch (error) {
      debugPrint("Front scan process error: $error");
      return null;
    }
  }

  /// Get variations of field names that might appear on ID cards
  List<String> _getFieldVariations(String field) {
    switch (field) {
      case 'ID NUMBER':
        return ['ID NUMBER', 'ID NO', 'IDNUMBER', 'ID#', 'IDENTIFICATION NUMBER', 'CARD NUMBER'];
      case 'NAME':
        return ['NAME', 'FULL NAME', 'HOLDER NAME', 'CARDHOLDER'];
      case 'DATE OF BIRTH':
        return ['DATE OF BIRTH', 'DOB', 'BIRTH DATE', 'BORN'];
      case 'NATIONALITY':
        return ['NATIONALITY', 'NATION', 'COUNTRY'];
      default:
        return [field];
    }
  }
}
