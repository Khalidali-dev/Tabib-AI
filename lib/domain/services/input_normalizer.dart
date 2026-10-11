
class NormalizedInput {
  final String originalQuery;
  final String sanitizedPrompt;
  final String searchQuery;
  final bool wasTranslated;

  const NormalizedInput({
    required this.originalQuery,
    required this.sanitizedPrompt,
    required this.searchQuery,
    this.wasTranslated = false,
  });
}

class InputNormalizer {
  InputNormalizer._();

  static String cleanInput(String text) {
    var s = text.trim();
    s = s.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
    s = s.replaceAll(RegExp(r'[\u202A-\u202E\u2066-\u2069]'), '');
    s = s.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    s = s.replaceAll(RegExp(r'[^\S\r\n]+'), ' ');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }

  static NormalizedInput normalize(String text) {
    final cleaned = cleanInput(text);
    return NormalizedInput(
      originalQuery: text,
      sanitizedPrompt: cleaned,
      searchQuery: cleaned,
      wasTranslated: false,
    );
  }
}
