import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

import '../data/model/document_model.dart';

class ReaderController extends GetxController {
  final FlutterTts tts = FlutterTts();
  var currentDoc = Rxn<DocumentModel>();
  var fullText = "".obs;
  var chunks = <String>[].obs;
  var currentIndex = 0.obs;
  var speed = 0.5.obs;
  Completer? _completer;
  var isPlaying = false.obs;

  @override
  void onInit() {
    super.onInit();

    // 🔥 IMPORTANT
    tts.awaitSpeakCompletion(true);

    // speed set
    tts.setSpeechRate(speed.value);

    // completion handler
    tts.setCompletionHandler(() {
      _onSpeakComplete();
    });
  }

  void _onSpeakComplete() {
    _completer?.complete();
  }

  // 🔥 Load text
  void loadText(String text) {
    fullText.value = text;
    chunks.value = _splitText(text);
  }

  // 🔥 Split text into sentences
  List<String> _splitText(String text) {
    return text
        .split(RegExp(r'[.!?]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> setLanguage(String langCode) async {
    await tts.setLanguage(langCode);
  }
  Future<List> getVoices() async {
    return await tts.getVoices;
  }

  Future<void> setVoice(Map<String, String> voice) async {
    await tts.setVoice(voice);
  }

  // ▶ PLAY
  Future<void> play() async {
    if (chunks.isEmpty) return;

    isPlaying.value = true;

    while (isPlaying.value && currentIndex.value < chunks.length) {

      final text = chunks[currentIndex.value];

      await tts.speak(text);
      await _waitForCompletion();

      if (!isPlaying.value) break;

      currentIndex.value++;
    }

    isPlaying.value = false;
  }

  // ⏸ PAUSE
  Future<void> pause() async {
    isPlaying.value = false;
    await tts.stop();
  }

  // 🔁 RESUME
  Future<void> resume() async {
    play();
  }

  // 🔥 Wait for TTS complete
  Future<void> _waitForCompletion() async {
    _completer = Completer();
    return _completer!.future;
  }

  void setSpeed(double value) async {
    speed.value = value;
    await tts.setSpeechRate(value);
  }

  Future<void> rewind() async {
    if (currentIndex.value > 0) {
      await tts.stop();
      currentIndex.value--;
      play();
    }
  }

  Future<void> forward() async {
    if (currentIndex.value < chunks.length - 1) {
      await tts.stop();
      currentIndex.value++;
      play();
    }
  }

  void  setDocument(DocumentModel doc) {
    currentDoc.value = doc;

    loadText(doc.extractedText.isEmpty
        ? "No readable content found"
        : doc.extractedText);

    // 🔥 IMPORTANT FIX
    currentIndex.value = doc.lastPosition;
  }
}