enum PediatricDrugType {
  paracetamol,
  ibuprofen,
}

class PediatricCalculationResult {
  final double weightKg;
  final double doseMgMin;
  final double doseMgMax;
  final double doseMlMin120;
  final double doseMlMax120;
  final double doseMlMin250;
  final double doseMlMax250;
  final double doseMlMin100;
  final double doseMlMax100;
  final double maxDailyMg;
  final int maxDosesIn24h;
  final int specifiedStrengthMg;
  final PediatricDrugType drugType;

  const PediatricCalculationResult({
    required this.weightKg,
    required this.doseMgMin,
    required this.doseMgMax,
    required this.doseMlMin120,
    required this.doseMlMax120,
    required this.doseMlMin250,
    required this.doseMlMax250,
    this.doseMlMin100 = 0.0,
    this.doseMlMax100 = 0.0,
    required this.maxDailyMg,
    this.maxDosesIn24h = 4,
    this.specifiedStrengthMg = 120,
    this.drugType = PediatricDrugType.paracetamol,
  });

  String toPromptContext() {
    final wStr = weightKg.toStringAsFixed(weightKg.truncateToDouble() == weightKg ? 0 : 1);
    final mgMinStr = doseMgMin.toStringAsFixed(0);
    final mgMaxStr = doseMgMax.toStringAsFixed(0);
    final maxDailyStr = maxDailyMg.toStringAsFixed(0);

    if (drugType == PediatricDrugType.ibuprofen) {
      final mlMin100Str = doseMlMin100.toStringAsFixed(1);
      final mlMax100Str = doseMlMax100.toStringAsFixed(1);
      return '''[MANDATORY_MATHEMATICAL_TRUTH]:
- Patient Weight: $wStr kg
- Medication: Ibuprofen Pediatric Suspension (100 mg / 5 mL)
- Ibuprofen Single Dose Formula: 5 to 10 mg/kg per dose
- Target Single Dose in Milligrams: $mgMinStr mg to $mgMaxStr mg
- USER SPECIFIED CONCENTRATION: 100 mg / 5 mL -> Use EXACTLY $mlMin100Str mL to $mlMax100Str mL per dose every 6-8 hours with food.
- Absolute 24-Hour Ceiling: $maxDailyStr mg (Maximum 3-4 doses in 24 hours; max 40 mg/kg/day)
- CRITICAL: Output ONLY these verified dosage values. Do not invent decimals or lower arbitrary numbers.''';
    }

    final mlMin120Str = doseMlMin120.toStringAsFixed(1);
    final mlMax120Str = doseMlMax120.toStringAsFixed(1);
    final mlMin250Str = doseMlMin250.toStringAsFixed(1);
    final mlMax250Str = doseMlMax250.toStringAsFixed(1);

    return '''[MANDATORY_MATHEMATICAL_TRUTH]:
- Patient Weight: $wStr kg
- Medication: Paracetamol Pediatric Suspension (120 mg / 5 mL or 250 mg / 5 mL)
- Paracetamol Single Dose Formula: 10 to 15 mg/kg per dose
- Target Single Dose in Milligrams: $mgMinStr mg to $mgMaxStr mg
- Standard 120 mg / 5 mL Suspension: EXACTLY $mlMin120Str mL to $mlMax120Str mL per dose every 4-6 hours.
- High Strength 250 mg / 5 mL Suspension: EXACTLY $mlMin250Str mL to $mlMax250Str mL per dose every 4-6 hours.
- Absolute 24-Hour Ceiling: $maxDailyStr mg (Maximum 4 doses in 24 hours)
- CRITICAL: Output ONLY these verified dosage values. Do not invent decimals or lower arbitrary numbers.''';
  }

