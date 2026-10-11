
/// Layer 1: Zero-Tolerance Deterministic Triage Interceptors.
/// Executes before calling the inference runtime to prevent lethal advice,
/// severe contraindications, and emergency triage delays.
class TriageInterceptor {
  /// Clinical scope notice for non-medical or out-of-scope inquiries.
  static const String outOfScopeResponse = '''🛡️ Clinical Scope Notice
I am Tabib AI, an on-device clinical decision support assistant. I can only assist with physiological symptoms, health assessments, and verified pharmacological guidelines.

I cannot assist with general knowledge, non-medical inquiries, or out-of-scope topics. Please enter a clinical or health-related query to proceed.''';

  /// Standard clinical safety notice for self-harm or lethal dosing inquiries.
  static const String lethalWarningResponse = '''⚠️ CLINICAL SAFETY & REFUSAL NOTICE
Tabib AI strictly prohibits assisting with lethal dosing, intentional self-harm, or substance misuse.

If you or someone you know is in distress or at risk:
• Emergency Services: Dial 1122 or 911 immediately.
• Crisis Support: Contact a mental health helpline or visit the nearest emergency room.

What Tabib AI is designed to do:
• Provide verified OTC dosage guidance and ceiling limits.
• Check drug-drug contraindications and pediatric dosing by weight.
• Identify emergency red-flag symptoms requiring urgent medical care.
• Offer evidence-based lifestyle, dietary, and supportive health advice.''';

  /// Structured emergency alert for acute stroke and myocardial infarction.
  static const String emergencyAlertResponse = '''🚨 MEDICAL EMERGENCY DETECTED (TIME-CRITICAL):
These symptoms strongly indicate an Acute Stroke (Brain Attack) or Acute Myocardial Infarction (Heart Attack).
Every minute is vital (Time is Brain / Heart).
• DO NOT take painkillers, antacids, or wait for symptoms to subside.
• DO NOT sleep or drive yourself.
• IMMEDIATELY call Rescue 1122 or 911, or proceed to the nearest Emergency Room.''';

  /// Structured emergency alert for acute surgical abdomen.
  static const String emergencySurgicalAbdomenResponse = '''🚨 SURGICAL EMERGENCY TRIAGE (SUSPECTED ACUTE ABDOMEN):
Severe acute abdominal pain with rebound tenderness, localized right lower quadrant pain, involuntary guarding, or suspected appendicitis indicates a surgical emergency (such as Acute Appendicitis or Viscus Perforation).
• DO NOT take painkillers or NSAIDs (e.g., Ibuprofen) as this masks acute surgical signs and delays life-saving surgical intervention.
• DO NOT consume food, liquids, laxatives, or oral medications (patient may require immediate emergency surgery under general anesthesia).
• DO NOT apply hot compresses (can accelerate perforation and generalized peritonitis).
• PROCEED IMMEDIATELY to the nearest Hospital Emergency Department or dial 1122 / 911.''';

  /// Structured emergency alert for diabetic ketoacidosis.
  static const String emergencyDkaResponse = '''🚨 CRITICAL ENDOCRINE EMERGENCY (SUSPECTED DKA):
Sweet or fruity acetone breath, missed insulin in diabetes, rapid deep breathing (Kussmaul respiration), persistent vomiting, severe dehydration, or confusion indicates Diabetic Ketoacidosis (DKA).
• DKA is a life-threatening metabolic emergency requiring immediate hospital admission / ICU triage for IV regular insulin, volume resuscitation, and electrolyte monitoring.
• DO NOT attempt home remedies or wait for clinic hours.
• IMMEDIATELY dial Emergency Services: 1122 or 911, or proceed to the nearest Emergency Room / ICU.''';

  /// Structured emergency alert for acute upper GI bleeding.
  static const String emergencyGiBleedResponse = '''🚨 CRITICAL GASTROINTESTINAL EMERGENCY (SUSPECTED GI BLEED):
Coffee-ground emesis (vomitus), vomiting blood (hematemesis), or black tarry stools (melena) indicates acute upper gastrointestinal hemorrhage.
• DO NOT treat as simple heartburn or take OTC antacids, H2-blockers, or Famotidine.
• DO NOT consume food, liquids, or oral analgesics.
• URGENT emergency endoscopy referral and hemodynamics stabilization required.
• PROCEED IMMEDIATELY to the nearest Hospital Emergency Department or dial 1122 / 911.''';

