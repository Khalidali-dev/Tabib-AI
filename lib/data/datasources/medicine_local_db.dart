import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;
import '../../domain/domain.dart';

class MedicineLocalDb {
  MedicineLocalDb._internal();
  static final MedicineLocalDb instance = MedicineLocalDb._internal();

  static const String _tableName = 'medications';
  static const String _dbFileName = 'tabib_clinical_catalog.db';
  static const int _dbVersion = 3;

  sqflite.Database? _database;
  List<MedicineEntity>? _webCache;

  static const int maxSafeParacetamolDailyMg = 4000;
  static const String maxSafeParacetamolCeilingDisplay =
      '4000 mg (4 grams / 8 x 500mg tablets) per 24 hours';

  static String validateAndSanitizeDosages(String text) {
    if (text.isEmpty) return text;
    var sanitized = text;

    final gramRegex = RegExp(
      r'(\b(?:paracetamol|acetaminophen|panadol|tylenol|calpol)?\b[^\n.]{0,35}?)(\d+(?:\.\d+)?)\s*(?:g|grams?|gm)\b(?:\/\s*day|per\s*day|daily|in\s*24\s*hours)?(?![a-zA-Z])',
      caseSensitive: false,
    );

    sanitized = sanitized.replaceAllMapped(gramRegex, (match) {
      final prefix = match.group(1) ?? '';
      final valStr = match.group(2) ?? '';
      final val = double.tryParse(valStr);

      final fullMatch = (match.group(0) ?? '').toLowerCase();
      final lowerPrefix = prefix.toLowerCase();
      if (lowerPrefix.contains('glass') ||
          lowerPrefix.contains('cup') ||
          lowerPrefix.contains('fluid') ||
          lowerPrefix.contains('water') ||
          lowerPrefix.contains('drink') ||
          fullMatch.contains('glass') ||
          fullMatch.contains('fluid') ||
          fullMatch.contains('water')) {
        return match.group(0)!;
      }

      if (val != null && val > 4.0) {
        return '$prefix$maxSafeParacetamolCeilingDisplay';
      }
      return match.group(0)!;
    });

    final mgRegex = RegExp(
      r'(\b(?:paracetamol|acetaminophen|panadol|tylenol|calpol)?\b[^\n.]{0,35}?)(\d+(?:\.\d+)?)\s*(?:mg|milligrams?)\b(?:\/\s*day|per\s*day|daily|in\s*24\s*hours)?(?![a-zA-Z])',
      caseSensitive: false,
    );

    sanitized = sanitized.replaceAllMapped(mgRegex, (match) {
      final prefix = match.group(1) ?? '';
      final valStr = match.group(2) ?? '';
      final val = double.tryParse(valStr);
      if (val != null && val > 4000.0) {
        return '$prefix$maxSafeParacetamolCeilingDisplay';
      }
      return match.group(0)!;
    });

    sanitized = sanitized.replaceAll(
      RegExp(r'\b12\.8\s*g(?:[\s/]*day)?\b', caseSensitive: false),
      maxSafeParacetamolCeilingDisplay,
    );

    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d+(?:\.\d+)?\s*(?:mg|g|mcg|ml)?\s*[-–]\s*\d{1,2}:\d{2}\s*(?:am|pm)?\s*(?:tds|bd|tid|bid|od|qid|qds|prn)?\b', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{1,2}:\d{2}\s*(?:am|pm)\s*(?:tds|bd|tid|bid|od|qid)?\b', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\b(?:0-2\s*mg|max\s*16\s*mg)\b', caseSensitive: false),
      '',
    );