  String toDeterministicPediatricMarkdown() {
    final wStr = weightKg.toStringAsFixed(weightKg.truncateToDouble() == weightKg ? 0 : 1);
    final mgMinStr = doseMgMin.toStringAsFixed(0);
    final mgMaxStr = doseMgMax.toStringAsFixed(0);
    final maxDailyMgStr = maxDailyMg.toStringAsFixed(0);

    if (drugType == PediatricDrugType.ibuprofen) {
      final mlMin100Str = doseMlMin100.toStringAsFixed(1);
      final mlMax100Str = doseMlMax100.toStringAsFixed(1);
      final maxDailyMlStr = ((maxDailyMg / 100.0) * 5.0).toStringAsFixed(0);

      return '''
RECOMMENDED_MEDICATION:
• Generic Name: Ibuprofen Pediatric Suspension (100 mg / 5 mL)
• Child Weight: $wStr kg (Mandatory Pediatric Dosing Lock)
• Calculated Dose (5-10 mg/kg): $mgMinStr mg to $mgMaxStr mg per dose
• Syrup (100 mg / 5 mL): $mlMin100Str mL to $mlMax100Str mL per dose every 6-8 hours with meals (Maximum 3-4 doses in 24 hours)
• Absolute 24h Ceiling: $maxDailyMgStr mg ($maxDailyMlStr mL of syrup; max 40 mg/kg/day)
• Safety Warning: Administer with milk or food. DO NOT administer adult tablets. Use calibrated oral syringe.
'''.trim();
    }

    if (specifiedStrengthMg == 250) {
      final mlMin250Str = doseMlMin250.toStringAsFixed(1);
      final mlMax250Str = doseMlMax250.toStringAsFixed(1);
      final maxDailyMlStr = ((maxDailyMg / 250.0) * 5.0).toStringAsFixed(0);

      return '''
RECOMMENDED_MEDICATION:
• Generic Name: Paracetamol Pediatric Suspension (250 mg / 5 mL Forte)
• Child Weight: $wStr kg (Mandatory Pediatric Dosing Lock)
• Calculated Dose (10-15 mg/kg): $mgMinStr mg to $mgMaxStr mg per dose
• Syrup (250 mg / 5 mL Forte): $mlMin250Str mL to $mlMax250Str mL per dose every 4-6 hours (Maximum 4 doses in 24 hours)
• Absolute 24h Ceiling: $maxDailyMgStr mg ($maxDailyMlStr mL of 250 mg / 5 mL syrup)
• Safety Warning: DO NOT administer adult tablets (500mg - 1000mg). Use calibrated oral syringe or measuring cup.
'''.trim();
    }

    final mlMin120Str = doseMlMin120.toStringAsFixed(1);
    final mlMax120Str = doseMlMax120.toStringAsFixed(1);
    final maxDailyMlStr = ((maxDailyMg / 120.0) * 5.0).toStringAsFixed(0);

    return '''
RECOMMENDED_MEDICATION:
• Generic Name: Paracetamol Pediatric Suspension (120 mg / 5 mL)
• Child Weight: $wStr kg (Mandatory Pediatric Dosing Lock)
• Calculated Dose (10-15 mg/kg): $mgMinStr mg to $mgMaxStr mg per dose
• Syrup (120 mg / 5 mL): $mlMin120Str mL to $mlMax120Str mL per dose every 4-6 hours (Maximum 4 doses in 24 hours)
• Absolute 24h Ceiling: $maxDailyMgStr mg ($maxDailyMlStr mL of syrup)
• Safety Warning: DO NOT administer adult tablets (500mg - 1000mg). Use calibrated oral syringe or measuring cup.
'''.trim();
  }
}

class PediatricMathHelper {
  static final RegExp _weightRegex = RegExp(
    r'(\d+(?:\.\d+)?)\s*(?:kg|kgs|kilos?|kilograms?)\b',
    caseSensitive: false,
  );

  static final RegExp _contextWeightRegex = RegExp(
    r'(?:child|baby|infant|pediatric|weight)\D{0,15}(\d+(?:\.\d+)?)\b',
    caseSensitive: false,
  );

  static final RegExp _ageRegex = RegExp(
    r'(\d+)\s*(?:-|\s)*(?:years?\s*old|yrs?\s*old|years?|yrs?|yo|y/o)\b',
    caseSensitive: false,
  );

  static final RegExp _wordAgeRegex = RegExp(
    r'(?:two\s*years?\s*old)',
    caseSensitive: false,
  );

  static final RegExp _pediatricOrFeverRegex = RegExp(
    r'(fever|child|kid|baby|infant|toddler|pediatric|2-year-old|2\s*year)',
    caseSensitive: false,
  );

  static final RegExp _antipyreticRegex = RegExp(
    r'(paracetamol|panadol|calpol|acetaminophen|tylenol|febrol|disprol|ibuprofen|brufen|advil|motrin|syrup|dose)',
    caseSensitive: false,
  );

  static final RegExp _ibuprofenRegex = RegExp(
    r'\b(ibuprofen|brufen|advil|motrin|100\s*mg\s*(?:/|in)\s*5\s*m[lL]|100\s*mg\s*(?:syrup|suspension)|100\s*(?:/|in)\s*5\b)\b',
    caseSensitive: false,
  );

