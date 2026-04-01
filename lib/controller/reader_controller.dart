import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../core/chunk_engine.dart';
import '../data/model/document_model.dart';

class ReaderController extends GetxController {
  final FlutterTts tts = FlutterTts();

  var currentDoc = Rxn<DocumentModel>();
  var chunks = <String>[].obs;
  var currentIndex = 0.obs;
  var speed = 0.6.obs;
  var isPlaying = false.obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var paragraphs = <String>[].obs;
  var availableVoices = <Map>[].obs;
  var availableLanguages = <String>[].obs;
  var selectedVoice = Rxn<Map>();
  var selectedLanguage = 'en-US'.obs;
  var isSavingMp3 = false.obs;
  var isCompleted = false.obs;

  // Word-level tracking
  var words = <String>[].obs;
  var currentWordIndex = 0.obs;

  // Paragraph-level tracking (for highlighting which paragraph is active)
  var currentParagraphIndex = 0.obs;

  // Scroll controller — exposed so View can assign a key
  final scrollController = ScrollController();
  // Per-word GlobalKeys so we can scroll the active word into view
  final List<GlobalKey> wordKeys = [];

  Completer? _completer;
  bool _isStopping = false;

  // ── Word offset map: word global-index → (paragraphIndex, wordIndexInPara) ──
  final List<_WordPos> _wordPositions = [];

  @override
  void onInit() {
    super.onInit();
    _initTts();
  }