  /// Structured emergency alert for CKD Stage 4 / renal impairment NSAID contraindication.
  static const String emergencyCkdNsaidResponse = '''🚨 CRITICAL NEPHROLOGY CONTRAINDICATION:
NSAIDs (Naproxen, Ibuprofen, Diclofenac) are STRICTLY CONTRAINDICATED in Chronic Kidney Disease (CKD Stage 4, eGFR < 30 mL/min).
• Mechanism: NSAIDs inhibit renal prostaglandins, precipitating acute-on-chronic renal failure and hyperkalemia.
• Safe Analgesic Protocol: Use Paracetamol (dose-adjusted, max 2000 mg/24h) for mild pain.
• For acute gout in CKD: Consult a nephrologist/rheumatologist immediately for intra-articular steroid injection or oral corticosteroids.''';

  /// Structured emergency alert for Triple Whammy nephrotoxicity.
  static const String emergencyTripleWhammyResponse = '''🚨 CRITICAL NEPHROTOXICITY ALERT ("TRIPLE WHAMMY" AKI RISK):
Concurrent use of an ACE inhibitor/ARB (e.g., Lisinopril), a diuretic (e.g., Furosemide), and an NSAID (e.g., Diclofenac) precipitates severe Acute Kidney Injury (AKI) and acute renal hypoperfusion.
• DO NOT take NSAIDs (Diclofenac/Ibuprofen/Naproxen) while taking ACE inhibitors and diuretics without immediate physician supervision.
• Renal hemodynamics are severely compromised by simultaneous afferent arteriole constriction (NSAID) and efferent arteriole vasodilation (ACEi/ARB).
• CONSULT your prescribing doctor immediately for alternative pain management (safe non-nephrotoxic analgesics) and urgent renal function monitoring (BUN/Serum Creatinine).
• SEEK IMMEDIATE EMERGENCY CARE if experiencing decreased urine output, leg swelling, confusion, or severe nausea.''';

  /// Structured emergency alert for anaphylaxis.
  static const String emergencyAnaphylaxisResponse = '''🚨 CRITICAL MEDICAL EMERGENCY: ANAPHYLAXIS DETECTED:
Airway swelling, difficulty breathing, stridor, wheezing, facial edema with hives, or sudden dizziness indicates life-threatening Anaphylaxis.
• IMMEDIATELY inject Intramuscular Epinephrine (EpiPen, 0.3mg adult / 0.15mg child) into outer mid-thigh if available.
• Call Emergency Services 1122 or 911 immediately.
• Lie flat with legs elevated (unless breathing is compromised, in which case sit up). Do NOT rely on oral antihistamines alone.''';

  /// Conversational greeting response.
  static const String greetingResponse =
      'Hello! I am Tabib AI, your on-device clinical decision support assistant. How can I assist you with your health today? Please describe your symptoms or health concerns.';

  static final RegExp _selfHarmRegex = RegExp(
    r'(lethal toxicity|kill myself|suicide|die\b|end my life|bottle of (?:paracetamol |panadol |aspirin |\d+ )?tablets|bottle of tablets|all at once|overdose|take \d+ pills|50 pills|50 tablets|fatal dose|lethal dose|recreational drug abuse|weaponization|cook meth|make meth)',
    caseSensitive: false,
  );

  static final RegExp _acuteEmergencyRegex = RegExp(
    r'(face droop|facial droop|arm weakness|slurred speech|chest pain left arm|chest heavy pressure|crushing chest pain|radiating to left arm|radiating to jaw|substernal pressure|heart attack|myocardial infarction|stroke|brain attack)',
    caseSensitive: false,
  );

  static final RegExp _anaphylaxisRegex = RegExp(
    r'(anaphylaxis|swollen tongue|tongue swelling|swollen lips|lip swelling|lips swelling|swelling of (?:the )?(?:lips|tongue|throat)|swollen throat|throat closing|can\W*t breathe allergy|stridor|laryngeal edema|angioedema)',
    caseSensitive: false,
  );

