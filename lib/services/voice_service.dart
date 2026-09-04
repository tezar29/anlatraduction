import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' show SpeechListenOptions;

/// Encapsule la reconnaissance vocale (parole → texte) et
/// la synthèse vocale (texte → parole) avec une gestion robuste du focus.
class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;
  bool _isInitializing = false;
  Completer<void>? _activeSpeechCompletion;

  Function(String)? _lastErrorHandler;
  void Function(String status)? _statusListener;

  Future<bool> init({Function(String)? onError}) async {
    if (onError != null) _lastErrorHandler = onError;
    if (_isInitializing) return _speechAvailable;
    _isInitializing = true;
    try {
      _speechAvailable = await _speech.initialize(
        onError: (val) {
          debugPrint('STT Error: ${val.errorMsg}');
          _lastErrorHandler?.call(val.errorMsg);
        },
        onStatus: (val) {
          debugPrint('STT Status: $val');
          _statusListener?.call(val);
        },
        finalTimeout: const Duration(milliseconds: 2000),
      );
      return _speechAvailable;
    } catch (e) {
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  bool get isAvailable => _speechAvailable;
  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required String localeId,
    required void Function(String text) onResult,
    void Function(String text)? onPartialResult,
    VoidCallback? onServiceError,
  }) async {
    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!_speechAvailable) {
      final ok = await init();
      if (!ok) {
        if (onServiceError != null) onServiceError();
        return;
      }
    }

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          } else if (onPartialResult != null) {
            onPartialResult(result.recognizedWords);
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 10),
          cancelOnError: true,
          partialResults: true,
          onDevice: false,
        ),
      );
    } catch (e) {
      debugPrint("Listen error: $e");
      if (onServiceError != null) onServiceError();
    }
  }

  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}
  }

  Future<void> speak(String text, {required String localeId}) async {
    if (text.trim().isEmpty) return;
    
    // Étape 1 : Désactiver micro avant TTS
    await stopListening();
    await Future.delayed(const Duration(milliseconds: 300));
    
    await _tts.stop();
    await _tts.setLanguage(localeId);
    await _tts.setSpeechRate(0.5);

    // Étape 2 : Détection de la fin de lecture
    final completion = Completer<void>();
    _activeSpeechCompletion = completion;
    
    _tts.setCompletionHandler(() {
      if (!completion.isCompleted) completion.complete();
    });
    _tts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      if (!completion.isCompleted) completion.complete();
    });

    await _tts.speak(text);
    
    // Attente de la fin réelle
    await completion.future.timeout(const Duration(seconds: 25), onTimeout: () {
      if (!completion.isCompleted) completion.complete();
    });
    
    if (identical(_activeSpeechCompletion, completion)) {
      _activeSpeechCompletion = null;
    }
    
    // Délai de confort après lecture
    await Future.delayed(const Duration(milliseconds: 1500));
  }

  void setStatusListener(void Function(String status) listener) {
    _statusListener = listener;
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    final completion = _activeSpeechCompletion;
    _activeSpeechCompletion = null;
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
  }

  Future<void> reset() async {
    await stopListening();
    await stopSpeaking();
    await Future.delayed(const Duration(milliseconds: 500));
    _speechAvailable = false;
    await init(onError: _lastErrorHandler);
  }
}
