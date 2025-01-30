import 'package:flutter/material.dart';

class MRZ {
  // Line 1 fields
  final String documentType;
  final String countryCode;
  final String documentNumber;
  final String documentNumberCheckDigit;
  final String optionalDataLine1;

  // Line 2 fields
  final String birthDate;
  final String birthDateCheckDigit;
  final String sex;
  final String expiryDate;
  final String expiryDateCheckDigit;
  final String nationality;
  final String optionalDataLine2;
  final String overallCheckDigit;

  // Line 3 fields
  final String primaryName;
  final String secondaryName;

  // Original lines for validation
  final String line1;
  final String line2;
  final String line3;

  MRZ({
    required this.documentType,
    required this.countryCode,
    required this.documentNumber,
    required this.documentNumberCheckDigit,
    required this.optionalDataLine1,
    required this.birthDate,
    required this.birthDateCheckDigit,
    required this.sex,
    required this.expiryDate,
    required this.expiryDateCheckDigit,
    required this.nationality,
    required this.optionalDataLine2,
    required this.overallCheckDigit,
    required this.primaryName,
    required this.secondaryName,
    required this.line1,
    required this.line2,
    required this.line3,
  });
}

class MRZParser {
  static MRZ parse(List<String> lines) {
    if (lines.length != 3) {
      throw FormatException('MRZ must have exactly 3 lines');
    }

    for (int i = 0; i < 3; i++) {
      if (lines[i].length != 30) {
        throw FormatException('Line ${i + 1} must be 30 characters');
      }
    }

    final line1 = _parseLine1(lines[0]);
    final line2 = _parseLine2(lines[1]);
    final names = _parseLine3(lines[2]);

    return MRZ(
      documentType: line1['documentType']!,
      countryCode: line1['countryCode']!,
      documentNumber: line1['documentNumber']!,
      documentNumberCheckDigit: line1['documentNumberCheckDigit']!,
      optionalDataLine1: line1['optionalDataLine1']!,
      birthDate: line2['birthDate']!,
      birthDateCheckDigit: line2['birthDateCheckDigit']!,
      sex: line2['sex']!,
      expiryDate: line2['expiryDate']!,
      expiryDateCheckDigit: line2['expiryDateCheckDigit']!,
      nationality: line2['nationality']!,
      optionalDataLine2: line2['optionalDataLine2']!,
      overallCheckDigit: line2['overallCheckDigit']!,
      primaryName: names['primary']!,
      secondaryName: names['secondary']!,
      line1: lines[0],
      line2: lines[1],
      line3: lines[2],
    );
  }

  static Map<String, String> _parseLine1(String line) {
    final regExp = RegExp(
      r'^([ACI])([A-Z0-9<])([A-Z]{3})([A-Z0-9<]{9})(\d)([A-Z0-9<]{15})$',
    );

    final match = regExp.firstMatch(line);
    if (match == null) {
      throw FormatException('Invalid Line 1 format');
    }

    return {
      'documentType': match.group(1)!,
      'countryCode': match.group(3)!,
      'documentNumber': match.group(4)!,
      'documentNumberCheckDigit': match.group(5)!,
      'optionalDataLine1': match.group(6)!,
    };
  }

  static Map<String, String> _parseLine2(String line) {
    final regExp = RegExp(
      r'^(\d{6})(\d)([MFX<])(\d{6})(\d)([A-Z]{3})([A-Z0-9<]{11})(\d)$',
    );

    final match = regExp.firstMatch(line);
    if (match == null) {
      throw FormatException('Invalid Line 2 format');
    }

    return {
      'birthDate': match.group(1)!,
      'birthDateCheckDigit': match.group(2)!,
      'sex': match.group(3)!,
      'expiryDate': match.group(4)!,
      'expiryDateCheckDigit': match.group(5)!,
      'nationality': match.group(6)!,
      'optionalDataLine2': match.group(7)!,
      'overallCheckDigit': match.group(8)!,
    };
  }

  static Map<String, String> _parseLine3(String line) {
    final parts = line.split('<<');
    String primary = parts.isNotEmpty ? parts[0] : '';
    String secondary = parts.length > 1 ? parts[1] : '';

    primary =
        primary.replaceAll('<', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    secondary =
        secondary.replaceAll('<', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    return {
      'primary': primary,
      'secondary': secondary,
    };
  }
}

class MRZValidator {
  static List<String> validate(MRZ mrz) {
    final errors = <String>[];

    // Document number check digit
    if (_calculateIcaoCheckDigit(mrz.documentNumber) !=
        mrz.documentNumberCheckDigit) {
      errors.add('Document number check digit mismatch');
    }

    // Birth date check digit
    if (_calculateIcaoCheckDigit(mrz.birthDate) != mrz.birthDateCheckDigit) {
      errors.add('Birth date check digit mismatch');
    }

    // Expiry date check digit
    if (_calculateIcaoCheckDigit(mrz.expiryDate) != mrz.expiryDateCheckDigit) {
      errors.add('Expiry date check digit mismatch');
    }

    // Overall check digit - correct specification
    final overallString =
        mrz.line1.substring(5, 30) + // Upper line positions 6-30
            mrz.line2.substring(0, 7) + // Middle line positions 1-7
            mrz.line2.substring(8, 15) + // Middle line positions 9-15
            mrz.line2.substring(18, 29); // Middle line positions 19-29

    if (_calculateIcaoCheckDigit(overallString) != mrz.overallCheckDigit) {
      errors.add('Overall check digit mismatch');
    }

    // Optional data Luhn check
    final optionalData = mrz.optionalDataLine1;
    if (optionalData.length != 15) {
      errors.add('Optional data must be 15 characters');
    } else if (!_validateLuhn(optionalData)) {
      errors.add('Optional data Luhn check failed');
    }

    return errors;
  }

  static String _calculateIcaoCheckDigit(String data) {
    final weights = [7, 3, 1];
    int sum = 0;

    for (int i = 0; i < data.length; i++) {
      final char = data[i];
      final value = _charToValue(char);
      sum += value * weights[i % 3];
    }

    return (sum % 10).toString();
  }

  static int _charToValue(String char) {
    if (char == '<') return 0;
    if (RegExp(r'[A-Z]').hasMatch(char)) {
      return char.codeUnitAt(0) - 'A'.codeUnitAt(0) + 10;
    }
    if (RegExp(r'\d').hasMatch(char)) {
      return int.parse(char);
    }
    throw FormatException('Invalid character: $char');
  }

  static bool _validateLuhn(String input) {
    final digits = input.split('').map((c) => int.tryParse(c)).toList();
    if (digits.any((d) => d == null)) return false;

    int sum = 0;
    bool doubleDigit = true;

    for (int i = digits.length - 2; i >= 0; i--) {
      int digit = digits[i]!;
      if (doubleDigit) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      debugPrint("sum in loop ------------------------------ $sum; $i; $digit");
      sum += digit;
      doubleDigit = !doubleDigit;
    }

    final checkDigit = (10 - (sum % 10)) % 10;
    final test = digits.last;
    debugPrint("sum ------------------------------ $sum");
    debugPrint("digits ------------------------------ $digits");
    debugPrint(
        "---------------------------------------------$checkDigit as String?");
    debugPrint("---------------------------------------------$test as String?");
    return checkDigit == digits.last;
  }
}