    return sanitized;
  }

  Future<void> init() async {
    if (kIsWeb) {
      _webCache ??= _seedRecords;
      return;
    }

    if (_database != null && _database!.isOpen) return;

    try {
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = p.join(dbPath, _dbFileName);

      _database = await sqflite.openDatabase(
        fullPath,
        version: _dbVersion,
        onCreate: (db, version) async {
          await _createTables(db);
          await _seedDatabase(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await db.execute('DROP TABLE IF EXISTS $_tableName');
          await _createTables(db);
          await _seedDatabase(db);
        },
        onOpen: (db) async {
          try {
            await _createTables(db);
            final count = sqflite.Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM $_tableName'),
            );
            if (count == null || count == 0) {
              await _seedDatabase(db);
            }
          } catch (_) {
            await _createTables(db);
            await _seedDatabase(db);
          }
        },
      );
    } catch (_) {
      _webCache = _seedRecords;
    }
  }

  Future<void> _createTables(sqflite.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        generic_name TEXT NOT NULL,
        brand_names TEXT NOT NULL,
        therapeutic_class TEXT NOT NULL,
        indications TEXT NOT NULL,
        adult_dosage TEXT NOT NULL,
        pediatric_dosage TEXT NOT NULL,
        max_daily_limit TEXT NOT NULL,
        contraindications TEXT NOT NULL,
        adverse_reactions TEXT NOT NULL,
        emergency_red_flags TEXT NOT NULL,
        precautions_interactions TEXT NOT NULL,
        dietary_lifestyle_advice TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_generic_name ON $_tableName(generic_name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_indications ON $_tableName(indications)',
    );
  }

  Future<void> _seedDatabase(sqflite.Database db) async {
    final batch = db.batch();
    for (final med in _seedRecords) {
      batch.insert(
        _tableName,
        med.toMap(),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static final Map<String, List<String>> _symptomKeywordsToGenerics = {
    'headache': ['Paracetamol', 'Ibuprofen'],
    'severe headache': ['Paracetamol', 'Ibuprofen'],
    'migraine': ['Paracetamol', 'Naproxen'],
    'fever': ['Paracetamol', 'Ibuprofen'],
    'high fever': ['Paracetamol', 'Ibuprofen'],
    'body ache': ['Paracetamol', 'Ibuprofen'],
    'toothache': ['Ibuprofen', 'Paracetamol'],
    'joint pain': ['Diclofenac', 'Naproxen'],
    'arthritis': ['Diclofenac', 'Naproxen'],
    'back pain': ['Diclofenac', 'Naproxen'],
    'muscle pain': ['Ibuprofen', 'Diclofenac'],
    'stomach pain': ['Omeprazole', 'Famotidine', 'Antacids (Aluminum & Magnesium Hydroxide)'],
    'severe stomach pain': ['Omeprazole', 'Famotidine'],
    'abdominal pain': ['Omeprazole', 'Famotidine'],
    'epigastric burning': ['Omeprazole', 'Famotidine'],
    'sour stomach': ['Omeprazole', 'Famotidine'],
    'heartburn': ['Omeprazole', 'Famotidine', 'Antacids (Aluminum & Magnesium Hydroxide)'],
    'stomach burning': ['Omeprazole', 'Famotidine'],
    'acid burning': ['Omeprazole', 'Famotidine'],
    'stomach burn': ['Omeprazole', 'Famotidine'],
    'nsaid': ['Omeprazole', 'Famotidine'],
    'nsaid gastritis': ['Omeprazole', 'Famotidine'],
    'nsaid-induced gastritis': ['Omeprazole', 'Famotidine'],
    'gastritis': ['Omeprazole', 'Famotidine'],
    'acidity': ['Omeprazole', 'Famotidine', 'Antacids (Aluminum & Magnesium Hydroxide)'],
    'gerd': ['Omeprazole', 'Famotidine'],
    'acid reflux': ['Omeprazole', 'Famotidine', 'Antacids (Aluminum & Magnesium Hydroxide)'],
    'indigestion': ['Antacids (Aluminum & Magnesium Hydroxide)', 'Famotidine'],
    'diarrhea': ['Oral Rehydration Salts'],
    'watery diarrhea': ['Oral Rehydration Salts'],
    'acute watery diarrhea': ['Oral Rehydration Salts'],
    'acute diarrhea': ['Oral Rehydration Salts'],
    'severe diarrhea': ['Oral Rehydration Salts'],
    'diarrheal': ['Oral Rehydration Salts'],
    'diarrhoea': ['Oral Rehydration Salts'],
    'watery diarrhoea': ['Oral Rehydration Salts'],
    'acute watery diarrhoea': ['Oral Rehydration Salts'],
    'acute diarrhoea': ['Oral Rehydration Salts'],
    'severe diarrhoea': ['Oral Rehydration Salts'],
    'loose motions': ['Oral Rehydration Salts'],
    'watery motions': ['Oral Rehydration Salts'],
    'acute watery motions': ['Oral Rehydration Salts'],
    'motions': ['Oral Rehydration Salts'],
    'frequent motions': ['Oral Rehydration Salts'],
    'watery stool': ['Oral Rehydration Salts'],
    'watery stools': ['Oral Rehydration Salts'],
    'loose stool': ['Oral Rehydration Salts'],
    'loose stools': ['Oral Rehydration Salts'],
    'vomiting': ['Oral Rehydration Salts'],
    'dehydration': ['Oral Rehydration Salts'],
    'ors': ['Oral Rehydration Salts'],
    'allergy': ['Cetirizine', 'Loratadine'],
    'allergic rhinitis': ['Cetirizine', 'Loratadine'],
    'hay fever': ['Cetirizine', 'Loratadine'],
    'sneezing': ['Cetirizine', 'Loratadine'],
    'runny nose': ['Cetirizine', 'Loratadine'],
    'hives': ['Cetirizine', 'Loratadine'],
    'urticaria': ['Cetirizine', 'Loratadine'],
    'itching': ['Cetirizine', 'Loratadine'],
    'skin rash': ['Cetirizine', 'Loratadine'],
    'nasal congestion': ['Normal Saline Nasal Spray'],
    'blocked nose': ['Normal Saline Nasal Spray'],
    'stuffy nose': ['Normal Saline Nasal Spray'],
    'dry nose': ['Normal Saline Nasal Spray'],
    'asthma': ['Salbutamol'],
    'wheezing': ['Salbutamol'],
    'bronchospasm': ['Salbutamol'],
    'iron deficiency': ['Ferrous Sulfate & Folic Acid'],
    'anemia': ['Ferrous Sulfate & Folic Acid'],
    'low hemoglobin': ['Ferrous Sulfate & Folic Acid'],
    'blood deficiency': ['Ferrous Sulfate & Folic Acid'],
    'extreme fatigue': ['Ferrous Sulfate & Folic Acid', 'Vitamin D3 (Cholecalciferol)'],
    'pale skin': ['Ferrous Sulfate & Folic Acid'],
    'vitamin d': ['Vitamin D3 (Cholecalciferol)'],
    'vitamin d deficiency': ['Vitamin D3 (Cholecalciferol)'],
    'bone weakness': ['Vitamin D3 (Cholecalciferol)'],
    'rickets': ['Vitamin D3 (Cholecalciferol)'],
    'diabetes': ['Metformin'],
    'type 2 diabetes': ['Metformin'],
    'high blood sugar': ['Metformin'],
    'sugar': ['Metformin'],
    'hypertension': ['Amlodipine', 'Lisinopril'],
    'high blood pressure': ['Amlodipine', 'Lisinopril'],
    'high cholesterol': ['Atorvastatin'],
    'cholesterol': ['Atorvastatin'],
    'hyperlipidemia': ['Atorvastatin'],
    'cough': ['Azithromycin', 'Amoxicillin'],
    'sore throat': ['Azithromycin', 'Amoxicillin'],
    'ear infection': ['Amoxicillin', 'Azithromycin'],
    'throat infection': ['Azithromycin', 'Amoxicillin'],
  };

  bool isDiagnosticOrTriageQuery(String query) {
    final lower = query.toLowerCase();
    return lower.contains('differential diagnosis') ||
        lower.contains('laboratory tests') ||
        lower.contains('lab tests') ||
        lower.contains('dengue') ||
        lower.contains('polydipsia') ||
        lower.contains('polyuria') ||
        lower.contains('ckd') ||
        lower.contains('chronic kidney disease') ||
        lower.contains('renal failure') ||
        lower.contains('kidney failure');
  }

  bool isHarmfulQuery(String query) {
    if (TriageInterceptor.shouldIntercept(query)) {
      return true;
    }
    final lower = query.toLowerCase();
    return lower.contains('kill myself') ||
        lower.contains('suicide') ||
        lower.contains('end my life') ||
        lower.contains('how to die') ||
        lower.contains('lethal dose') ||
        lower.contains('lethal amount') ||
        lower.contains('overdose') ||
        lower.contains('fatal dose') ||
        lower.contains('make meth') ||
        lower.contains('cook meth') ||
        lower.contains('cut open abscess at home') ||
        lower.contains('home surgery') ||
        lower.contains('fentanyl') ||
        lower.contains('morphine without prescription') ||
        lower.contains('xanax without prescription');
  }

  bool isPediatricQuery(String query) {
    final lower = query.toLowerCase();
    final childPattern = RegExp(
      r'\b(?:child|infant|baby|pediatric|toddler|newborn|kid|boy|girl)\b',
      caseSensitive: false,
    );
    final agePattern = RegExp(
      r'(\d+)\s*(?:years?|yrs?|months?|m|y)\s*(?:old|age)?',
      caseSensitive: false,
    );
    final weightPattern = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:kg|kgs|kilo|kilos)\b',
      caseSensitive: false,
    );

    final matchAge = agePattern.firstMatch(lower);
    if (matchAge != null) {
      final val = int.tryParse(matchAge.group(1) ?? '');
      if (val != null && val < 12) return true;
    }

    final matchWeight = weightPattern.firstMatch(lower);
    if (matchWeight != null) {
      final val = double.tryParse(matchWeight.group(1) ?? '');
      if (val != null && val < 40.0) return true;
    }

    return childPattern.hasMatch(lower);
  }

  Future<List<MedicineEntity>> searchMedications(String query) async {
    final rawQuery = query.trim();
    if (rawQuery.isEmpty) return [];

    if (isHarmfulQuery(rawQuery) || isDiagnosticOrTriageQuery(rawQuery)) {
      return [];
    }

    if (TriageInterceptor.isSurgicalEmergencyOrContraindicated(rawQuery)) {
      return [];
    }

    final lowerQuery = rawQuery.toLowerCase();
    final candidateGenerics = <String>{};

    for (final entry in _symptomKeywordsToGenerics.entries) {
      if (lowerQuery.contains(entry.key.toLowerCase())) {
        candidateGenerics.addAll(entry.value);
      }
    }

    final allRecords = await _getAllRecords();

    final directMatches = <MedicineEntity>[];
    for (final med in allRecords) {
      if (lowerQuery.contains(med.genericName.toLowerCase())) {
        directMatches.add(med);
      } else {
        for (final b in med.brandNames.split(',')) {
          final cleanB = b.trim().toLowerCase();
          if (cleanB.isNotEmpty && lowerQuery.contains(cleanB)) {
            directMatches.add(med);
            break;
          }
        }
      }
    }

    final finalGenerics = <String>{
      ...directMatches.map((m) => m.genericName),
      ...candidateGenerics,
    };

    final matchedRecords = allRecords
        .where((med) => finalGenerics.contains(med.genericName))
        .toList();

    return _filterAndRankByRelevance(matchedRecords, lowerQuery);
  }

  static Future<List<MedicineEntity>> search(String query) async {
    return MedicineLocalDb.instance.searchMedications(query);
  }

  List<MedicineEntity> _filterAndRankByRelevance(
    List<MedicineEntity> matches,
    String lowerQuery,
  ) {
    final isPediatric = isPediatricQuery(lowerQuery);
    final isHypertension = lowerQuery.contains('hypertension') ||
        lowerQuery.contains('high blood pressure') ||
        lowerQuery.contains('bp');
    final isDiabetes = lowerQuery.contains('diabetes') ||
        lowerQuery.contains('blood sugar') ||
        lowerQuery.contains('glucose');
    final isGastric = lowerQuery.contains('stomach') ||
        lowerQuery.contains('heartburn') ||
        lowerQuery.contains('gastritis') ||
        lowerQuery.contains('acid') ||
        lowerQuery.contains('gerd');
    final isWateryDiarrhea = lowerQuery.contains('diarrhea') ||
        lowerQuery.contains('diarrhoea') ||
        lowerQuery.contains('loose motions') ||
        lowerQuery.contains('motions') ||
        lowerQuery.contains('watery stool');
    final isCongestion = lowerQuery.contains('congestion') ||
        lowerQuery.contains('runny nose') ||
        lowerQuery.contains('stuffy nose');

    final filtered = matches.where((med) {
      final genLower = med.genericName.toLowerCase();
      final indLower = med.indications.toLowerCase();

      if (isPediatric &&
          (genLower.contains('diclofenac') ||
              genLower.contains('naproxen') ||
              genLower.contains('atorvastatin') ||
              genLower.contains('metformin') ||
              genLower.contains('amlodipine') ||
              genLower.contains('lisinopril'))) {
        return false;
      }

      if (isHypertension &&
          !isDiabetes &&
          (genLower.contains('metformin') || indLower.contains('diabetes'))) {
        return false;
      }

      if (isDiabetes &&
          !isHypertension &&
          (genLower.contains('amlodipine') ||
              genLower.contains('lisinopril') ||
              indLower.contains('hypertension'))) {
        return false;
      }

      if (isGastric &&
          !isWateryDiarrhea &&
          (genLower.contains('oral rehydration') ||
              genLower.contains('salts'))) {
        return false;
      }

      if (isGastric &&
          (genLower.contains('ibuprofen') ||
              genLower.contains('diclofenac') ||
              genLower.contains('naproxen') ||
              genLower.contains('aspirin'))) {
        return false;
      }

      if (isCongestion &&
          (genLower.contains('amlodipine') ||
              genLower.contains('lisinopril') ||
              genLower.contains('metformin') ||
              genLower.contains('atorvastatin'))) {
        return false;
      }

      return true;
    }).toList();

    return filtered.take(2).toList();
  }

  Future<List<MedicineEntity>> _getAllRecords() async {
    if (kIsWeb || _database == null) {
      return _webCache ?? _seedRecords;
    }

    try {
      final maps = await _database!.query(_tableName);
      if (maps.isEmpty) {
        return _seedRecords;
      }
      return maps.map((map) => MedicineEntity.fromMap(map)).toList();
    } catch (_) {
      return _seedRecords;
    }
  }

  Future<MedicineEntity?> getMedicineById(int id) async {
    if (kIsWeb || _database == null) {
      final records = _webCache ?? _seedRecords;
      try {
        return records.firstWhere((r) => r.id == id);
      } catch (_) {
        return null;
      }
    }

    final maps = await _database!.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return MedicineEntity.fromMap(maps.first);
    }
    return null;
  }

  Future<MedicineEntity?> getMedicineByGenericName(String genericName) async {
    final records = await _getAllRecords();
    try {
      return records.firstWhere(
        (r) => r.genericName.toLowerCase() == genericName.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  static const List<MedicineEntity> _seedRecords = [
    MedicineEntity(
      id: 1,
      genericName: 'Paracetamol',
      brandNames: 'Panadol, Calpol, Disprol, Febrol',
      therapeuticClass: 'Analgesic & Antipyretic',
      indications: 'Mild to moderate pain, headache, tension headache, migraine, fever reduction in viral infections.',
      adultDosage: '500 mg to 1000 mg every 4-6 hours as needed.',
      pediatricDosage: '10-15 mg/kg per dose every 4-6 hours. Max 60 mg/kg/day.',
      maxDailyLimit: '4000 mg (4 grams / 8 x 500mg tablets) per 24 hours. (Strict hepatotoxicity ceiling)',
      contraindications: 'Severe hepatic impairment, acute liver failure, severe active hepatitis, hypersensitivity to paracetamol.',
      adverseReactions: 'Rare at therapeutic doses. Hepatotoxicity with overdose, nausea, rash.',
      emergencyRedFlags: 'Ingestion of >4000 mg/day or >7.5 g acutely requires immediate emergency N-acetylcysteine (NAC) administration. Yellowing of eyes/skin (jaundice), severe right upper quadrant abdominal pain.',
      precautionsAndInteractions: 'Use with extreme caution in chronic alcoholism, malnutrition, severe renal impairment. Avoid concurrent use with multiple OTC paracetamol-containing combination products to prevent accidental overdose.',
      dietaryLifestyleAdvice: 'May be taken with or without food. Ensure adequate hydration during febrile illnesses.',
    ),
    MedicineEntity(
      id: 2,
      genericName: 'Ibuprofen',
      brandNames: 'Brufen, Advil, Motrin',
      therapeuticClass: 'NSAID (Non-Steroidal Anti-Inflammatory Drug)',
      indications: 'Inflammatory pain, musculoskeletal pain, toothache, dysmenorrhea, arthritis, fever.',
      adultDosage: '400 mg every 6-8 hours with or immediately after meals.',
      pediatricDosage: '5-10 mg/kg per dose every 6-8 hours (infants >6 months only). Max 40 mg/kg/day.',
      maxDailyLimit: '1200 mg/day for OTC self-care (Max 2400 mg/day under strict medical supervision).',
      contraindications: 'Active peptic ulcer disease, history of GI bleeding or perforation, severe heart failure (NYHA Class IV), severe renal failure (eGFR <30 mL/min), third trimester of pregnancy, active Dengue infection.',
      adverseReactions: 'Gastric irritation, epigastric burning, nausea, peptic ulceration, renal function decline, fluid retention, hypertension.',
      emergencyRedFlags: 'Black tarry stools (melena), vomiting blood or coffee-ground emesis, sudden severe abdominal pain (perforation), sudden shortness of breath.',
      precautionsAndInteractions: 'Absolute contraindication in suspected Dengue fever due to increased hemorrhagic risk. Never combine with ACE inhibitors/ARBs and Diuretics (Triple Whammy Acute Kidney Injury risk). Always administer with food or co-prescribe a PPI in elderly or high-risk patients.',
      dietaryLifestyleAdvice: 'Always take with a full meal or glass of milk. Avoid alcohol consumption during NSAID therapy.',
    ),
    MedicineEntity(
      id: 3,
      genericName: 'Oral Rehydration Salts',
      brandNames: 'ORS, Pedialyte, Nimkol, Hydralyte',
      therapeuticClass: 'Electrolyte & Fluid Replenisher',
      indications: 'Prevention and treatment of mild to moderate dehydration caused by acute diarrhea, gastroenteritis, cholera, or excessive vomiting.',
      adultDosage: '200 mL to 400 mL (1-2 glasses) slowly after each loose stool or watery motion.',
      pediatricDosage: 'Under 2 years: 50-100 mL after each stool. 2-10 years: 100-200 mL after each stool.',
      maxDailyLimit: 'No toxic upper ceiling; match fluid intake to volume of ongoing fluid loss.',
      contraindications: 'Intractable vomiting preventing oral intake, severe hemodynamic shock, paralytic ileus, bowel perforation.',
      adverseReactions: 'Rare vomiting if ingested too rapidly. Hypernatremia if mixed with insufficient water.',
      emergencyRedFlags: 'Inability to drink or unconsciousness, sunken eyes, skin pinch retracts very slowly (>2 seconds), absence of urination for over 8 hours.',
      precautionsAndInteractions: 'Strictly dissolve one standard sachet in exactly 1 Liter of clean boiled and cooled drinking water. Do not boil prepared solution. Discard remaining solution after 24 hours.',
      dietaryLifestyleAdvice: 'Continue breastfeeding infants. In adults, continue light bland diet (BRAT diet: bananas, rice, applesauce, toast). Avoid sugary sodas, commercial juices, and high-fat foods.',
    ),
    MedicineEntity(
      id: 4,
      genericName: 'Omeprazole',
      brandNames: 'Losec, Prilosec, Risek, Omez',
      therapeuticClass: 'Proton Pump Inhibitor (PPI)',
      indications: 'Gastroesophageal reflux disease (GERD), acid peptic disease, healing of gastric and duodenal ulcers, eradication of H. pylori (with antibiotics), prevention of NSAID-induced gastropathy.',
      adultDosage: '20 mg once daily taken 30-60 minutes before breakfast.',
      pediatricDosage: '0.7-1.4 mg/kg once daily under specialist pediatric guidance.',
      maxDailyLimit: '40 mg per day for standard acid suppression (80 mg/day in Zollinger-Ellison syndrome).',
      contraindications: 'Hypersensitivity to omeprazole or substituted benzimidazoles. Co-administration with rilpivirine.',
      adverseReactions: 'Headache, diarrhea, nausea, flatulence, abdominal pain, constipation.',
      emergencyRedFlags: 'Unexplained weight loss, recurrent vomiting, dysphagia (difficulty swallowing), hematemesis or melena (requires urgent endoscopy to rule out gastric malignancy).',
      precautionsAndInteractions: 'May reduce absorption of Vitamin B12, iron, and magnesium with prolonged (>1 year) use. Interacts with clopidogrel (decreases active metabolite formation; pantoprazole preferred).',
      dietaryLifestyleAdvice: 'Swallow capsule whole with water; do not crush or chew beads. Avoid eating within 3 hours before bedtime. Elevate the head of your bed if nocturnal reflux is present. Reduce caffeine, spicy food, citrus, and mint.',
    ),
    MedicineEntity(
      id: 5,
      genericName: 'Cetirizine',
      brandNames: 'Zyrtec, Cirrus, Rigix',
      therapeuticClass: 'Second-Generation Antihistamine',
      indications: 'Allergic rhinitis, seasonal hay fever, urticaria (hives), allergic conjunctivitis, itching, skin allergies.',
      adultDosage: '10 mg once daily (preferably in the evening).',
      pediatricDosage: '2-6 years: 2.5 mg once daily (max 5 mg). 6-12 years: 5 mg twice daily or 10 mg once daily.',
      maxDailyLimit: '10 mg per 24 hours (adults).',
      contraindications: 'Severe end-stage renal disease (eGFR <10 mL/min or hemodialysis). Hypersensitivity to cetirizine or hydroxyzine.',
      adverseReactions: 'Mild somnolence/drowsiness (low incidence compared to first-gen), dry mouth, fatigue, headache.',
      emergencyRedFlags: 'Facial swelling, swelling of lips/tongue, difficulty breathing, stridor (signs of severe anaphylaxis requiring emergency intramuscular epinephrine and Rescue 1122 / 911).',
      precautionsAndInteractions: 'Dose must be reduced to 5 mg every other day in moderate-to-severe renal impairment. Avoid concomitant alcohol or central nervous system depressants.',
      dietaryLifestyleAdvice: 'May be taken with or without food. Avoid operating heavy machinery or driving until individual sedative reaction is established.',
    ),
    MedicineEntity(
      id: 6,
      genericName: 'Salbutamol',
      brandNames: 'Ventolin, ProAir, Asthalin',
      therapeuticClass: 'Short-Acting Beta-2 Agonist (SABA) Bronchodilator',
      indications: 'Relief of acute bronchospasm in asthma, chronic obstructive pulmonary disease (COPD), exercise-induced bronchospasm.',
      adultDosage: '1-2 puffs (100-200 mcg) via MDI inhaler every 4-6 hours as needed for acute shortness of breath.',
      pediatricDosage: '1-2 puffs (100-200 mcg) via spacer device under adult supervision for acute wheezing.',
      maxDailyLimit: '8 puffs (800 mcg) per 24 hours for routine outpatient management.',
      contraindications: 'Hypersensitivity to salbutamol. Not indicated for prevention of threatened abortion in oral form.',
      adverseReactions: 'Fine skeletal muscle tremor (especially hands), tachycardia, palpitations, headache, hypokalemia at high doses.',
      emergencyRedFlags: 'Inability to speak in full sentences, silent chest (absence of wheeze with severe dyspnea), cyanosis, lack of relief 15 minutes after 4-6 puffs (acute life-threatening asthma exacerbation requiring immediate emergency transfer).',
      precautionsAndInteractions: 'Overreliance on short-acting beta agonists without inhaled corticosteroid (ICS) indicates poorly controlled asthma and increases mortality risk. Use with caution in cardiovascular disorders, arrhythmias, and hyperthyroidism.',
      dietaryLifestyleAdvice: 'Always rinse mouth after inhalation if using combination products. Ensure correct inhaler technique with a spacer chamber for optimal bronchial deposition.',
    ),
    MedicineEntity(
      id: 7,
      genericName: 'Amoxicillin',
      brandNames: 'Amoxil, Augmentin (with Clavulanate), Trimox',
      therapeuticClass: 'Beta-Lactam Antibiotic (Aminopenicillin)',
      indications: 'Bacterial infections including acute otitis media, streptococcal pharyngitis, sinusitis, community-acquired pneumonia, uncomplicated urinary tract infections.',
      adultDosage: '500 mg every 8 hours or 875 mg every 12 hours for 5 to 7 days.',
      pediatricDosage: '25-45 mg/kg/day divided every 12 hours (High-dose otitis media: 80-90 mg/kg/day).',
      maxDailyLimit: '3000 mg per 24 hours (adults).',
      contraindications: 'Known immediate hypersensitivity or anaphylaxis to penicillins or beta-lactam antibiotics.',
      adverseReactions: 'Diarrhea, nausea, vomiting, maculopapular rash, Clostridioides difficile-associated diarrhea.',
      emergencyRedFlags: 'Urticarial rash within 1 hour of ingestion, facial angioedema, wheezing, hypotension (anaphylaxis). Severe profuse watery diarrhea with fever.',
      precautionsAndInteractions: 'Prescription-only medication. Ineffective against viral infections (common cold, flu). Patients with infectious mononucleosis develop a high incidence of rash; avoid amoxicillin if glandular fever is suspected.',
      dietaryLifestyleAdvice: 'May be taken with food to minimize gastrointestinal discomfort. Complete the full prescribed course even if symptoms resolve earlier.',
    ),
    MedicineEntity(
      id: 8,
      genericName: 'Diclofenac',
      brandNames: 'Voltaren, Cataflam, Dicloran',
      therapeuticClass: 'NSAID (Phenylacetic Acid Derivative)',
      indications: 'Acute severe inflammatory pain, osteoarthritic flare-ups, rheumatoid arthritis, acute gout, renal colic, post-operative dental pain.',
      adultDosage: '50 mg 2-3 times daily with food, or 75 mg slow-release once to twice daily.',
      pediatricDosage: 'Not recommended for children under 14 years without pediatric rheumatology supervision.',
      maxDailyLimit: '150 mg per 24 hours.',
      contraindications: 'Active peptic ulcer, ischemic heart disease, peripheral arterial disease, cerebrovascular disease, congestive heart failure, severe renal impairment, active Dengue infection.',
      adverseReactions: 'Epigastric pain, nausea, peptic ulcer, elevated liver transaminases, fluid retention, hypertension, increased cardiovascular thrombotic events.',
      emergencyRedFlags: 'Crushing chest pain or neurological deficits (increased myocardial infarction/stroke risk), hematemesis, black tarry stools.',
      precautionsAndInteractions: 'Has the highest cardiovascular thrombotic risk among standard traditional NSAIDs. Use lowest effective dose for shortest possible duration. Strongly avoid in patients with known ischemic heart disease or high cardiovascular risk.',
      dietaryLifestyleAdvice: 'Take with a full meal and a large glass of water. Avoid lying flat for 30 minutes after tablet ingestion.',
    ),
    MedicineEntity(
      id: 9,
      genericName: 'Famotidine',
      brandNames: 'Pepcid, Famocid, Gastrosidin',
      therapeuticClass: 'Histamine H2-Receptor Antagonist (H2RA)',
      indications: 'Short-term relief and management of heartburn, acid indigestion, sour stomach, gastroesophageal reflux, healing of active peptic ulcers.',
      adultDosage: '20 mg to 40 mg once daily at bedtime, or 20 mg twice daily 15-60 minutes before meals.',
      pediatricDosage: '0.5 mg/kg once or twice daily under pediatric guidance (max 40 mg/day).',
      maxDailyLimit: '40 mg per 24 hours (80 mg/day in severe ulcer/reflux disease).',
      contraindications: 'Hypersensitivity to famotidine or other H2-receptor antagonists.',
      adverseReactions: 'Headache, dizziness, constipation, diarrhea.',
      emergencyRedFlags: 'Difficulty or pain swallowing, vomiting blood, black stools. Symptoms persisting beyond 14 days of OTC treatment.',
      precautionsAndInteractions: 'Adjust dosage in moderate-to-severe renal impairment (reduce dose by 50% if eGFR <50 mL/min). Safe alternative to PPIs for intermittent mild acid rebound.',
      dietaryLifestyleAdvice: 'Take 15-60 minutes before consuming foods or beverages that trigger heartburn (e.g., spicy curries, fried items, coffee). Avoid smoking and late-night eating.',
    ),
    MedicineEntity(
      id: 10,
      genericName: 'Loratadine',
      brandNames: 'Claritin, Loratin, Softin',
      therapeuticClass: 'Non-Sedating Second-Generation Antihistamine',
      indications: 'Allergic rhinitis, persistent sneezing, rhinorrhea, itchy/watery eyes, chronic idiopathic urticaria.',
      adultDosage: '10 mg once daily.',
      pediatricDosage: '2-12 years (<30 kg): 5 mg once daily. (>30 kg): 10 mg once daily.',
      maxDailyLimit: '10 mg per 24 hours.',
      contraindications: 'Hypersensitivity to loratadine or desloratadine.',
      adverseReactions: 'Headache, dry mouth, fatigue. True non-sedating profile at recommended doses.',
      emergencyRedFlags: 'Severe lip or laryngeal angioedema, respiratory compromise (anaphylaxis protocol mandatory).',
      precautionsAndInteractions: 'Dosing interval should be adjusted to 10 mg every other day in severe hepatic insufficiency.',
      dietaryLifestyleAdvice: 'Can be taken with or without food. Excellent daytime antihistamine option for students, drivers, and heavy machinery operators.',
    ),
    MedicineEntity(
      id: 11,
      genericName: 'Metformin',
      brandNames: 'Glucophage, Neodipar, Fortamet',
      therapeuticClass: 'Biguanide Antidiabetic Agent',
      indications: 'First-line pharmacological management of Type 2 Diabetes Mellitus, especially in overweight individuals; polycystic ovary syndrome (PCOS).',
      adultDosage: 'Initial: 500 mg once or twice daily with meals. Titrate gradually to 1000 mg twice daily.',
      pediatricDosage: 'Children >=10 years: 500 mg once or twice daily (max 2000 mg/day).',
      maxDailyLimit: '2000 mg to 2550 mg per 24 hours in divided doses.',
      contraindications: 'Severe renal impairment (eGFR <30 mL/min), acute metabolic acidosis, diabetic ketoacidosis (DKA), tissue hypoxia (decompensated heart failure, severe sepsis), acute alcohol intoxication.',
      adverseReactions: 'Gastrointestinal upset (nausea, abdominal bloating, diarrhea, metallic taste), long-term Vitamin B12 deficiency.',
      emergencyRedFlags: 'Kussmaul breathing (deep, rapid breathing), severe malaise, muscle cramps, hypothermia, severe drowsiness (Signs of rare but life-threatening Lactic Acidosis; emergency admission mandatory).',
      precautionsAndInteractions: 'Withhold for 48 hours prior to and following iodinated radiological contrast procedures in patients with reduced eGFR. Titrate slowly over several weeks to mitigate GI adverse effects.',
      dietaryLifestyleAdvice: 'Always consume with or immediately after meals to reduce stomach distress. Adhere strictly to low-glycemic Mediterranean or diabetic dietary guidelines and routine physical exercise.',
    ),
    MedicineEntity(
      id: 12,
      genericName: 'Amlodipine',
      brandNames: 'Norvasc, Amlopress, Amcard',
      therapeuticClass: 'Dihydropyridine Calcium Channel Blocker',
      indications: 'Essential hypertension, chronic stable angina, vasospastic (Prinzmetal) angina.',
      adultDosage: 'Initial: 5 mg once daily. May be titrated after 1-2 weeks to 10 mg once daily.',
      pediatricDosage: 'Children 6-17 years: 2.5 mg to 5 mg once daily.',
      maxDailyLimit: '10 mg once daily.',
      contraindications: 'Severe hypotension, cardiogenic shock, clinically significant aortic stenosis, unstable angina.',
      adverseReactions: 'Peripheral ankle edema, flushing, headache, dizziness, fatigue, palpitations.',
      emergencyRedFlags: 'Severe dizziness with fainting, sudden chest pain flare upon initiation, resting blood pressure <90/60 mmHg.',
      precautionsAndInteractions: 'Start with 2.5 mg daily in elderly patients or severe hepatic impairment. Does not cause bradycardia. Co-administration with simvastatin may require limiting simvastatin to 20 mg/day.',
      dietaryLifestyleAdvice: 'Take once daily at the same time every morning. Elevate legs when resting if mild dependent ankle edema occurs. Avoid concurrent excessive grapefruit juice.',
    ),
    MedicineEntity(
      id: 13,
      genericName: 'Azithromycin',
      brandNames: 'Zithromax, Azomax, Macrolar',
      therapeuticClass: 'Macrolide Antibiotic (Azalide)',
      indications: 'Upper and lower respiratory tract infections, atypical pneumonia (Mycoplasma/Chlamydia), acute bacterial sinusitis, tonsillitis, skin infections, uncomplicated chlamydial urethritis.',
      adultDosage: '500 mg once daily for 3 days; or 500 mg on day 1 followed by 250 mg once daily on days 2 to 5.',
      pediatricDosage: '10 mg/kg once daily for 3 days (or 10 mg/kg day 1, then 5 mg/kg days 2-5).',
      maxDailyLimit: '500 mg once daily (respiratory tract infections).',
      contraindications: 'Hypersensitivity to azithromycin, erythromycin, or any macrolide/ketolide. History of cholestatic jaundice or hepatic dysfunction with prior azithromycin use.',
      adverseReactions: 'Diarrhea, nausea, abdominal cramps, vomiting, headache, transient hearing impairment at high doses.',
      emergencyRedFlags: 'Palpitations, syncope, QT prolongation, polymorphic ventricular tachycardia (Torsades de Pointes). Severe skin reaction (Stevens-Johnson syndrome).',
      precautionsAndInteractions: 'Prescription-only medication. Use with extreme caution in patients with known baseline QT prolongation, hypokalemia, or concurrent antiarrhythmic therapy (amiodarone, sotalol). Ineffective for viral flu.',
      dietaryLifestyleAdvice: 'May be taken with or without food, though taking with food reduces gastrointestinal side effects. Complete the short 3-day or 5-day cycle fully as prescribed.',
    ),
    MedicineEntity(
      id: 14,
      genericName: 'Ferrous Sulfate & Folic Acid',
      brandNames: 'Fefol, Iberet Folic, Fero-Folic',
      therapeuticClass: 'Hematinic & Micronutrient Supplement',
      indications: 'Prevention and treatment of iron deficiency anemia, megaloblastic anemia, nutritional anemia of pregnancy and lactation.',
      adultDosage: 'One capsule or tablet daily containing 150-200 mg dried ferrous sulfate (approx 60 mg elemental iron) and 400-500 mcg folic acid.',
      pediatricDosage: 'Liquid iron drops titrated by pediatric weight (3-6 mg elemental iron/kg/day).',
      maxDailyLimit: 'One to two tablets daily under medical hematology supervision.',
      contraindications: 'Hemochromatosis, hemosiderosis, hemolytic anemia, active peptic ulcer disease, repeated blood transfusions.',
      adverseReactions: 'Dark/black stools (benign), constipation, nausea, epigastric discomfort, heartburn.',
      emergencyRedFlags: 'Accidental pediatric ingestion of iron tablets can cause severe, fatal iron toxicity. Keep strictly out of reach of young children.',
      precautionsAndInteractions: 'Do not take simultaneously with antacids, calcium supplements, milk, tea, or coffee as they drastically inhibit iron absorption. Space by at least 2 hours.',
      dietaryLifestyleAdvice: 'Absorption is significantly enhanced when taken with a source of Vitamin C (fresh orange juice, citrus fruits). Consume green leafy vegetables, lentils, and lean red meats.',
    ),
    MedicineEntity(
      id: 15,
      genericName: 'Antacids (Aluminum & Magnesium Hydroxide)',
      brandNames: 'Maalox, Mucaine, Gaviscon, Digene',
      therapeuticClass: 'Oral Chemical Antacid',
      indications: 'Rapid symptomatic relief of heartburn, acid indigestion, sour stomach, and hyperacidity associated with gastritis and peptic ulcer.',
      adultDosage: '10 mL to 20 mL (2-4 teaspoons) of suspension or 1-2 chewable tablets 1 hour after meals and at bedtime.',
      pediatricDosage: 'Not recommended for routine self-care in children under 6 years without pediatric direction.',
      maxDailyLimit: 'Maximum 80 mL or 12 chewable tablets in a 24-hour period.',
      contraindications: 'Severe renal failure (risk of magnesium toxicity and aluminum accumulation), appendicitis, hypophosphatemia.',
      adverseReactions: 'Magnesium causes diarrhea; aluminum causes constipation (combination formulations balance bowel effects). Chalky taste.',
      emergencyRedFlags: 'Severe persistent vomiting, unremitting abdominal pain, gastrointestinal bleeding.',
      precautionsAndInteractions: 'Chemical antacids bind and significantly decrease the bioavailability of many drugs including fluoroquinolones, tetracyclines, iron, and azithromycin. Administer at least 2 hours before or after other medications.',
      dietaryLifestyleAdvice: 'Chew tablets completely followed by a glass of water. Avoid carbonated beverages, chocolate, peppermint, and lying flat after meals.',
    ),
    MedicineEntity(
      id: 16,
      genericName: 'Lisinopril',
      brandNames: 'Zestril, Prinivil',
      therapeuticClass: 'Angiotensin-Converting Enzyme (ACE) Inhibitor',
      indications: 'Hypertension, heart failure (adjunctive), acute myocardial infarction (within 24 hours), diabetic nephropathy in type 1 and type 2 diabetics.',
      adultDosage: 'Initial: 10 mg once daily. Maintenance: 20-40 mg once daily.',
      pediatricDosage: 'Children >=6 years: 0.07 mg/kg once daily (max 5 mg initially).',
      maxDailyLimit: '40 mg to 80 mg once daily.',
      contraindications: 'History of angioedema related to prior ACE inhibitor therapy, hereditary/idiopathic angioedema, pregnancy (fetal toxicity/death in 2nd and 3rd trimesters), concurrent use with aliskiren in diabetics.',
      adverseReactions: 'Persistent dry tickling cough (bradykinin-mediated), hyperkalemia, dizziness, hypotension, elevated serum creatinine.',
      emergencyRedFlags: 'Swelling of the face, lips, tongue, or glottis causing airway obstruction (angioedema requires immediate ER intervention).',
      precautionsAndInteractions: 'Never combine with NSAIDs and Diuretics (Triple Whammy renal failure). Monitor serum potassium and renal function closely. Avoid potassium supplements and salt substitutes containing potassium.',
      dietaryLifestyleAdvice: 'Maintain consistent fluid intake. Do not use potassium-based salt substitutes without physician approval.',
    ),
    MedicineEntity(
      id: 17,
      genericName: 'Atorvastatin',
      brandNames: 'Lipitor, Atorva, Lipiget',
      therapeuticClass: 'HMG-CoA Reductase Inhibitor (Statin)',
      indications: 'Hypercholesterolemia, primary prevention of cardiovascular events (myocardial infarction, stroke) in high-risk patients, secondary prevention in coronary heart disease.',
      adultDosage: '10 mg to 20 mg once daily. High-intensity therapy: 40 mg to 80 mg once daily.',
      pediatricDosage: 'Familial hypercholesterolemia (>=10 years): 10 mg once daily (max 20 mg).',
      maxDailyLimit: '80 mg once daily.',
      contraindications: 'Active liver disease, unexplained persistent elevations of hepatic transaminases, pregnancy, breastfeeding.',
      adverseReactions: 'Myalgia (muscle aches), headache, elevated liver enzymes, mild gastrointestinal disturbances, slight increase in blood glucose.',
      emergencyRedFlags: 'Unexplained severe muscle pain, tenderness, or weakness accompanied by dark tea-colored urine (Rhabdomyolysis; emergency cessation and renal preservation protocol).',
      precautionsAndInteractions: 'Strong CYP3A4 inhibitors (clarithromycin, itraconazole) increase plasma levels and myopathy risk. Perform baseline liver function testing prior to initiation.',
      dietaryLifestyleAdvice: 'May be taken at any time of day, with or without food. Combine with a low-cholesterol, low-saturated fat Mediterranean diet and regular aerobic exercise. Avoid large quantities of grapefruit juice.',
    ),
    MedicineEntity(
      id: 18,
      genericName: 'Naproxen',
      brandNames: 'Aleve, Naprosyn, Synflex',
      therapeuticClass: 'NSAID (Propionic Acid Derivative)',
      indications: 'Osteoarthritis, rheumatoid arthritis, ankylosing spondylitis, acute tendonitis, acute gout, dysmenorrhea, migraine.',
      adultDosage: '250 mg to 500 mg twice daily with meals (or 500 mg initially followed by 250 mg every 6-8 hours).',
      pediatricDosage: 'Juvenile idiopathic arthritis (>=2 years): 10 mg/kg/day divided in two doses with food.',
      maxDailyLimit: '1250 mg per day acutely (1000 mg/day chronic maintenance).',
      contraindications: 'Active peptic ulcer, GI bleeding, severe renal impairment (eGFR <30), severe heart failure, third trimester of pregnancy, active Dengue infection.',
      adverseReactions: 'Dyspepsia, heartburn, nausea, gastric ulceration, headache, fluid retention.',
      emergencyRedFlags: 'Gastrointestinal hemorrhage (melena, hematemesis), acute kidney injury (anuria), anaphylactoid reactions.',
      precautionsAndInteractions: 'Naproxen is associated with a relatively lower cardiovascular thrombotic risk compared to other traditional NSAIDs, but retains substantial gastrointestinal toxicity. Avoid co-administration with other NSAIDs or anticoagulants.',
      dietaryLifestyleAdvice: 'Always ingest with a substantial meal or glass of milk. Stay well-hydrated throughout therapy.',
    ),
    MedicineEntity(
      id: 19,
      genericName: 'Normal Saline Nasal Spray',
      brandNames: 'Ocean, Sterimar, Solin, Nasospray',
      therapeuticClass: 'Isotonic / Decongestive Nasal Irrigation',
      indications: 'Relief of nasal congestion, dry or crusted nasal passages, allergic rhinitis, viral upper respiratory tract infection, post-nasal drip.',
      adultDosage: '2 to 3 sprays in each nostril 3-4 times daily as needed.',
      pediatricDosage: '1 to 2 drops/sprays in each nostril before feedings and at bedtime (safe for infants and newborns).',
      maxDailyLimit: 'No toxic upper ceiling; non-medicated, non-habit forming physiological solution.',
      contraindications: 'None for standard isotonic 0.9% sterile saline formulations.',
      adverseReactions: 'Occasional mild transient nasal stinging or irritation.',
      emergencyRedFlags: 'Unilateral foul-smelling discharge in young children (suspect foreign body inhalation/insertion). Clear fluid dripping continuously following head trauma (suspect CSF rhinorrhea).',
      precautionsAndInteractions: 'Completely safe alternative to medicated adrenergic nasal sprays (e.g., oxymetazoline) which cause rebound congestion (rhinitis medicamentosa) if used beyond 3-5 days. Does not interact with systemic medications.',
      dietaryLifestyleAdvice: 'Blow nose gently before administration. In infants, use a gentle bulb syringe 5 minutes after administering drops to clear loosened secretions.',
    ),
    MedicineEntity(
      id: 20,
      genericName: 'Vitamin D3 (Cholecalciferol)',
      brandNames: 'D-Cure, Indrop-D, Caltrate-D, Sunny D',
      therapeuticClass: 'Fat-Soluble Secosteroid Micronutrient',
      indications: 'Prevention and treatment of Vitamin D deficiency, rickets, osteomalacia, maintenance of bone mineral density, adjunctive treatment of osteoporosis.',
      adultDosage: 'Treatment of severe deficiency: 50,000 IU once weekly for 8 weeks (or 200,000 IU oral single dose monthly for 2 months under supervision). Maintenance: 800-2000 IU daily.',
      pediatricDosage: 'Infants: 400 IU daily. Nutritional rickets treatment: 1000-5000 IU daily for 12 weeks under pediatric supervision.',
      maxDailyLimit: '4000 IU per day for routine OTC dietary supplementation without serum 25(OH)D monitoring.',
      contraindications: 'Hypercalcemia, hypervitaminosis D, metastatic bone calcification, severe renal osteodystrophy with hyperphosphatemia.',
      adverseReactions: 'Rare at physiological doses. Signs of toxicity (hypercalcemia): nausea, vomiting, polyuria, polydipsia, weakness, renal calculi.',
      emergencyRedFlags: 'Confusion, cardiac arrhythmias, severe dehydration and vomiting from massive accidental over-dosage.',
      precautionsAndInteractions: 'Ensure adequate dietary calcium intake. Thiazide diuretics reduce urinary calcium excretion and increase hypercalcemia risk. Phenytoin and carbamazepine accelerate vitamin D metabolism.',
      dietaryLifestyleAdvice: 'As a fat-soluble vitamin, oral drops or capsules are best absorbed when consumed with the largest meal of the day containing healthy dietary fats. Engage in safe midday sun exposure.',
    ),
  ];
}