  static final RegExp _forteOr250Regex = RegExp(
    r'(?:250\s*mg\s*(?:/|in)\s*5\s*m[lL]|250\s*mg\s*(?:syrup|suspension)|250\s*(?:/|in)\s*5\b|250\s*mg\b|forte)',
    caseSensitive: false,
  );

  static PediatricCalculationResult? calculateFromQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    double? extractedWeight;

    final match = _weightRegex.firstMatch(trimmed);
    if (match != null) {
      extractedWeight = double.tryParse(match.group(1) ?? '');
    }

    if (extractedWeight == null) {
      final contextMatch = _contextWeightRegex.firstMatch(trimmed);
      if (contextMatch != null) {
        extractedWeight = double.tryParse(contextMatch.group(1) ?? '');
      }
    }

    if (extractedWeight == null) {
      if (_wordAgeRegex.hasMatch(trimmed)) {
        extractedWeight = 12.0;
      } else {
        final ageMatch = _ageRegex.firstMatch(trimmed);
        if (ageMatch != null) {
          final age = int.tryParse(ageMatch.group(1) ?? '');
          if (age != null && age > 0 && age < 12) {
            if (age == 1) {
              extractedWeight = 10.0;
            } else if (age == 2) {
              extractedWeight = 12.0;
            } else if (age == 3) {
              extractedWeight = 14.5;
            } else if (age == 4) {
              extractedWeight = 16.5;
            } else if (age == 5) {
              extractedWeight = 18.5;
            } else {
              extractedWeight = (age * 2.5) + 6.0;
            }
          }
        }
      }
    }

    if (extractedWeight == null || extractedWeight <= 0 || extractedWeight > 60) {
      return null;
    }

    final hasPediatricOrFever = _pediatricOrFeverRegex.hasMatch(trimmed);
    final hasAntipyretic = _antipyreticRegex.hasMatch(trimmed);

    if (!hasPediatricOrFever && !hasAntipyretic) {
      return null;
    }

    final weight = extractedWeight;
    final isIbuprofen = _ibuprofenRegex.hasMatch(trimmed);

    if (isIbuprofen) {
      final doseMgMin = weight * 5.0;
      final doseMgMax = weight * 10.0;
      final doseMlMin100 = double.parse(((doseMgMin / 100.0) * 5.0).toStringAsFixed(2));
      final doseMlMax100 = double.parse(((doseMgMax / 100.0) * 5.0).toStringAsFixed(2));
      final maxDailyMg = weight * 40.0;

      return PediatricCalculationResult(
        weightKg: weight,
        doseMgMin: doseMgMin,
        doseMgMax: doseMgMax,
        doseMlMin120: 0.0,
        doseMlMax120: 0.0,
        doseMlMin250: 0.0,
        doseMlMax250: 0.0,
        doseMlMin100: doseMlMin100,
        doseMlMax100: doseMlMax100,
        maxDailyMg: maxDailyMg,
        maxDosesIn24h: 4,
        specifiedStrengthMg: 100,
        drugType: PediatricDrugType.ibuprofen,
      );
    }

    final doseMgMin = weight * 10.0;
    final doseMgMax = weight * 15.0;
    final doseMlMin120 = double.parse(((doseMgMin / 120.0) * 5.0).toStringAsFixed(2));
    final doseMlMax120 = double.parse(((doseMgMax / 120.0) * 5.0).toStringAsFixed(2));
    final doseMlMin250 = double.parse(((doseMgMin / 250.0) * 5.0).toStringAsFixed(2));
    final doseMlMax250 = double.parse(((doseMgMax / 250.0) * 5.0).toStringAsFixed(2));
    final maxDailyMg = weight * 60.0;
    final specifiedStrengthMg = _forteOr250Regex.hasMatch(trimmed) ? 250 : 120;

    return PediatricCalculationResult(
      weightKg: weight,
      doseMgMin: doseMgMin,
      doseMgMax: doseMgMax,
      doseMlMin120: doseMlMin120,
      doseMlMax120: doseMlMax120,
      doseMlMin250: doseMlMin250,
      doseMlMax250: doseMlMax250,
      maxDailyMg: maxDailyMg,
      specifiedStrengthMg: specifiedStrengthMg,
      drugType: PediatricDrugType.paracetamol,
    );
  }

  static bool isPediatricQuery(String query) => calculateFromQuery(query) != null;
}
