import '../../data/datasources/medicine_local_db.dart';

class OutputSanitizer {
  OutputSanitizer._();

  static String _enforceIdentity(String text) {
    var s = text;
    s = s.replaceAll(
      RegExp(r'\bwelcome to Chat\s*Doctor\b', caseSensitive: false),
      'Welcome to Tabib AI',
    );
    s = s.replaceAll(
      RegExp(r'\bChat\s*Doctor\b', caseSensitive: false),
      'Tabib AI',
    );
    s = s.replaceAll(
      RegExp(r'\bManga\b', caseSensitive: false),
      'Tabib',
    );
    s = s.replaceAll(
      RegExp(r'\bI am ChatDoctor\b', caseSensitive: false),
      'I am Tabib AI',
    );
    return s;
  }

  static const List<_ContradictionPair> _contradictions = [
    _ContradictionPair(
      unsafePattern: r"(?:don'?t|do not|avoid)\s+taking\s+(?:any\s+)?medicine",
      safePattern: r"(?:you can|you may|take|use)\s+(?:the\s+)?medicine",
      unsafeReplacement: '',
    ),
    _ContradictionPair(
      unsafePattern: r"(?:don'?t|do not)\s+take\s+paracetamol",
      safePattern: r"(?:take|use|recommended)\s+(?:paracetamol|panadol)",
      unsafeReplacement: '',
    ),
    _ContradictionPair(
      unsafePattern: r"(?:don'?t|do not)\s+take\s+ibuprofen",
      safePattern: r"(?:take|use|recommended)\s+(?:ibuprofen|brufen)",
      unsafeReplacement: '',
    ),
    _ContradictionPair(
      unsafePattern: r"(?:don'?t|do not)\s+take\s+(?:any\s+)?painkillers?",
      safePattern: r"(?:take|use)\s+(?:painkillers?|analgesics?|paracetamol)",
      unsafeReplacement: '',
    ),
    _ContradictionPair(
      unsafePattern: r"no\s+(?:need\s+for\s+)?medication\s+is\s+required",
      safePattern: r"(?:take|use|recommended)\s+(?:paracetamol|ibuprofen|medicine)",
      unsafeReplacement: '',
    ),
  ];

  static String _eliminateContradictions(String text) {
    var s = text;
    for (final pair in _contradictions) {
      final hasSafe = RegExp(pair.safePattern, caseSensitive: false).hasMatch(s);
      final hasUnsafe = RegExp(pair.unsafePattern, caseSensitive: false).hasMatch(s);
      if (hasSafe && hasUnsafe) {
        s = s.replaceAll(
          RegExp(pair.unsafePattern, caseSensitive: false),
          pair.unsafeReplacement,
        );
      }
    }
    return s;
  }

  static String _collapseRepetitions(String text) {
    final lines = text.split('\n');
    final resultLines = <String>[];
    final seenGlobalSentences = <String>{};

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty) {
        resultLines.add(line);
        continue;
      }

      if (trimmedLine.startsWith('#') || trimmedLine.startsWith('**')) {
        resultLines.add(line);
        continue;
      }

      final normLine = trimmedLine
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (normLine.length > 12 && seenGlobalSentences.contains(normLine)) {
        continue;
      }

      final sentenceSplitter = RegExp(r'(?<=[.!?])\s+');
      final lineSentences = line.split(sentenceSplitter);
      final keptSentences = <String>[];

      for (final s in lineSentences) {
        final cleanS = s.trim();
        if (cleanS.isEmpty) continue;
        final normS = cleanS
            .toLowerCase()
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        if (normS.length > 14 && seenGlobalSentences.contains(normS)) {
          continue;
        }
        if (normS.length > 14) {
          seenGlobalSentences.add(normS);
        }
        keptSentences.add(s);
      }