  static final RegExp _surgicalAbdomenRegex = RegExp(
    r'(appendicitis|rebound tenderness|rebound pain|acute abdomen|surgical abdomen|rigid abdomen|board-like abdomen|board-like rigidity|guarding abdomen|abdominal guarding|involuntary guarding|right lower quadrant(?: pain| tenderness)?|rlq pain|rlq tenderness|severe lower right stomach pain|lower right abdominal pain|pain in (?:the )?(?:right lower|lower right) (?:quadrant|abdomen|stomach)|mcburney|peritonitis)',
    caseSensitive: false,
  );

  static final RegExp _dkaRegex = RegExp(
    r'(diabetic ketoacidosis|dka\b|kussmaul|(?:sweet|fruity|acetone)(?:\s*or\s*|\s*/\s*|\s+)?(?:breath|smell)|(?:sweet|fruity|acetone)\s+(?:smelling\s+)?breath|missed\s+insulin|forgot\s+(?:my\s+)?insulin|skipped\s+(?:my\s+)?insulin|no\s+insulin|high\s+(?:blood\s+)?sugar\s+(?:with\s+)?(?:vomiting|nausea|confusion|breath|coma)|high\s+glucose\s+(?:with\s+)?(?:vomiting|confusion))',
    caseSensitive: false,
  );

  static final RegExp _giBleedRegex = RegExp(
    r'(coffee[\s-]*ground(?:\s+emesis|\s+vomit|\s+vomitus)?|vomiting blood|vomit blood|throwing up blood|threw up blood|hematemesis|melena|black tarry stool|black tarry stools|blood in vomit|blood in vomitus)',
    caseSensitive: false,
  );

  static final RegExp _aceOrArbRegex = RegExp(
    r'\b(lisinopril|enalapril|ramipril|captopril|perindopril|benazepril|fosinopril|quinapril|losartan|valsartan|candesartan|irbesartan|telmisartan|olmesartan|zestril|prinivil|vasotec|altace|cozaar|diovan|micardis|avapro|atacand|benicar|ace\s*inhibitor|arb)\b',
    caseSensitive: false,
  );

  static final RegExp _diureticRegex = RegExp(
    r'\b(furosemide|lasix|torsemide|bumetanide|hydrochlorothiazide|hctz|chlorthalidone|indapamide|spironolactone|aldactone|eplerenone|diuretic|water\s*pill)\b',
    caseSensitive: false,
  );

  static final RegExp _nsaidRegex = RegExp(
    r'\b(diclofenac|voltaren|cataflam|ibuprofen|brufen|advil|motrin|naproxen|aleve|naprosyn|meloxicam|mobic|celecoxib|celebrex|ketorolac|toradol|indomethacin|indocin|piroxicam|feldene|mefenamic|ponstan|etoricoxib|nsaid|nsaids)\b',
    caseSensitive: false,
  );

  static final RegExp _tripleWhammyExplicitRegex = RegExp(
    r'\b(triple\s*whammy|triple\s*whammy\s*aki|triple\s*whammy\s*nephrotoxicity)\b',
    caseSensitive: false,
  );

  static bool isTripleWhammy(String text) {
    if (_tripleWhammyExplicitRegex.hasMatch(text)) return true;
    final hasAceOrArb = _aceOrArbRegex.hasMatch(text);
    final hasDiuretic = _diureticRegex.hasMatch(text);
    final hasNsaid = _nsaidRegex.hasMatch(text);
    return hasAceOrArb && hasDiuretic && hasNsaid;
  }

  static final RegExp _ckdRegex = RegExp(
    r'\b(ckd\b|chronic\s*kidney|egfr\b|renal\s*failure|creatinine|kidney\s*disease|kidney\s*failure)\b',
    caseSensitive: false,
  );

  static final RegExp _ckdPainOrNsaidRegex = RegExp(
    r'\b(brufen|ibuprofen|naproxen|aleve|naprosyn|diclofenac|voltaren|cataflam|nsaid|nsaids|gout|advil|motrin|celebrex|mobic|toradol|ponstan)\b',
    caseSensitive: false,
  );

  static bool isCkdNsaidContraindicated(String text) {
    final hasCkd = _ckdRegex.hasMatch(text);
    final hasNsaid = _ckdPainOrNsaidRegex.hasMatch(text) || _nsaidRegex.hasMatch(text);
    return hasCkd && hasNsaid;
  }

