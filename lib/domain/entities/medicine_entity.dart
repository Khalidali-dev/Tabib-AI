import 'package:equatable/equatable.dart';

class MedicineEntity extends Equatable {
  final int? id;
  final String genericName;
  final String brandNames;
  final String therapeuticClass;
  final String indications;
  final String adultDosage;
  final String pediatricDosage;
  final String maxDailyLimit;
  final String contraindications;
  final String adverseReactions;
  final String emergencyRedFlags;
  final String precautionsAndInteractions;
  final String? dietaryLifestyleAdvice;

  const MedicineEntity({
    this.id,
    required this.genericName,
    required this.brandNames,
    required this.therapeuticClass,
    required this.indications,
    required this.adultDosage,
    required this.pediatricDosage,
    required this.maxDailyLimit,
    required this.contraindications,
    required this.adverseReactions,
    required this.emergencyRedFlags,
    required this.precautionsAndInteractions,
    this.dietaryLifestyleAdvice,
  });

  String get primaryIndications => indications;
  String get ceilingLimit => maxDailyLimit;
  String get absoluteContraindications => contraindications;
  String get drugInteractions => precautionsAndInteractions;

  String get lifestyleAdvice =>
      dietaryLifestyleAdvice ??
      'Maintain proper hydration, balanced nutrition, and rest. Avoid concurrent unverified supplements.';

  factory MedicineEntity.fromMap(Map<String, dynamic> map) {
    return MedicineEntity(
      id: map['id'] as int?,
      genericName: map['generic_name'] as String? ?? '',
      brandNames: map['brand_names'] as String? ?? '',
      therapeuticClass: map['therapeutic_class'] as String? ?? '',
      indications: map['indications'] as String? ?? '',
      adultDosage: map['adult_dosage'] as String? ?? '',
      pediatricDosage: map['pediatric_dosage'] as String? ?? '',
      maxDailyLimit: map['max_daily_limit'] as String? ?? '',
      contraindications: map['contraindications'] as String? ?? '',
      adverseReactions: map['adverse_reactions'] as String? ?? '',
      emergencyRedFlags: map['emergency_red_flags'] as String? ?? '',
      precautionsAndInteractions:
          map['precautions_interactions'] as String? ?? '',
      dietaryLifestyleAdvice: map['dietary_lifestyle_advice'] as String?,
    );
  }

  factory MedicineEntity.fromJson(Map<String, dynamic> json) =>
      MedicineEntity.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'generic_name': genericName,
      'brand_names': brandNames,
      'therapeutic_class': therapeuticClass,
      'indications': indications,
      'adult_dosage': adultDosage,
      'pediatric_dosage': pediatricDosage,
      'max_daily_limit': maxDailyLimit,
      'contraindications': contraindications,
      'adverse_reactions': adverseReactions,
      'emergency_red_flags': emergencyRedFlags,
      'precautions_interactions': precautionsAndInteractions,
      'dietary_lifestyle_advice': lifestyleAdvice,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  String toClinicalContextString() {
    return '''
[MEDICINE RECORD: $genericName ($brandNames)]
- Class: $therapeuticClass
- Clinical Indications: $indications
- Adult Dosage: $adultDosage
- Pediatric Dosage: $pediatricDosage
- Absolute Max Daily Limit: $maxDailyLimit
- Contraindications: $contraindications
- Common Adverse Reactions: $adverseReactions
- CRITICAL EMERGENCY RED FLAGS: $emergencyRedFlags
- Precautions & Key Drug Interactions: $precautionsAndInteractions
- Evidence-Based Lifestyle & Dietary Guidance: $lifestyleAdvice
'''.trim();
  }

  String toContextString() => toClinicalContextString();

  @override
  List<Object?> get props => [
        id,
        genericName,
        brandNames,
        therapeuticClass,
        indications,
        adultDosage,
        pediatricDosage,
        maxDailyLimit,
        contraindications,
        adverseReactions,
        emergencyRedFlags,
        precautionsAndInteractions,
        dietaryLifestyleAdvice,
      ];
}

extension MedicineListContextX on List<MedicineEntity> {
  String toContextString() {
    if (isEmpty) return '';
    return map((m) => m.toClinicalContextString()).join('\n\n');
  }
}