      if (keptSentences.isNotEmpty) {
        if (normLine.length > 12) {
          seenGlobalSentences.add(normLine);
        }
        resultLines.add(keptSentences.join(' '));
      }
    }

    return resultLines.join('\n').trim();
  }

  static final List<RegExp> _fillerPatterns = [
    RegExp(r'^hello[!.]\s*$', caseSensitive: false, multiLine: true),
    RegExp(r'^hi[!.]\s*$', caseSensitive: false, multiLine: true),
    RegExp(r'^how can I (?:help|assist) you today\??\s*$', caseSensitive: false, multiLine: true),
    RegExp("^I(?:'m| am) here to help[.!]?\\s*\$", caseSensitive: false, multiLine: true),
    RegExp("^sure[!,.]?\\s*(?:I'?d? be happy to help\\.?\\s*)?", caseSensitive: false, multiLine: true),
    RegExp(r'^of course[!,.]?\s*$', caseSensitive: false, multiLine: true),
    RegExp(r'^great question[!,.]?\s*$', caseSensitive: false, multiLine: true),
    RegExp(r'^certainly[!,.]?\s*$', caseSensitive: false, multiLine: true),
    RegExp("^I'?m? sorry to hear that[.!]?\\s*\$", caseSensitive: false, multiLine: true),
    RegExp(r'<\|im_(?:end|start)\|>', caseSensitive: false),
    RegExp(r'<\|endoftext\|>', caseSensitive: false),
  ];

  static String _stripFiller(String text) {
    var s = text;
    for (final re in _fillerPatterns) {
      s = s.replaceAll(re, '');
    }
    return s.trim();
  }

  static String preventDiagnosticInversion(String text, {String? queryContext}) {
    var s = text;
    final isHypertensive = (queryContext != null &&
            (RegExp(r'(?:1[4-9]\d|2\d\d)\s*/\s*\d{2,3}').hasMatch(queryContext) ||
                RegExp(r'\d{2,3}\s*/\s*(?:9[1-9]|1\d\d)').hasMatch(queryContext) ||
                queryContext.toLowerCase().contains('hypertension') ||
                queryContext.toLowerCase().contains('high bp') ||
                queryContext.contains('155/95'))) ||
        RegExp(r'(?:1[4-9]\d|2\d\d)\s*/\s*\d{2,3}').hasMatch(s);

    if (isHypertensive) {
      s = s.replaceAll(
        RegExp(r'\bhypotension\s+due\s+to\s+medication\b', caseSensitive: false),
        'Hypertension (elevated blood pressure)',
      );
      s = s.replaceAll(
        RegExp(r'\b(?:severe\s+)?hypotension\b', caseSensitive: false),
        'Hypertension',
      );
    }
    return s;
  }

  static String _stripUrlsAndMarkdownTables(String text) {
    var s = text;
    s = s.replaceAll(
      RegExp(r'(?:https?:\/\/|www\.)[^\s]+', caseSensitive: false),
      '',
    );
    s = s.replaceAll(
      RegExp(r'\b[a-zA-Z0-9_\-]+\.(?:com|org|net|gov|edu|io|co|pk|ai)\/[^\s]*', caseSensitive: false),
      '',
    );
    s = s.replaceAll(RegExp(r'\[o\]\[[^\]\r\n]*\]?'), '');
    s = s.replaceAll(RegExp(r'\|\s*:?-+:?\s*\|.*'), '');
    s = s.replaceAll(RegExp(r'^\s*\|.*\|\s*$', multiLine: true), '');
    return s;
  }

  static String sanitize(String rawOutput, {String? queryContext}) {
    if (rawOutput.isEmpty) return rawOutput;
    var s = _enforceIdentity(rawOutput);
    s = _eliminateContradictions(s);
    s = preventDiagnosticInversion(s, queryContext: queryContext);
    s = _stripUrlsAndMarkdownTables(s);
    s = _collapseRepetitions(s);
    s = _stripFiller(s);
    s = s.replaceAll(
      RegExp(r'\b(?:\d+|fifteen|twenty)\s+tablets\s+(?:at\s+a\s+time|at\s+once)\b', caseSensitive: false),
      '',
    );
    s = _scrubHallucinatedDrugsAndTimings(s);
    s = _stripFictitiousObjectiveFindings(s);
    s = MedicineLocalDb.validateAndSanitizeDosages(s);
    s = cleanAsterisks(s);
    s = fixTruncatedTail(s);
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return s;
  }

  static String _scrubHallucinatedDrugsAndTimings(String text) {
    var s = text;
    final opioidPattern = RegExp(
      r'\b(?:hydromorphone|morphine|oxycodone|fentanyl|codeine|tramadol|hydrocodone|methadone|buprenorphine|oxymorphone|meperidine|demerol|dilaudid|percocet|vicodin|oxycontin)\b[^\n.,;!?]*(?:max\s*\d+\s*mg|[0-9\-]+\s*mg)?',
      caseSensitive: false,
    );
    s = s.replaceAll(opioidPattern, '');

    final dosageTimingPattern = RegExp(
      r'\b\d+(?:\.\d+)?\s*(?:mg|g|mcg|ml)?\s*[-–]\s*\d{1,2}:\d{2}\s*(?:am|pm)?\s*(?:tds|bd|tid|bid|od|qid|qds|prn)?\b',
      caseSensitive: false,
    );
    s = s.replaceAll(dosageTimingPattern, '');

    final standaloneDosingPattern = RegExp(
      r'\b\d+(?:\.\d+)?\s*(?:mg|g|mcg|ml)\s*(?:tds|bd|tid|bid|od|qid|qds|prn)\b',
      caseSensitive: false,
    );
    s = s.replaceAll(standaloneDosingPattern, '');

    final timingsPattern = RegExp(
      r'\b\d{1,2}:\d{2}\s*(?:am|pm)\s*(?:tds|bd|tid|bid|od|qid)?\b',
      caseSensitive: false,
    );
    s = s.replaceAll(timingsPattern, '');

    final rawDosePattern = RegExp(
      r'\b(?:0-2\s*mg|max\s*16\s*mg)\b',
      caseSensitive: false,
    );
    s = s.replaceAll(rawDosePattern, '');

    s = s.replaceAll(
      RegExp(r'\s*\([^)]*?\b(?:albuterol|salbutamol|paracetamol|ibuprofen|hydromorphone|morphine|inhaler|antibiotic)[^)]*?\)', caseSensitive: false),
      '',
    );
    s = s.replaceAll(
      RegExp(r'\s*\([^(]*?\b(?:albuterol|salbutamol|paracetamol|ibuprofen|hydromorphone|morphine|inhaler|antibiotic)[^)]*$', caseSensitive: false),
      '',
    );

    return s;
  }

  static String _stripFictitiousObjectiveFindings(String text) {
    var s = text;
    s = s.replaceAll(
      RegExp(
        r'(?:^|\n)\s*(?:###\s*)?(?:Objective|Physical Exam(?:ination)?|Physical Findings|Vitals?|Vital Signs|Laboratory Findings|Diagnostic Labs)\b[^\n]*\n(?:[^\n#]+\n?)*',
        caseSensitive: false,
      ),
      '',
    );
    s = s.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '');
    s = s.replaceAll(RegExp(r'!\[[^\]]*\](?:\([^\)]*)?'), '');
    return s;
  }

  static String fixTruncatedTail(String text) {
    if (text.isEmpty) return text;
    var s = text.trim();
    if (s.endsWith('(e.g., albuterol') || s.endsWith('(e.g.,') || s.endsWith('(e.g.')) {
      s = s.substring(0, s.lastIndexOf('(')).trim();
    }
    final openParen = '('.allMatches(s).length;
    final closeParen = ')'.allMatches(s).length;
    if (openParen > closeParen) {
      final lastOpen = s.lastIndexOf('(');
      if (lastOpen != -1 && s.length - lastOpen < 30) {
        s = s.substring(0, lastOpen).trim();
      }
    }
    return s;
  }

  static String cleanAsterisks(String text) {
    if (text.isEmpty) return text;
    var s = text;
    s = s.replaceAll(RegExp(r'(?<=[)\]};,.:!?])\*(?!\*)'), '');
    s = s.replaceAll(RegExp(r'(?<!\*)\*(?=[(\[{;,.:!?])'), '');
    s = s.replaceAll(RegExp(r'\*{3,}'), '**');
    s = s.replaceAll(RegExp(r'(?<!^|\n)(?<=\s)\*(?=\s)'), '');
    s = s.replaceAll(RegExp(r'(?<=\w)\*(?=[\s\n.,;!?]|$)'), '');
    s = s.replaceAll(RegExp(r'(?<=[\s\n]|^)\*(?=\w)(?![^*]*\*)'), '');

    final withoutBold = s.replaceAll('**', '');
    final singleCount = '*'.allMatches(withoutBold).length;
    if (singleCount % 2 != 0) {
      s = s.replaceAllMapped(RegExp(r'(?<!\*)\*(?!\*)'), (m) => '');
    }
    return s;
  }

  static String sanitizeToken(String token) {
    if (token.isEmpty) return token;
    var s = _enforceIdentity(token);
    s = s.replaceAll(RegExp(r'<\|im_(?:end|start)\|>'), '');
    s = s.replaceAll(RegExp(r'<\|endoftext\|>'), '');
    s = s.replaceAll(RegExp(r'\[o\]\[[^\]]*\]?'), '');
    s = s.replaceAll(RegExp(r'!\[[^\]]*\]\(?'), '');
    return s;
  }
}

class _ContradictionPair {
  final String unsafePattern;
  final String safePattern;
  final String unsafeReplacement;

  const _ContradictionPair({
    required this.unsafePattern,
    required this.safePattern,
    required this.unsafeReplacement,
  });
}