  Future<void> _initTts() async {
    tts.awaitSpeakCompletion(true);
    await tts.setSpeechRate(speed.value);
    await tts.setLanguage(selectedLanguage.value);

    tts.setCompletionHandler(() {
      if (!_isStopping) {
        _completer?.complete();
      }
    });

    tts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      _completer?.complete();
    });

    // Progress handler — match spoken word to our word list
    tts.setProgressHandler((text, start, end, word) {
      _onTtsWord(word, start, end);
    });

    try {
      final voices = await tts.getVoices;
      if (voices is List) {
        availableVoices.value = List<Map>.from(voices);
      }
      final langs = await tts.getLanguages;
      if (langs is List) {
        availableLanguages.value =
        List<String>.from(langs.map((e) => e.toString()));
      }
    } catch (e) {
      debugPrint("TTS init error: $e");
    }
  }

  // ── Called by TTS progress handler ──────────────────────────────────────────
  void _onTtsWord(String word, int start, int end) {
    // The TTS reports the word it's currently speaking.
    // We search forward from currentWordIndex to find the matching word.
    final searchStart = currentWordIndex.value;
    final searchEnd = (searchStart + 60).clamp(0, words.length);

    for (int i = searchStart; i < searchEnd; i++) {
      // Strip punctuation for comparison
      final clean = words[i].replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '').toLowerCase();
      final spoken = word.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '').toLowerCase();
      if (clean == spoken || clean.startsWith(spoken) || spoken.startsWith(clean)) {
        currentWordIndex.value = i;
        updateParagraphIndex(i);
        scrollToWord(i);
        _savePosition();
        break;
      }
    }
  }

  void updateParagraphIndex(int wordIndex) {
    if (wordIndex < _wordPositions.length) {
      currentParagraphIndex.value = _wordPositions[wordIndex].paragraphIndex;
    }
  }

  void scrollToWord(int index) {
    if (index < wordKeys.length) {
      final key = wordKeys[index];
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.4, // keep highlighted word slightly above center
        );
      }
    }
  }

  // ── Document setup ───────────────────────────────────────────────────────────
  void setDocument(DocumentModel doc) {
    currentDoc.value = doc;
    isLoading.value = true;
    hasError.value = false;
    currentWordIndex.value = 0;
    currentParagraphIndex.value = 0;

    try {
      final rawText = doc.extractedText.trim().isEmpty
          ? "No readable content found in this document."
          : doc.extractedText;

      final cleaned = ChunkEngine.cleanText(rawText);

      // Split into paragraphs — preserve single line-breaks as paragraph breaks
      paragraphs.value = cleaned
          .split(RegExp(r'\n+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Build flat word list + position map
      words.clear();
      _wordPositions.clear();
      wordKeys.clear();

      for (int pIdx = 0; pIdx < paragraphs.length; pIdx++) {
        final paraWords = paragraphs[pIdx].split(RegExp(r'\s+'));
        for (int wIdx = 0; wIdx < paraWords.length; wIdx++) {
          final w = paraWords[wIdx];
          if (w.isEmpty) continue;
          words.add(w);
          _wordPositions.add(_WordPos(pIdx, wIdx));
          wordKeys.add(GlobalKey());
        }
      }

      // Restore last position
      if (doc.lastPosition > 0 && doc.lastPosition < words.length) {
        currentWordIndex.value = doc.lastPosition;
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = "Error loading document: $e";
    } finally {
      isLoading.value = false;
    }
  }

  // ── Playback ─────────────────────────────────────────────────────────────────
  Future<void> play() async {
    if (words.isEmpty || isPlaying.value) return;

    isPlaying.value = true;
    _isStopping = false;

    // Speak from current word to end
    final remaining = words.sublist(currentWordIndex.value).join(' ');

    _completer = Completer();
    await tts.speak(remaining);
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

  Future<void> rewind() async {
    final wasPlaying = isPlaying.value;
    await pause();
    currentWordIndex.value =
        (currentWordIndex.value - 50).clamp(0, words.length - 1);
    updateParagraphIndex(currentWordIndex.value);
    scrollToWord(currentWordIndex.value);
    if (wasPlaying) await play();
  }

  Future<void> forward() async {
    final wasPlaying = isPlaying.value;
    await pause();
    currentWordIndex.value =
        (currentWordIndex.value + 50).clamp(0, words.length - 1);
    updateParagraphIndex(currentWordIndex.value);
    scrollToWord(currentWordIndex.value);
    if (wasPlaying) await play();
  }

  Future<void> jumpToWord(int index) async {
    final wasPlaying = isPlaying.value;
    await pause();
    currentWordIndex.value = index.clamp(0, words.length - 1);
    updateParagraphIndex(currentWordIndex.value);
    scrollToWord(currentWordIndex.value);
    if (wasPlaying) await play();
  }

  // ── Speed ────────────────────────────────────────────────────────────────────
  Future<void> setSpeed(double value) async {
    speed.value = value;
    final wasPlaying = isPlaying.value;
    if (wasPlaying) await pause();
    await tts.setSpeechRate(value);
    if (wasPlaying) await play();
  }

  // ── Language ─────────────────────────────────────────────────────────────────
  Future<void> setLanguage(String langCode) async {
    final wasPlaying = isPlaying.value;
    if (wasPlaying) await pause();
    selectedLanguage.value = langCode;
    try {
      await tts.setLanguage(langCode);
    } catch (e) {
      debugPrint("Language set error: $e — falling back to en-US");
      selectedLanguage.value = 'en-US';
      await tts.setLanguage('en-US');
    }
    if (wasPlaying) await play();
  }

  // ── Voice ────────────────────────────────────────────────────────────────────
  Future<void> setVoice(Map voice) async {
    final wasPlaying = isPlaying.value;
    if (wasPlaying) await pause();
    selectedVoice.value = voice;
    try {
      await tts.setVoice(Map<String, String>.from(voice));
    } catch (e) {
      debugPrint("Voice set error: $e");
    }
    if (wasPlaying) await play();
  }

  // ── Save MP3 ─────────────────────────────────────────────────────────────────
  Future<void> saveAsMp3() async {
    if (words.isEmpty) return;
    isSavingMp3.value = true;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final docName =
          currentDoc.value?.name.replaceAll(RegExp(r'[^\w\s]'), '').trim() ??
              'audio';
      final path = '${dir.path}/$docName.mp3';
      final fullText = words.join(' ');
      await tts.synthesizeToFile(fullText, path);
      Get.snackbar(
        "Saved",
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

  // ── Helpers ───────────────────────────────────────────────────────────────────
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

  double get progressPercent {
    if (words.isEmpty) return 0;
    return currentWordIndex.value / words.length;
  }

  @override
  void onClose() {
    tts.stop();
    scrollController.dispose();
    super.onClose();
  }
}

class _WordPos {
  final int paragraphIndex;
  final int wordIndexInPara;
  _WordPos(this.paragraphIndex, this.wordIndexInPara);
}