  static bool isDka(String text) {
    if (_dkaRegex.hasMatch(text)) return true;
    final lower = text.toLowerCase();
    final hasInsulin = lower.contains('insulin');
    final hasMissed = lower.contains('missed') ||
        lower.contains('forgot') ||
        lower.contains('skip') ||
        lower.contains('stopped') ||
        lower.contains('without');
    final hasSymptoms = lower.contains('sweet') ||
        lower.contains('fruity') ||
        lower.contains('breath') ||
        lower.contains('vomit') ||
        lower.contains('sugar');
    return hasInsulin && hasMissed && hasSymptoms;
  }

  static final RegExp _nonMedicalPattern = RegExp(
    r'\b(imran khan|nawaz|biden|trump|politics|cricket|football|movie|actor|code|python|flutter|crypto|bitcoin|who is|weather|ipl|psl|messi|ronaldo|premier league|javascript|java|c\+\+|html|css|president|prime minister|election|stock market|chatgpt|openai)\b',
    caseSensitive: false,
  );

  static final RegExp _medicalTokens = RegExp(
    r'\b(pain|fever|cough|dose|dosage|tablet|tablets|mg|syrup|doctor|headache|ache|blood|pressure|bp|hypertension|hypotension|diabetes|sugar|infection|stomach|throat|rash|swelling|kidney|renal|heart|cardiac|child|children|pediatric|weight|kg|vomit|vomiting|diarrhea|diarrhoea|motions|motion|stool|stools|loose|breathing|breath|cold|flu|allergy|allergic|burn|burning|cut|injury|wound|medicine|medication|pill|capsule|paracetamol|panadol|ibuprofen|brufen|aspirin|antibiotic|antibiotics|nausea|dizzy|dizziness|asthma|inhaler|sprain|fracture|gout|eye|ear|nose|chest|lung|lungs|pulse|temp|temperature|heartburn|acid|reflux|gerd|gastric|gastritis|ulcer|dyspepsia|epigastric|spasm|cramp|cramps|colic|constipation|laxative|ors|hydration|dehydration|salts|drops|cream|ointment|dosing|overdose|poison|poisoning|toxicity|infant|baby|toddler|pregnant|pregnancy|lactation|breastfeeding|derma|skin|itch|itching|hives|urticaria|bleeding|bleed|drainage|pus|abscess|sinus|sinusitis|congestion|runny|sore|strep|pharyngitis|tonsil|tonsillitis|bronchitis|pneumonia|wheeze|wheezing|salbutamol|ventolin|amoxicillin|azithromycin|ciprofloxacin|metformin|insulin|omeprazole|famotidine|antacid|losartan|lisinopril|amlodipine|atorvastatin|furosemide|cefixime|augmentin|flagyl|metronidazole|calpol|arinac|disprin|ponstan|myteka|montelukast|risek|gaviscon|pedialyte)\b',
    caseSensitive: false,
  );

