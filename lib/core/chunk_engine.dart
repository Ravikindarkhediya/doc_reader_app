
class ChunkEngine {
  /// Clean raw extracted text from PDF/DOC
  static String cleanText(String raw) {
    if (raw.trim().isEmpty) return '';

    String text = raw;

    // Remove null characters and control chars
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

    // Fix broken hyphenation (word- \n word → word word)
    text = text.replaceAll(RegExp(r'-\s*\n\s*'), '');

    // Replace multiple newlines with single space
    text = text.replaceAll(RegExp(r'\n{2,}'), ' ');
    text = text.replaceAll('\n', ' ');

    // Remove repeated spaces
    text = text.replaceAll(RegExp(r'  +'), ' ');

    // Remove lines that are just numbers (page numbers)
    text = text.replaceAll(RegExp(r'(?<!\w)\d{1,4}(?!\w)'), '');

    // Clean trailing/leading whitespace
    text = text.trim();

    return text;
  }

  /// Split text into sentence chunks for TTS
  static List<String> splitIntoChunks(String text, {ChunkMode mode = ChunkMode.sentence}) {
    if (text.trim().isEmpty) return [];

    final cleaned = cleanText(text);

    switch (mode) {
      case ChunkMode.sentence:
        return _splitBySentence(cleaned);
      case ChunkMode.word:
        return _splitByWord(cleaned);
      case ChunkMode.paragraph:
        return _splitByParagraph(cleaned);
    }
  }

  static List<String> _splitBySentence(String text) {
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));

    List<String> chunks = [];
    String buffer = '';

    for (var s in sentences) {
      if ((buffer + s).length < 200) {
        buffer += ' $s';
      } else {
        chunks.add(buffer.trim());
        buffer = s;
      }
    }

    if (buffer.isNotEmpty) {
      chunks.add(buffer.trim());
    }

    return chunks;
  }

  static List<String> _splitByWord(String text) {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  static List<String> _splitByParagraph(String text) {
    return text
        .split(RegExp(r'\.\s{2,}|\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.length > 10)
        .toList();
  }

  /// Estimate read time in minutes
  static double estimateReadTime(List<String> chunks) {
    final totalWords = chunks.join(' ').split(' ').length;
    return totalWords / 200.0; // avg 200 wpm
  }

  /// Get word count
  static int wordCount(String text) {
    return text.trim().split(RegExp(r'\s+')).length;
  }
}

enum ChunkMode { sentence, word, paragraph }
