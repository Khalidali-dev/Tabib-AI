import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:llamadart/llamadart.dart';
import '../../data/datasources/medicine_local_db.dart';
import '../../data/datasources/model_downloader.dart';
import '../domain.dart';

extension LlamaEngineClearContext on LlamaEngine {
  Future<void> clearContext() async {
    try {
      cancelGeneration();
    } catch (_) {}
  }
}

class MedicalInferenceService {
  MedicalInferenceService._internal();
  static final MedicalInferenceService instance =
      MedicalInferenceService._internal();

  LlamaEngine? _engine;
  String? _activeModelPath;
  bool _isContextInitialized = false;
  StreamSubscription<String>? _tokenSubscription;
  StreamController<String>? _activeTokenStreamController;

  bool get isReady => _isContextInitialized && _engine != null;
  String? get activeModelPath => _activeModelPath;

  Future<void> resetContext() async {
    final oldController = _activeTokenStreamController;
    _activeTokenStreamController = null;
    final oldSubscription = _tokenSubscription;
    _tokenSubscription = null;

    try {
      await _engine?.clearContext();
    } catch (_) {}
    await oldSubscription?.cancel();
    if (oldController != null && !oldController.isClosed) {
      await oldController.close();
    }
  }

  Future<bool> initContext(String modelPath) async {
    try {
      final file = File(modelPath);
      if (!file.existsSync()) {
        _isContextInitialized = false;
        return false;
      }

      if (_engine != null) {
        _engine?.cancelGeneration();
        await _engine!.dispose();
        _engine = null;
      }

      _engine = await LlamaEngine.load(
        LlamaModel(ModelSource.path(modelPath)),
        params: const ModelParams(
          contextSize: 2048,
          device: ComputeDevice.auto,
          gpuLayers: 0,
          numberOfThreads: 4,
        ),
      );

      _activeModelPath = modelPath;
      _isContextInitialized = true;
      return true;
    } catch (_) {
      _isContextInitialized = false;
      return false;
    }
  }

  bool isHarmfulQuery(String query) {
    final lower = query.toLowerCase();
    return TriageInterceptor.shouldIntercept(query) ||
        lower.contains('lethal toxicity') ||
        lower.contains('kill myself') ||
        lower.contains('how to suicide') ||
        lower.contains('suicide method') ||
        lower.contains('lethal dose') ||
        lower.contains('overdose') ||
        lower.contains('bottle of tablets') ||
        lower.contains('all at once') ||
        lower.contains('end my life') ||
        lower.contains('die painfully') ||
        lower.contains('make meth') ||
        lower.contains('cook meth') ||
        lower.contains('cut open abscess at home') ||
        lower.contains('home surgery') ||
        lower.contains('fentanyl') ||
        lower.contains('morphine without prescription') ||
        lower.contains('xanax without prescription');
  }

  bool isAcuteCardiacEmergency(String query) {
    final lower = query.toLowerCase();
    final hasCardiacKeywords = lower.contains('chest pain') ||
        lower.contains('crushing chest') ||
        lower.contains('radiating to arm') ||
        lower.contains('radiating to left arm') ||
        lower.contains('radiating to jaw') ||
        lower.contains('heart attack') ||
        lower.contains('angina');

    final hasHeartburnTerms = lower.contains('acidity') ||
        lower.contains('reflux') ||
        lower.contains('heartburn');

    return hasCardiacKeywords && !hasHeartburnTerms;
  }

  bool isEmergencyRedFlag(String query) {
    final lower = query.toLowerCase();
    return isAcuteCardiacEmergency(query) ||
        lower.contains('face droop') ||
        lower.contains('arm weakness') ||
        lower.contains('slurred speech') ||
        lower.contains('anaphylaxis') ||
        lower.contains('difficulty breathing') ||
        lower.contains('cannot breathe') ||
        lower.contains('choking') ||
        lower.contains('severe allergic reaction') ||
        lower.contains('lips swelling') ||
        lower.contains('throat closing') ||
        lower.contains('massive bleeding') ||
        lower.contains('coughing blood') ||
        lower.contains('vomiting blood') ||
        lower.contains('unconscious') ||
        lower.contains('fainted') ||
        lower.contains('seizure') ||
        lower.contains('convulsions') ||
        lower.contains('stroke');
  }