  static bool isMedicalQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return false;
    if (_pureGreetingRegex.hasMatch(trimmed)) return true;
    if (_nonMedicalPattern.hasMatch(trimmed)) return false;
    return _medicalTokens.hasMatch(trimmed);
  }

  static bool isNonMedicalQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return false;
    if (_pureGreetingRegex.hasMatch(trimmed)) return false;
    if (_nonMedicalPattern.hasMatch(trimmed)) return true;
    return !isMedicalQuery(trimmed);
  }

  static final RegExp _pureGreetingRegex = RegExp(
    r'^(?:hi|hello|hey|greetings|good\s+(?:morning|afternoon|evening))[!\.\?\s]*$',
    caseSensitive: false,
  );

  static final RegExp _pseudoephedrineRegex = RegExp(
    r'\b(pseudoephedrine|sudafed|decongestant|phenylephrine)\b',
    caseSensitive: false,
  );

  static BloodPressureReading? extractBloodPressure(String query) {
    final bpRegex = RegExp(
      r'(?:BP|blood\s*pressure)?\s*[:=]?\s*(\d{2,3})\s*(?:/|\\|\s+over\s+|-)\s*(\d{2,3})\s*(?:mm\s*hg)?',
      caseSensitive: false,
    );
    final match = bpRegex.firstMatch(query);
    if (match != null) {
      final sys = int.tryParse(match.group(1) ?? '');
      final dia = int.tryParse(match.group(2) ?? '');
      if (sys != null && dia != null && sys >= 50 && sys <= 260 && dia >= 30 && dia <= 160) {
        return BloodPressureReading(
          systolic: sys,
          diastolic: dia,
          rawBpString: '${match.group(1)}/${match.group(2)}',
        );
      }
    }
    return null;
  }

  static bool hasPseudoephedrineQuery(String query) =>
      _pseudoephedrineRegex.hasMatch(query);

  static TriageResult evaluate(String query) {
    final directive = intercept(query);
    if (directive == null) {
      return const TriageResult(
        isEmergency: false,
        emergencyMessage: null,
        directive: null,
      );
    }

    final trimmed = query.trim();
    if (_pureGreetingRegex.hasMatch(trimmed) || isNonMedicalQuery(trimmed)) {
      return TriageResult(
        isEmergency: false,
        emergencyMessage: null,
        directive: directive,
      );
    }

    return TriageResult(
      isEmergency: true,
      emergencyMessage: directive,
      directive: directive,
    );
  }

  static String? intercept(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();

    if (_pureGreetingRegex.hasMatch(trimmed)) {
      return greetingResponse;
    }

    final bpReading = extractBloodPressure(trimmed);
    if (bpReading != null && bpReading.isHypertensive && hasPseudoephedrineQuery(trimmed)) {
      return 'Pseudoephedrine is strictly contraindicated in uncontrolled hypertension (${bpReading.systolic}/${bpReading.diastolic} mmHg) due to systemic vasoconstriction risks. Use normal saline nasal spray or steam inhalation instead.';
    }

    if (_selfHarmRegex.hasMatch(trimmed) ||
        lower.contains('kill myself') ||
        lower.contains('overdose') ||
        lower.contains('lethal dose') ||
        lower.contains('suicide')) {
      return lethalWarningResponse;
    }

    if (isCkdNsaidContraindicated(trimmed)) {
      return emergencyCkdNsaidResponse;
    }

    if (isTripleWhammy(trimmed)) {
      return emergencyTripleWhammyResponse;
    }

    if (_giBleedRegex.hasMatch(trimmed)) {
      return emergencyGiBleedResponse;
    }

    if (_anaphylaxisRegex.hasMatch(trimmed)) {
      return emergencyAnaphylaxisResponse;
    }

    if (_surgicalAbdomenRegex.hasMatch(trimmed)) {
      return emergencySurgicalAbdomenResponse;
    }

    if (isDka(trimmed)) {
      return emergencyDkaResponse;
    }

    if (_acuteEmergencyRegex.hasMatch(trimmed) ||
        (lower.contains('chest pain') && (lower.contains('arm') || lower.contains('jaw')))) {
      return emergencyAlertResponse;
    }

    if (isNonMedicalQuery(trimmed)) {
      return outOfScopeResponse;
    }

    return null;
  }

  static bool isSurgicalEmergencyOrContraindicated(String query) {
    final trimmed = query.trim();
    return _surgicalAbdomenRegex.hasMatch(trimmed) ||
        _giBleedRegex.hasMatch(trimmed) ||
        isCkdNsaidContraindicated(trimmed) ||
        isTripleWhammy(trimmed);
  }

  static String? getDirective(String query) => intercept(query);

  static bool shouldIntercept(String query) => intercept(query) != null;
}

/// Clinical result model for pre-inference deterministic triage interception.
class TriageResult {
  final bool isEmergency;
  final String? emergencyMessage;
  final String? directive;

  const TriageResult({
    required this.isEmergency,
    this.emergencyMessage,
    this.directive,
  });

  bool get shouldHalt => isEmergency || (directive != null && directive!.isNotEmpty);
}

/// Clinical blood pressure reading model with diagnostic hypertension classification.
class BloodPressureReading {
  final int systolic;
  final int diastolic;
  final String rawBpString;

  const BloodPressureReading({
    required this.systolic,
    required this.diastolic,
    required this.rawBpString,
  });

  bool get isHypertensive => systolic > 140 || diastolic > 90;
}
