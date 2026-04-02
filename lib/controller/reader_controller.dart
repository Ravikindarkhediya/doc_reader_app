import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../core/chunk_engine.dart';
import '../core/utils/tts_utils.dart';
import '../data/model/document_model.dart';

class ReaderController extends GetxController {
  final FlutterTts tts = FlutterTts();

  // ── Document ──────────────────────────────────────────────────────────────
  var currentDoc = Rxn<DocumentModel>();
  var paragraphs = <String>[].obs;
  var words = <String>[].obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // ── Playback state ────────────────────────────────────────────────────────
  var isPlaying = false.obs;
  var isCompleted = false.obs;
  var speed = 0.4.obs;
  var currentWordIndex = 0.obs;
  var currentParagraphIndex = 0.obs;

  // ── TTS options ───────────────────────────────────────────────────────────
  var availableVoices = <Map>[].obs;
  var availableLanguages = <String>[].obs;
  var selectedVoice = Rxn<Map>();
  var selectedLanguage = 'en-US'.obs;
  var isSavingMp3 = false.obs;

  // ── Scroll ────────────────────────────────────────────────────────────────
  final scrollController = ScrollController();
  final List<GlobalKey> wordKeys = [];

  // ── Internal ──────────────────────────────────────────────────────────────
  Completer? _completer;
  bool _isStopping = false;
  int _playStartWordIndex = 0;

  /// Character offset of each word (relative to _playStartWordIndex) in the
  /// sanitized TTS string.  Used for accurate word tracking via char offsets.
  final List<int> _wordCharOffsets = [];

  /// Maps global word index → paragraph index
  final List<int> _wordParagraphIndex = [];

