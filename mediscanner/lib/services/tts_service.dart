import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused }

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  TtsState _state = TtsState.stopped;
  TtsState get state => _state;

  VoidCallback? onStateChanged;

  Future<void> init() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _flutterTts.setSpeechRate(0.48); // Slightly slower for clear clinical terminology
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);

        _flutterTts.setStartHandler(() {
          _state = TtsState.playing;
          onStateChanged?.call();
        });

        _flutterTts.setCompletionHandler(() {
          _state = TtsState.stopped;
          onStateChanged?.call();
        });

        _flutterTts.setErrorHandler((msg) {
          _state = TtsState.stopped;
          onStateChanged?.call();
        });

        _flutterTts.setPauseHandler(() {
          _state = TtsState.paused;
          onStateChanged?.call();
        });
      }
    } catch (_) {
      // Ignored if platform not supported
    }
  }

  Future<void> speak({required String text, required bool isSinhala}) async {
    try {
      await stop();
      if (text.trim().isEmpty) return;

      if (isSinhala) {
        // Check if Sinhala is available on device, otherwise use default
        final languages = await _flutterTts.getLanguages;
        if (languages is List && languages.contains('si-LK')) {
          await _flutterTts.setLanguage('si-LK');
        } else {
          await _flutterTts.setLanguage('en-US');
        }
      } else {
        await _flutterTts.setLanguage('en-US');
      }

      _state = TtsState.playing;
      onStateChanged?.call();
      await _flutterTts.speak(text);
    } catch (_) {
      _state = TtsState.stopped;
      onStateChanged?.call();
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _state = TtsState.paused;
      onStateChanged?.call();
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _state = TtsState.stopped;
      onStateChanged?.call();
    } catch (_) {}
  }
}