  double? extractPediatricWeightKg(String query) {
    final lower = query.toLowerCase();
    final kgPattern = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:kg|kgs|kilo|kilos)\b',
      caseSensitive: false,
    );
    final kgMatch = kgPattern.firstMatch(lower);
    if (kgMatch != null) {
      final val = double.tryParse(kgMatch.group(1) ?? '');
      if (val != null && val > 0 && val <= 80) return val;
    }

    final contextPattern = RegExp(
      r'(?:child|baby|infant|pediatric|weight)\D{0,15}(\d+(?:\.\d+)?)\b',
      caseSensitive: false,
    );
    final contextMatch = contextPattern.firstMatch(lower);
    if (contextMatch != null) {
      final val = double.tryParse(contextMatch.group(1) ?? '');
      if (val != null && val > 0 && val <= 80) return val;
    }

    return null;
  }

  bool isDengueFever(String query) {
    final lower = query.toLowerCase();
    return lower.contains('dengue');
  }

  bool isRenalImpairment(String query) {
    final lower = query.toLowerCase();
    return lower.contains('ckd') ||
        lower.contains('chronic kidney disease') ||
        lower.contains('renal impairment') ||
        lower.contains('kidney disease') ||
        lower.contains('kidney failure') ||
        lower.contains('egfr') ||
        lower.contains('creatinine');
  }

  bool isPediatricFeverQuery(String query) {
    final lower = query.toLowerCase();
    final hasWeight = extractPediatricWeightKg(query) != null;
    final hasChild = lower.contains('child') ||
        lower.contains('baby') ||
        lower.contains('infant') ||
        lower.contains('toddler');
    final hasFever = lower.contains('fever');

    return (hasChild || hasWeight) && hasFever;
  }

  Map<String, double>? calculatePediatricDose(double weightKg) {
    if (weightKg <= 0 || weightKg > 80) return null;
    final minMg = weightKg * 10.0;
    final maxMg = weightKg * 15.0;
    final minMl120 = (minMg / 120.0) * 5.0;
    final maxMl120 = (maxMg / 120.0) * 5.0;
    final minMl250 = (minMg / 250.0) * 5.0;
    final maxMl250 = (maxMg / 250.0) * 5.0;
    final maxDailyMg = weightKg * 60.0;

    return {
      'weightKg': weightKg,
      'minMg': minMg,
      'maxMg': maxMg,
      'minMl120': minMl120,
      'maxMl120': maxMl120,
      'minMl250': minMl250,
      'maxMl250': maxMl250,
      'maxDailyMg': maxDailyMg,
    };
  }

  bool isMedicationRelevantToPrompt(MedicineEntity med, String query) {
    final lowerQ = query.toLowerCase();
    final lowerGen = med.genericName.toLowerCase();
    final lowerInd = med.indications.toLowerCase();

    final isDiabetesDrug = lowerGen.contains('metformin') ||
        lowerInd.contains('diabetes') ||
        lowerInd.contains('type 2 diabetes');
    if (isDiabetesDrug) {
      final hasDiabetesIntent = lowerQ.contains('diabetes') ||
          lowerQ.contains('sugar') ||
          lowerQ.contains('glucose') ||
          lowerQ.contains('metformin');
      if (!hasDiabetesIntent) {
        return false;
      }
    }

    final hasCongestionCold = lowerQ.contains('congestion') ||
        lowerQ.contains('runny nose') ||
        lowerQ.contains('stuffy nose');
    if (hasCongestionCold) {
      final isRelevantRespiratory = lowerInd.contains('rhinitis') ||
          lowerInd.contains('allergy') ||
          lowerInd.contains('cold') ||
          lowerInd.contains('nasal') ||
          lowerInd.contains('congestion') ||
          lowerGen.contains('cetirizine') ||
          lowerGen.contains('paracetamol');
      if (!isRelevantRespiratory) {
        return false;
      }
    }

    final hasHypertension = lowerQ.contains('hypertension') ||
        lowerQ.contains('high blood pressure') ||
        lowerQ.contains('bp >') ||
        lowerQ.contains('140/90');
    if (hasHypertension && isDiabetesDrug) {
      return false;
    }

    final hasGastricBurning = RegExp(
      r'(epigastric burning|sour stomach|heartburn|stomach burning|acid burning|gastritis|stomach burn|acid reflux|gerd|nsaid)',
      caseSensitive: false,
    ).hasMatch(lowerQ);

    final hasWateryDiarrhea = RegExp(
      r'(watery diarrhea|watery diarrhoea|acute watery diarrhea|acute watery diarrhoea|acute diarrhea|acute diarrhoea|severe diarrhea|severe diarrhoea|watery stool|watery stools|loose watery|watery motions|loose motions|acute watery motions|motions|frequent motions|loose stool|loose stools|diarrhea|diarrhoea)',
      caseSensitive: false,
    ).hasMatch(lowerQ);

    if (hasGastricBurning && !hasWateryDiarrhea) {
      if (lowerGen.contains('oral rehydration') || lowerGen.contains('ors')) {
        return false;
      }
    }

    if (lowerGen.contains('oral rehydration') || lowerGen.contains('ors')) {
      if (hasWateryDiarrhea ||
          lowerQ.contains('motion') ||
          lowerQ.contains('stool') ||
          lowerQ.contains('vomit') ||
          lowerQ.contains('dehydrat')) {
        return true;
      }
    }

    final isCardioOrLipid = lowerGen.contains('amlodipine') ||
        lowerGen.contains('lisinopril') ||
        lowerGen.contains('atorvastatin') ||
        lowerInd.contains('hypertension') ||
        lowerInd.contains('hypercholesterolemia') ||
        lowerInd.contains('dyslipidemia');
    if (isCardioOrLipid) {
      final hasCardioIntent = lowerQ.contains('hypertension') ||
          lowerQ.contains('blood pressure') ||
          lowerQ.contains('high bp') ||
          lowerQ.contains('cholesterol') ||
          lowerQ.contains('lipid') ||
          lowerQ.contains('heart') ||
          lowerQ.contains('amlodipine') ||
          lowerQ.contains('lisinopril') ||
          lowerQ.contains('atorvastatin');
      if (!hasCardioIntent) {
        return false;
      }
    }

    final isAntibiotic = lowerGen.contains('amoxicillin') ||
        lowerGen.contains('azithromycin') ||
        lowerInd.contains('antibacterial') ||
        lowerInd.contains('antibiotic');
    if (isAntibiotic) {
      final hasBacterialIntent = lowerQ.contains('infection') ||
          lowerQ.contains('bacterial') ||
          lowerQ.contains('strep') ||
          lowerQ.contains('bronchitis') ||
          lowerQ.contains('pneumonia') ||
          lowerQ.contains('amoxicillin') ||
          lowerQ.contains('azithromycin');
      if (!hasBacterialIntent) {
        return false;
      }
    }

    final isGiDrug = lowerGen.contains('famotidine') ||
        lowerGen.contains('omeprazole') ||
        lowerGen.contains('antacid') ||
        lowerInd.contains('gerd') ||
        lowerInd.contains('peptic ulcer') ||
        lowerInd.contains('gastric');
    if (isGiDrug) {
      final hasGastricIntent = RegExp(
        r'(gastric|stomach|epigastric|heartburn|sour stomach|acid|acidity|ulcer|gerd|reflux)',
        caseSensitive: false,
      ).hasMatch(lowerQ);
      if (!hasGastricIntent) {
        return false;
      }
    }

    final isNsaid = lowerGen.contains('ibuprofen') ||
        lowerGen.contains('diclofenac') ||
        lowerGen.contains('naproxen') ||
        lowerGen.contains('aspirin') ||
        lowerInd.contains('nsaid');
    if (isNsaid) {
      final hasStomachPainOrUlcer = RegExp(
        r'(stomach pain|severe stomach|abdominal pain|gastric|gastritis|ulcer|heartburn|acid|epigastric)',
        caseSensitive: false,
      ).hasMatch(lowerQ);
      if (hasStomachPainOrUlcer) {
        return false;
      }
    }

    return true;
  }

  String buildClinicalPrompt({
    required String query,
    String? context,
  }) {
    final cleanQuery = query.trim();
    final promptString = '''<|im_start|>system
You are Tabib AI. Evaluate the patient's reported symptoms with extreme clinical brevity.
ABSOLUTE OPERATING RULES:
1. Provide strictly ONE short paragraph under "### Clinical Impression" (2 to 3 sentences maximum).
2. State ONLY the most likely diagnosis and non-pharmacological care (hydration, rest).
3. FORBIDDEN CONTENT:
   - NEVER invent or write "Physical Exam Findings", "Vital Signs", "Blood Pressure", "Heart Rate", "Labs", or "CBC".
   - NEVER invent objective examination details (e.g., ear exam, lung auscultation, throat examination).
   - NEVER output markdown image syntax (![]()), URLs, or tables.
4. Stop generating immediately after completing the brief clinical impression.
<|im_end|>
<|im_start|>user
Symptoms: $cleanQuery
<|im_end|>
<|im_start|>assistant
### Clinical Impression
''';

    final rawBytes = utf8.encode(promptString);
    final sanitizedPrompt = utf8.decode(rawBytes);
    return sanitizedPrompt;
  }

  String buildChatMLPrompt({
    required String userQuery,
    List<MedicineEntity> records = const [],
  }) {
    return buildClinicalPrompt(
      query: userQuery,
      context: records.isNotEmpty ? records.toContextString() : null,
    );
  }

  static String assembleClinicalResponse({
    required String llmText,
    List<MedicineEntity>? dbMedicine,
    String? userQuery,
  }) {
    var clean = OutputSanitizer.sanitize(llmText, queryContext: userQuery);
    clean = MedicalInferenceService.instance.injectVerifiedMedications(
      clinicalLlmOutput: clean,
      records: dbMedicine ?? const [],
      userQuery: userQuery,
    );
    return MedicineLocalDb.validateAndSanitizeDosages(clean);
  }

  String injectVerifiedMedications({
    required String clinicalLlmOutput,
    required List<MedicineEntity> records,
    String? userQuery,
  }) {
    if (userQuery != null && TriageInterceptor.isSurgicalEmergencyOrContraindicated(userQuery)) {
      return OutputSanitizer.sanitize(clinicalLlmOutput, queryContext: userQuery);
    }

    if (userQuery != null && userQuery.isNotEmpty) {
      final pedResult = PediatricMathHelper.calculateFromQuery(userQuery);
      if (pedResult != null) {
        final pedBlock = '\n\n${pedResult.toDeterministicPediatricMarkdown()}';

        var cleanOutput = clinicalLlmOutput
            .replaceAll(
              RegExp(r'\b(?:500\s*mg|1000\s*mg|tablets?)\b', caseSensitive: false),
              '',
            )
            .trim();

        final medIdx = cleanOutput.indexOf(RegExp(
            r'###\s*Recommended Medication & Verified Dosage|###\s*💊 Verified Medication & Dosage|RECOMMENDED_MEDICATION:',
            caseSensitive: false));
        if (medIdx != -1) {
          final nextIdx = cleanOutput.indexOf(RegExp(
              r'###\s*Non-Drug Supportive Care|###\s*Supportive Care|###\s*Lifestyle & Supportive Protocol|###\s*Lifestyle & Dietary Guidance|2\.\s*LIFESTYLE & SUPPORTIVE PROTOCOL|LIFESTYLE & SUPPORTIVE PROTOCOL|SUPPORTIVE CARE & PRECAUTIONS|PRECAUTIONS:',
              caseSensitive: false), medIdx);
          if (nextIdx != -1) {
            final before = cleanOutput.substring(0, medIdx).trimRight();
            final after = cleanOutput.substring(nextIdx).trimLeft();
            return '$before$pedBlock\n\n$after';
          } else {
            return '${cleanOutput.substring(0, medIdx).trimRight()}$pedBlock';
          }
        }

        final lifestyleIndex = cleanOutput.indexOf(RegExp(
            r'###\s*Non-Drug Supportive Care|###\s*Supportive Care|###\s*Lifestyle & Supportive Protocol|###\s*Lifestyle & Dietary Guidance|2\.\s*LIFESTYLE & SUPPORTIVE PROTOCOL|LIFESTYLE & SUPPORTIVE PROTOCOL|SUPPORTIVE CARE & PRECAUTIONS|PRECAUTIONS:',
            caseSensitive: false));
        if (lifestyleIndex != -1) {
          final before = cleanOutput.substring(0, lifestyleIndex).trimRight();
          final after = cleanOutput.substring(lifestyleIndex).trimLeft();
          return '$before$pedBlock\n\n$after';
        } else {
          return '${cleanOutput.trimRight()}$pedBlock';
        }
      }
    }

    var cleanOutput = clinicalLlmOutput;
    final fakeMedPattern = RegExp(
      r'###\s*(?:Recommended Medication(?: & Verified Dosage)?|Medications?|Prescribed Medication|Verified Medication(?: & Dosage)?)[^\n]*\n(?:[^\n#]+\n?)*',
      caseSensitive: false,
    );
    cleanOutput = cleanOutput.replaceAll(fakeMedPattern, '').trim();

    if (records.isEmpty) return cleanOutput;

    final relevant = userQuery != null && userQuery.isNotEmpty
        ? records.where((r) => isMedicationRelevantToPrompt(r, userQuery)).toList()
        : records;

    if (relevant.isEmpty) return cleanOutput;

    final buffer = StringBuffer();
    buffer.writeln('\n\n### 💊 Verified Medication & Dosage');
    for (final med in relevant.take(2)) {
      buffer.writeln('• Generic Name: ${med.genericName} (${med.brandNames})');
      buffer.writeln('• Therapeutic Class: ${med.therapeuticClass}');
      buffer.writeln('• Verified Adult Dose: ${med.adultDosage}');
      buffer.writeln('• Ceiling Limit: ${med.ceilingLimit}');
      buffer.writeln('• Absolute Contraindications: ${med.contraindications}');
    }

    final medBlock = buffer.toString().trimRight();

    final lifestyleIndex = cleanOutput.indexOf(RegExp(
        r'###\s*Non-Drug Supportive Care|###\s*Supportive Care|###\s*Lifestyle & Supportive Protocol|###\s*Lifestyle & Dietary Guidance|2\.\s*LIFESTYLE & SUPPORTIVE PROTOCOL|LIFESTYLE & SUPPORTIVE PROTOCOL|SUPPORTIVE CARE & PRECAUTIONS|PRECAUTIONS:',
        caseSensitive: false));
    String result;
    if (lifestyleIndex != -1) {
      final before = cleanOutput.substring(0, lifestyleIndex).trimRight();
      final after = cleanOutput.substring(lifestyleIndex).trimLeft();
      result = '$before$medBlock\n\n$after';
    } else {
      result = '${cleanOutput.trimRight()}$medBlock';
    }

    return MedicineLocalDb.validateAndSanitizeDosages(result);
  }

  Stream<String> infer({
    required String prompt,
    List<MedicineEntity> records = const [],
    String? userQuery,
  }) {
    final controller = StreamController<String>();
    _activeTokenStreamController = controller;

    if (userQuery != null) {
      final interceptedWarning = TriageInterceptor.intercept(userQuery);
      if (interceptedWarning != null) {
        _streamInterceptedWarning(interceptedWarning, controller);
        return controller.stream;
      }
    }

    _startInference(prompt, controller, originalQuery: userQuery);
    return controller.stream;
  }

  Future<void> _startInference(
    String prompt,
    StreamController<String> controller, {
    String? originalQuery,
  }) async {
    try {
      await _engine?.clearContext();
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;

      await _executeLlamaDartInference(prompt, controller, originalQuery: originalQuery);
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
        await controller.close();
      }
    }
  }

  Stream<String> generateStreamingResponse({
    required String userQuery,
    required List<MedicineEntity> retrievedRecords,
  }) {
    final normalized = InputNormalizer.normalize(userQuery);
    final sanitizedEnglishQuery = normalized.sanitizedPrompt;

    final prompt = buildClinicalPrompt(
      query: sanitizedEnglishQuery,
      context: retrievedRecords.toContextString(),
    );

    return infer(
      prompt: prompt,
      records: retrievedRecords,
      userQuery: userQuery,
    );
  }

  Future<void> _streamInterceptedWarning(
    String message,
    StreamController<String> controller,
  ) async {
    final words = message.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (controller.isClosed) break;
      controller.add(i == words.length - 1 ? words[i] : '${words[i]} ');
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
    if (!controller.isClosed) {
      await controller.close();
    }
  }

  static String chopRepetitiveTailClauses(String text, {int minLength = 15}) {
    if (text.length < minLength * 2) return text;

    final regex = RegExp(
      r'(.{15,500}?)(?:[\s.,;!?\-]|\n)+\1',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);
    if (match != null) {
      final firstInstance = match.group(1)!;
      var cutoff = match.start + firstInstance.length;
      if (cutoff < text.length &&
          (text[cutoff] == '.' ||
              text[cutoff] == '!' ||
              text[cutoff] == '?')) {
        cutoff++;
      }
      return text.substring(0, cutoff).trim();
    }

    return text;
  }

  String sanitizeClinicalOutput(String text, {String? userQuery}) {
    final tailChopped = chopRepetitiveTailClauses(text);
    return OutputSanitizer.sanitize(tailChopped, queryContext: userQuery);
  }

  static const List<String> stopTokens = [
    '<|im_end|>',
    '<|endoftext|>',
    '<|im_start|>',
    'User:',
    'Patient:',
  ];

  Future<void> _executeLlamaDartInference(
    String prompt,
    StreamController<String> controller, {
    String? originalQuery,
  }) async {
    try {
      if (_engine == null || !_isContextInitialized) {
        try {
          final modelPath = await ModelDownloader().getModelFilePath();
          if (File(modelPath).existsSync()) {
            final initSuccess = await initContext(modelPath);
            if (!initSuccess) {
              throw Exception('Model initialization failed for $modelPath.');
            }
          } else {
            await _synthesizeOfflineClinicalNote(prompt, controller, originalQuery: originalQuery);
            return;
          }
        } catch (_) {
          await _synthesizeOfflineClinicalNote(prompt, controller, originalQuery: originalQuery);
          return;
        }
      }

      try {
        _engine?.cancelGeneration();
      } catch (_) {}

      final rawBytes = utf8.encode(prompt);
      final sanitizedPrompt = utf8.decode(rawBytes);

      final params = const GenerationParams(
        temp: 0.0,
        topP: 0.85,
        penalty: 1.4,
        presencePenalty: 0.4,
        reusePromptPrefix: false,
        maxTokens: 120,
        stopSequences: stopTokens,
      );

      final tokenStream = _engine!.generate(sanitizedPrompt, params: params);

      String trailingWindow = '';
      bool isFirstChunk = true;

      if (!controller.isClosed) {
        controller.add('### Clinical Impression\n');
      }

      _tokenSubscription = tokenStream.listen(
        (token) async {
          final tokenBytes = utf8.encode(token);
          final rawChunk = utf8.decode(tokenBytes, allowMalformed: true);

          if (rawChunk.isEmpty) return;

          if (rawChunk == '<|im_end|>' ||
              rawChunk == '<|endoftext|>' ||
              rawChunk.startsWith('<|im_start|>') ||
              rawChunk.startsWith('User:') ||
              rawChunk.startsWith('Patient:')) {
            await stopGeneration();
            if (!controller.isClosed) {
              await controller.close();
            }
            return;
          }

          trailingWindow += rawChunk;

          for (final stopSeq in stopTokens) {
            final idx = trailingWindow.indexOf(stopSeq);
            if (idx != -1) {
              final remaining = trailingWindow.substring(0, idx);
              final cleanRemaining = OutputSanitizer.sanitizeToken(remaining);
              if (cleanRemaining.isNotEmpty && !controller.isClosed) {
                controller.add(cleanRemaining);
              }
              await stopGeneration();
              if (!controller.isClosed) {
                await controller.close();
              }
              return;
            }
          }

          var cleanChunk = OutputSanitizer.sanitizeToken(rawChunk);
          if (isFirstChunk) {
            isFirstChunk = false;
            cleanChunk = cleanChunk.replaceFirst(
              RegExp(r'^\s*###\s*Clinical\s*Impression\s*\n?', caseSensitive: false),
              '',
            );
            cleanChunk = cleanChunk.replaceFirst(
              RegExp(r'^\s*CLINICAL\s*IMPRESSION:\s*\n?', caseSensitive: false),
              '',
            );
            cleanChunk = cleanChunk.replaceFirst(
              RegExp(r'^\s*1\.\s*CLINICAL\s*IMPRESSION:\s*\n?', caseSensitive: false),
              '',
            );
            cleanChunk = cleanChunk.replaceFirst(
              RegExp(r'^\s*###\s*Clinical\s*Assessment\s*\n?', caseSensitive: false),
              '',
            );
            cleanChunk = cleanChunk.replaceFirst(
              RegExp(r'^\s*ASSESSMENT:\s*', caseSensitive: false),
              '',
            );
          }
          for (final stopSeq in stopTokens) {
            cleanChunk = cleanChunk.replaceAll(stopSeq, '');
          }

          if (cleanChunk.isNotEmpty && !controller.isClosed) {
            controller.add(cleanChunk);
          }

          if (trailingWindow.length > 160) {
            trailingWindow =
                trailingWindow.substring(trailingWindow.length - 80);
          }
        },
        onError: (err) {
          if (!controller.isClosed) {
            controller.addError(err);
            controller.close();
          }
        },
        onDone: () {
          if (!controller.isClosed) {
            controller.close();
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
        await controller.close();
      }
    }
  }

  Future<void> _synthesizeOfflineClinicalNote(
    String prompt,
    StreamController<String> controller, {
    String? originalQuery,
  }) async {
    final query = (originalQuery ?? prompt).toLowerCase();
    String impression;
    String lifestyle;
    String redFlags;

    if (query.contains('diarrhea') ||
        query.contains('diarrhoea') ||
        query.contains('loose motion') ||
        query.contains('watery motion') ||
        query.contains('watery') ||
        query.contains('loose stool') ||
        query.contains('watery stool')) {
      impression =
          'Clinical presentation indicates acute uncomplicated gastroenteritis or acute watery diarrhea with significant fluid loss.';
      lifestyle =
          '• Maintain high oral fluid intake with clean water, clear broths, and frequent sips.\n• Consume small, bland meals (rice, bananas, toast) while avoiding dairy and high-fat items.';
      redFlags =
          '• Severe dehydration signs (sunken eyes, confusion, lack of urination >8 hours).\n• High persistent fever, intractable vomiting, or blood in stool (Dial 1122 immediately).';
    } else if (query.contains('stomach') ||
        query.contains('gastric') ||
        query.contains('acid') ||
        query.contains('heartburn') ||
        query.contains('gerd')) {
      impression =
          'Clinical presentation suggests acute functional dyspepsia or gastroesophageal acid reflux without acute peritoneal signs.';
      lifestyle =
          '• Avoid lying down for at least 2 to 3 hours postprandially to prevent acid regurgitation.\n• Elevate the head of the bed by 6 inches and limit spicy foods, citrus, and caffeine.';
      redFlags =
          '• Vomiting blood (hematemesis) or dark tarry stools (melena).\n• Severe crushing chest pain radiating to left arm or jaw (Dial 1122 immediately).';
    } else if (query.contains('headache') ||
        query.contains('migraine')) {
      impression =
          'Primary clinical differential indicates acute tension-type cephalalgia or cervicogenic muscle contraction headache.';
      lifestyle =
          '• Rest in a quiet, dark, well-ventilated room with minimal screen exposure.\n• Apply a warm or cool compress across the forehead and practice cervical relaxation.';
      redFlags =
          '• Sudden explosive "thunderclap" headache or stiff neck with high fever.\n• Focal weakness, vision changes, or confusion (Dial 1122 immediately).';
    } else if (query.contains('fever') ||
        query.contains('temperature')) {
      impression =
          'Clinical presentation is consistent with an acute uncomplicated febrile response, likely viral in etiology.';
      lifestyle =
          '• Prioritize complete bed rest and wear light, breathable clothing to assist natural heat dissipation.\n• Increase fluid intake with clean water and clear broths, and apply tepid sponging.';
      redFlags =
          '• Temperature exceeding 39.5°C (103°F) unresponsive to cooling measures.\n• Stiff neck, petechial rash, or respiratory distress (Dial 1122 immediately).';
    } else if (query.contains('cough') ||
        query.contains('cold') ||
        query.contains('congestion') ||
        query.contains('sore throat')) {
      impression =
          'Presentation corresponds to acute viral upper respiratory tract infection with localized mucosal inflammation.';
      lifestyle =
          '• Steam inhalation twice daily and warm saline gargles to relieve pharyngeal discomfort.\n• Maintain adequate oral hydration with warm broths, honey-lemon tea, and clean fluids.';
      redFlags =
          '• Stridor, difficulty breathing, or inability to swallow saliva.\n• Coughing up frank blood or persistent high fever (Dial 1122 immediately).';
    } else {
      impression =
          'Objective clinical assessment reflects acute mild-to-moderate symptomatic distress without acute overt red-flag triggers at initial evaluation.';
      lifestyle =
          '• Ensure structured physical rest and maintain adequate balanced hydration.\n• Avoid polypharmacy and monitor symptoms closely over the subsequent 24 to 48 hours.';
      redFlags =
          '• Severe unremitting pain, altered mental status, or shortness of breath.\n• Any rapid deterioration in vital stability (Dial 1122 immediately).';
    }

    final note = '''### Clinical Impression
$impression

### Non-Drug Supportive Care
$lifestyle

### Emergency Red Flags
$redFlags''';

    final words = note.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (controller.isClosed) break;
      controller.add(i == words.length - 1 ? words[i] : '${words[i]} ');
      await Future<void>.delayed(const Duration(milliseconds: 14));
    }
    if (!controller.isClosed) {
      await controller.close();
    }
  }

  Future<void> stopGeneration() async {
    try {
      _engine?.cancelGeneration();
    } catch (_) {}
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    if (_activeTokenStreamController != null &&
        !_activeTokenStreamController!.isClosed) {
      await _activeTokenStreamController!.close();
    }
  }

  Future<void> releaseContext() async {
    try {
      await stopGeneration();
      await _engine?.dispose();
      _engine = null;
      _isContextInitialized = false;
      _activeModelPath = null;
    } catch (_) {}
  }

  bool isUrgentEmergency(String query) => isEmergencyRedFlag(query);

  void dispose() {
    stopGeneration();
    releaseContext();
  }
}
