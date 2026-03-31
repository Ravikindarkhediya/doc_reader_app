import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../core/chunk_engine.dart';
import '../data/model/document_model.dart';

class ReaderController extends GetxController {
  // TTS
  final FlutterTts tts = FlutterTts();

  // State
  var currentDoc = Rxn<DocumentModel>();
  var chunks = <String>[].obs;
  var currentIndex = 0.obs;
  var speed = 0.6.obs;
  var isPlaying = false.obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Voice / Language
  var availableVoices = <Map>[].obs;
  var availableLanguages = <String>[].obs;
  var selectedVoice = Rxn<Map>();
  var selectedLanguage = 'en-US'.obs;

  // Reading Mode
  var chunkMode = ChunkMode.sentence.obs;

  // Save as MP3 state
  var isSavingMp3 = false.obs;

  Completer? _completer;
  bool _stopRequested = false;

  @override
  void onInit() {
    super.onInit();
    _initTts();
  }

  Future<void> _initTts() async {
    tts.awaitSpeakCompletion(true);
    await tts.setSpeechRate(speed.value);

    tts.setCompletionHandler(() => _completer?.complete());
    tts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      _completer?.complete();
    });

    try {
      final voices = await tts.getVoices;
      if (voices is List) {
        availableVoices.value = List<Map>.from(voices);
      }

      final langs = await tts.getLanguages;
      if (langs is List) {
        availableLanguages.value = List<String>.from(langs.map((e) => e.toString()));
      }
    } catch (e) {
      debugPrint("TTS init error: $e");
    }
  }

  // Load document into reader
  void setDocument(DocumentModel doc) {
    currentDoc.value = doc;
    isLoading.value = true;
    hasError.value = false;

    try {
      final text = doc.extractedText.trim().isEmpty
          ? "No readable content found in this document."
          : doc.extractedText;

      chunks.value = ChunkEngine.splitIntoChunks(text, mode: chunkMode.value);

      if (chunks.isEmpty) {
        hasError.value = true;
        errorMessage.value = "Could not parse document content.";
      }

      // Resume from last position
      final savedPos = doc.lastPosition;
      currentIndex.value =
          (savedPos < chunks.length) ? savedPos : 0;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = "Error loading document: $e";
    } finally {
      isLoading.value = false;
    }
  }

  void changeChunkMode(ChunkMode mode) {
    chunkMode.value = mode;
    if (currentDoc.value != null) {
      setDocument(currentDoc.value!);
    }
  }

  // PLAY
  Future<void> play() async {
    if (chunks.isEmpty || isPlaying.value) return;

    _stopRequested = false;
    isPlaying.value = true;

    while (isPlaying.value &&
        !_stopRequested &&
        currentIndex.value < chunks.length) {

      final text = chunks[currentIndex.value];

      if (text.trim().isNotEmpty) {
        await tts.speak(text);
        await _waitForCompletion();
      }

      if (_stopRequested) break;

      currentIndex.value++;

      _savePosition();

      await Future.delayed(const Duration(milliseconds: 40));
    }

    isPlaying.value = false;
  }

  Future<void> _waitForCompletion() async {
    _completer = Completer();
    return _completer!.future;
  }

  // PAUSE
  Future<void> pause() async {
    _stopRequested = true;
    isPlaying.value = false;

    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete();
    }

    await tts.stop();
  }

  // REWIND (go back 1 chunk)
  Future<void> rewind() async {
    if (currentIndex.value > 0) {
      final wasPlaying = isPlaying.value;
      await pause();
      currentIndex.value--;
      if (wasPlaying) play();
    }
  }

  // FORWARD (go forward 1 chunk)
  Future<void> forward() async {
    if (currentIndex.value < chunks.length - 1) {
      final wasPlaying = isPlaying.value;
      await pause();
      currentIndex.value++;
      if (wasPlaying) play();
    }
  }

  // Jump to specific chunk
  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= chunks.length) return;
    final wasPlaying = isPlaying.value;
    await pause();
    currentIndex.value = index;
    if (wasPlaying) play();
  }

  // Speed control
  Future<void> setSpeed(double value) async {
    speed.value = value;
    await tts.setSpeechRate(value);
  }

  // Language
  Future<void> setLanguage(String langCode) async {
    selectedLanguage.value = langCode;
    await tts.setLanguage(langCode);
  }

  // Voice
  Future<void> setVoice(Map voice) async {
    selectedVoice.value = voice;
    await tts.setVoice(Map<String, String>.from(voice));
  }

  // Bookmark current chunk
  void toggleBookmark() {
    final doc = currentDoc.value;
    if (doc == null) return;
    final idx = currentIndex.value;

    if (doc.hasBookmark(idx)) {
      doc.removeBookmark(idx);
      Get.snackbar("Bookmark Removed", "Removed from bookmarks",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2));
    } else {
      doc.addBookmark(idx);
      Get.snackbar("Bookmarked", "Position saved",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2));
    }
  }

  bool get isCurrentChunkBookmarked {
    final doc = currentDoc.value;
    if (doc == null) return false;
    return doc.hasBookmark(currentIndex.value);
  }

  // Save position
  void _savePosition() {
    final doc = currentDoc.value;
    if (doc == null) return;
    doc.lastPosition = currentIndex.value;
    try {
      doc.save();
    } catch (_) {}
  }

  // Save as MP3 (requires flutter_tts synthesize support)
  Future<void> saveAsMp3() async {
    if (chunks.isEmpty) return;
    isSavingMp3.value = true;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final docName = currentDoc.value?.name
              .replaceAll(RegExp(r'[^\w\s]'), '')
              .trim() ??
          'audio';
      final path = '${dir.path}/$docName.mp3';

      final fullText = chunks.join('. ');
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

  double get progressPercent {
    if (chunks.isEmpty) return 0;
    return currentIndex.value / chunks.length;
  }

  String get progressText {
    if (chunks.isEmpty) return '0 / 0';
    return '${currentIndex.value + 1} / ${chunks.length}';
  }

  @override
  void onClose() {
    tts.stop();
    super.onClose();
  }
}