  // ── Init ──────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _initTts();
  }

  Future<void> _initTts() async {
    tts.awaitSpeakCompletion(true);

    // Restore persisted settings
    final box = Hive.box('settings');
    speed.value = (box.get('tts_speed', defaultValue: 0.4) as num).toDouble();
    selectedLanguage.value = box.get('tts_language', defaultValue: 'en-US') as String;

    await tts.setSpeechRate(speed.value);
    await tts.setLanguage(selectedLanguage.value);

    tts.setCompletionHandler(() {
      if (!_isStopping) _completer?.complete();
    });

    tts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      _completer?.complete();
    });

    // Use character offset (start/end) for accurate word tracking
    tts.setProgressHandler((text, start, end, word) {
      _onTtsProgress(start, end, word);
    });

    try {
      final voices = await tts.getVoices;
      if (voices is List) {
        availableVoices.value = List<Map>.from(voices);
      }
      final langs = await tts.getLanguages;
      if (langs is List) {
        availableLanguages.value =
        (List<String>.from(langs.map((e) => e.toString())))..sort();
      }

      // Restore saved voice
      final savedVoiceName = box.get('tts_voice_name') as String?;
      if (savedVoiceName != null) {
        final match = availableVoices.firstWhereOrNull(
              (v) => v['name']?.toString() == savedVoiceName,
        );
        if (match != null) {
          selectedVoice.value = match;
          await tts.setVoice(Map<String, String>.from(match));
        }
      }
    } catch (e) {
      debugPrint("TTS init error: $e");
    }
  }

  // ── Word char-offset tracking ─────────────────────────────────────────────

  /// Rebuild the char-offset table whenever play() starts.
  void _buildWordCharOffsets() {
    _wordCharOffsets.clear();
    int pos = 0;
    for (int i = _playStartWordIndex; i < words.length; i++) {
      _wordCharOffsets.add(pos);
      pos += TtsUtils.sanitizeWordForTts(words[i]).length + 1; // +1 for space
    }
  }

  /// Called by TTS progress handler on every spoken word.
  /// Uses [start] (char offset in the TTS string) to find the correct word
  /// via binary search — works correctly even when words repeat.
  void _onTtsProgress(int start, int end, String spokenWord) {
    if (_wordCharOffsets.isEmpty) return;

    // Binary search: find largest offset ≤ start
    int lo = 0, hi = _wordCharOffsets.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (_wordCharOffsets[mid] <= start) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }

    final globalIdx = _playStartWordIndex + lo;
    if (globalIdx >= words.length) return;
    if (globalIdx == currentWordIndex.value) return; // no change

    currentWordIndex.value = globalIdx;
    if (globalIdx < _wordParagraphIndex.length) {
      currentParagraphIndex.value = _wordParagraphIndex[globalIdx];
    }
    scrollToWord(globalIdx);
    _savePosition();
  }

  // ── Scroll ────────────────────────────────────────────────────────────────

  void scrollToWord(int index) {
    if (index < 0 || index >= wordKeys.length) return;
    final ctx = wordKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: 0.5, // keep active word centered
    );
  }

  // ── Document setup ────────────────────────────────────────────────────────

  void setDocument(DocumentModel doc) {
    currentDoc.value = doc;
    isLoading.value = true;
    hasError.value = false;
    isCompleted.value = false;
    currentWordIndex.value = 0;
    currentParagraphIndex.value = 0;

    try {
      final rawText = doc.extractedText.trim().isEmpty
          ? "No readable content found in this document."
          : doc.extractedText;

      final cleaned = ChunkEngine.cleanText(rawText);

      // Use ChunkEngine.toParagraphs so each paragraph is one item
      // (double-newline = paragraph break; single newline → space)
      paragraphs.value = ChunkEngine.toParagraphs(cleaned);

      // Build flat word list + paragraph index map + GlobalKeys
      words.clear();
      _wordParagraphIndex.clear();
      wordKeys.clear();

      for (int pIdx = 0; pIdx < paragraphs.length; pIdx++) {
        final paraWords = paragraphs[pIdx]
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .toList();
        for (final w in paraWords) {
          words.add(w);
          _wordParagraphIndex.add(pIdx);
          wordKeys.add(GlobalKey());
        }
      }

      // Restore last position
      if (doc.lastPosition > 0 && doc.lastPosition < words.length) {
        currentWordIndex.value = doc.lastPosition;
        currentParagraphIndex.value = _wordParagraphIndex[doc.lastPosition];
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = "Error loading document: $e";
    } finally {
      isLoading.value = false;
    }
  }

  // ── Playback ──────────────────────────────────────────────────────────────

  Future<void> play() async {
    if (words.isEmpty || isPlaying.value) return;
    isCompleted.value = false;
    isPlaying.value = true;
    _isStopping = false;

    _playStartWordIndex = currentWordIndex.value;
    _buildWordCharOffsets();

    final ttsText = words
        .sublist(_playStartWordIndex)
        .map(TtsUtils.sanitizeWordForTts)
        .join(' ');

    _completer = Completer();
    await tts.speak(ttsText);
    await _completer!.future;

    if (!_isStopping) {
      isPlaying.value = false;
      isCompleted.value = true;
    }
  }

  Future<void> pause() async {
    if (!isPlaying.value) return;
    _isStopping = true;
    isPlaying.value = false;
    _completer?.complete();
    _completer = null;
    await tts.stop();
    _isStopping = false;
  }

  Future<void> togglePlay() async {
    isPlaying.value ? await pause() : await play();
  }

  /// Skip back 10 words
  Future<void> rewind() async {
    final wasPlaying = isPlaying.value;
    await pause();
    currentWordIndex.value =
        (currentWordIndex.value - 10).clamp(0, words.length - 1);
    _syncParagraphIndex();
    scrollToWord(currentWordIndex.value);
    if (wasPlaying) await play();
  }

  /// Skip forward 10 words
  Future<void> forward() async {
    final wasPlaying = isPlaying.value;
    await pause();
    currentWordIndex.value =
        (currentWordIndex.value + 10).clamp(0, words.length - 1);
    _syncParagraphIndex();
    scrollToWord(currentWordIndex.value);
    if (wasPlaying) await play();
  }

  /// Jump to the start of the previous paragraph
  Future<void> prevParagraph() async {
    if (paragraphs.isEmpty) return;
    final wasPlaying = isPlaying.value;
    await pause();

    final targetPara =
    (currentParagraphIndex.value - 1).clamp(0, paragraphs.length - 1);
    final idx = _wordParagraphIndex.indexOf(targetPara);
    if (idx >= 0) {
      currentWordIndex.value = idx;
      currentParagraphIndex.value = targetPara;
      scrollToWord(idx);
    }
    if (wasPlaying) await play();
  }

  /// Jump to the start of the next paragraph
  Future<void> nextParagraph() async {
    if (paragraphs.isEmpty) return;
    final wasPlaying = isPlaying.value;
    await pause();

    final targetPara =
    (currentParagraphIndex.value + 1).clamp(0, paragraphs.length - 1);
    final idx = _wordParagraphIndex.indexOf(targetPara);
    if (idx >= 0) {
      currentWordIndex.value = idx;
      currentParagraphIndex.value = targetPara;
      scrollToWord(idx);
    }
    if (wasPlaying) await play();
  }

  Future<void> jumpToWord(int index) async {
    final wasPlaying = isPlaying.value;
    await pause();
    currentWordIndex.value = index.clamp(0, words.length - 1);
    _syncParagraphIndex();
    scrollToWord(currentWordIndex.value);
    if (wasPlaying) await play();
  }

  // ── Settings (persisted) ──────────────────────────────────────────────────

  Future<void> setSpeed(double value) async {
    speed.value = value;
    Hive.box('settings').put('tts_speed', value);
    final wasPlaying = isPlaying.value;
    if (wasPlaying) await pause();
    await tts.setSpeechRate(value);
    if (wasPlaying) await play();
  }

  Future<void> setLanguage(String langCode) async {
    final wasPlaying = isPlaying.value;
    if (wasPlaying) await pause();
    selectedLanguage.value = langCode;
    Hive.box('settings').put('tts_language', langCode);
    try {
      await tts.setLanguage(langCode);
    } catch (e) {
      debugPrint("Language set error: $e — falling back to en-US");
      selectedLanguage.value = 'en-US';
      await tts.setLanguage('en-US');
    }
    if (wasPlaying) await play();
  }

  Future<void> setVoice(Map voice) async {
    final wasPlaying = isPlaying.value;
    if (wasPlaying) await pause();
    selectedVoice.value = voice;
    try {
      await tts.setVoice(Map<String, String>.from(voice));
      Hive.box('settings').put('tts_voice_name', voice['name']?.toString());
    } catch (e) {
      debugPrint("Voice set error: $e");
    }
    if (wasPlaying) await play();
  }

  // ── Save MP3 ──────────────────────────────────────────────────────────────

  Future<void> saveAsMp3() async {
    if (words.isEmpty) return;
    isSavingMp3.value = true;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final docName = currentDoc.value?.name
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim() ??
          'audio';
      final path = '${dir.path}/$docName.mp3';
      final fullText = words.map(TtsUtils.sanitizeWordForTts).join(' ');
      await tts.synthesizeToFile(fullText, path);
      Get.snackbar(
        "✅ Saved",
        "Audio saved to: $path",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar("Error", "Could not save audio: $e",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSavingMp3.value = false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _syncParagraphIndex() {
    final idx = currentWordIndex.value;
    if (idx < _wordParagraphIndex.length) {
      currentParagraphIndex.value = _wordParagraphIndex[idx];
    }
  }

  void _savePosition() {
    final doc = currentDoc.value;
    if (doc == null) return;
    doc.lastPosition = currentWordIndex.value;
    try {
      doc.save();
    } catch (_) {}
  }

  String get wordProgress =>
      "${currentWordIndex.value} / ${words.length} words";

  double get progressPercent =>
      words.isEmpty ? 0 : currentWordIndex.value / words.length;

  @override
  void onClose() {
    tts.stop();
    scrollController.dispose();
    super.onClose();
  }
}