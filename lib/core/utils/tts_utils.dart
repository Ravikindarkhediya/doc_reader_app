class TtsUtils {
  // ── Language code → human-readable name ────────────────────────────────────
  static const _langNames = {
    'af': 'Afrikaans', 'ar': 'Arabic', 'bg': 'Bulgarian', 'bn': 'Bengali',
    'bs': 'Bosnian', 'ca': 'Catalan', 'cs': 'Czech', 'cy': 'Welsh',
    'da': 'Danish', 'de': 'German', 'el': 'Greek', 'en': 'English',
    'eo': 'Esperanto', 'es': 'Spanish', 'et': 'Estonian', 'eu': 'Basque',
    'fa': 'Persian', 'fi': 'Finnish', 'fr': 'French', 'ga': 'Irish',
    'gl': 'Galician', 'gu': 'Gujarati', 'he': 'Hebrew', 'hi': 'Hindi',
    'hr': 'Croatian', 'hu': 'Hungarian', 'hy': 'Armenian', 'id': 'Indonesian',
    'is': 'Icelandic', 'it': 'Italian', 'ja': 'Japanese', 'jw': 'Javanese',
    'ka': 'Georgian', 'km': 'Khmer', 'kn': 'Kannada', 'ko': 'Korean',
    'la': 'Latin', 'lt': 'Lithuanian', 'lv': 'Latvian', 'mk': 'Macedonian',
    'ml': 'Malayalam', 'mr': 'Marathi', 'my': 'Myanmar', 'ne': 'Nepali',
    'nl': 'Dutch', 'no': 'Norwegian', 'pa': 'Punjabi', 'pl': 'Polish',
    'pt': 'Portuguese', 'ro': 'Romanian', 'ru': 'Russian', 'si': 'Sinhala',
    'sk': 'Slovak', 'sl': 'Slovenian', 'sq': 'Albanian', 'sr': 'Serbian',
    'su': 'Sundanese', 'sv': 'Swedish', 'sw': 'Swahili', 'ta': 'Tamil',
    'te': 'Telugu', 'th': 'Thai', 'tl': 'Filipino', 'tr': 'Turkish',
    'uk': 'Ukrainian', 'ur': 'Urdu', 'vi': 'Vietnamese', 'zh': 'Chinese',
    'zu': 'Zulu',
  };

  static const _regionNames = {
    'AU': 'Australia', 'BR': 'Brazil', 'CA': 'Canada', 'CN': 'China',
    'DE': 'Germany', 'ES': 'Spain', 'FR': 'France', 'GB': 'United Kingdom',
    'HK': 'Hong Kong', 'ID': 'Indonesia', 'IN': 'India', 'IT': 'Italy',
    'JP': 'Japan', 'KR': 'Korea', 'MX': 'Mexico', 'NG': 'Nigeria',
    'NZ': 'New Zealand', 'PH': 'Philippines', 'PT': 'Portugal',
    'RU': 'Russia', 'TW': 'Taiwan', 'US': 'United States', 'ZA': 'South Africa',
  };

  /// "en-US" → "English (United States)"
  static String formatLanguageName(String code) {
    try {
      final parts = code.split(RegExp(r'[-_]'));
      final lang = _langNames[parts[0].toLowerCase()] ?? parts[0].toUpperCase();
      if (parts.length < 2) return lang;
      final region = _regionNames[parts[1].toUpperCase()] ?? parts[1].toUpperCase();
      return '$lang ($region)';
    } catch (_) {
      return code;
    }
  }

  /// "com.apple.ttsbundle.Samantha-compact" → "Samantha"
  static String formatVoiceName(Map voice) {
    String name = voice['name']?.toString() ?? '';

    // Strip platform prefixes
    final prefixes = [
      'com.apple.ttsbundle.',
      'com.apple.voice.compact.', 'com.apple.voice.',
      'com.google.android.tts:',
      'com.samsung.SMT-',
    ];
    for (final prefix in prefixes) {
      if (name.startsWith(prefix)) {
        name = name.substring(prefix.length);
        break;
      }
    }

    // Strip quality suffixes
    final qSuffixes = ['-compact', '-premium', '-enhanced', '-neural'];
    String quality = '';
    for (final s in qSuffixes) {
      if (name.endsWith(s)) {
        name = name.substring(0, name.length - s.length);
        quality = s.substring(1); // drop dash
        quality = quality[0].toUpperCase() + quality.substring(1);
        break;
      }
    }

    // Split camelCase: "SamanthaNeural" → "Samantha Neural"
    name = name.replaceAllMapped(
      RegExp(r'(?<=[a-z])([A-Z])'),
          (m) => ' ${m.group(0)}',
    ).trim();

    // Remove any leftover colons/slashes
    name = name.replaceAll(RegExp(r'[:\/\\]'), ' ').trim();

    if (quality.isNotEmpty) name = '$name · $quality';
    return name.isEmpty ? 'Unknown Voice' : name;
  }

  /// Sanitize text for TTS: replace problematic chars without changing word count.
  static String sanitizeWordForTts(String w) {
    return w
        .replaceAll('&amp;', 'and')
        .replaceAll('&lt;', 'less than')
        .replaceAll('&gt;', 'greater than')
        .replaceAll('&', 'and')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }
}