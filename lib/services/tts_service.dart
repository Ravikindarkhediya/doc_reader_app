import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
  }

  Future speak(String text) async {
    await _tts.speak(text);
  }

  Future pause() async {
    await _tts.pause();
  }

  Future stop() async {
    await _tts.stop();
  }
}