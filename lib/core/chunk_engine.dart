class ChunkEngine {
  /// Clean raw extracted text from PDF/DOC — preserves paragraph structure.
  static String cleanText(String raw) {
    if (raw.trim().isEmpty) return '';

    String text = raw;

    // Remove null chars and non-printable control chars (keep \n and \t)
    text = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), ' ');

    // Normalize unicode dashes and quotes
    text = text
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"')
        .replaceAll('\u2026', '...');

    // Fix broken hyphenation (word-\nword → wordword)
    text = text.replaceAll(RegExp(r'-\s*\n\s*'), '');

    // Collapse 3+ consecutive blank lines into exactly 2 (one blank line = paragraph break)
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Remove lines that are ONLY page numbers (standalone 1-4 digit numbers)
    // Use multiline mode so ^ and $ match line boundaries
    text = text.replaceAll(RegExp(r'^\s*\d{1,4}\s*$', multiLine: true), '');

    // Remove repeated spaces within a line (but NOT newlines)
    text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ');

    // Trim leading/trailing whitespace on each line
    text = text.split('\n').map((l) => l.trimRight()).join('\n');

    text = text.trim();

    return text.isNotEmpty ? text : "No readable content";
  }

  /// Estimate read time in minutes
  static double estimateReadTime(List<String> chunks) {
    final totalWords = chunks.join(' ').split(' ').length;
    return totalWords / 200.0;
  }

  /// Get word count
  static int wordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
}
