import 'package:flutter/services.dart';

/// Encapsule la reconnaissance vocale (parole → texte) et
/// la synthèse vocale (texte → parole) pour toute l'application.
class VoiceService {
  static const MethodChannel _channel = MethodChannel('com.example.transturc/voice');
  bool _speechAvailable = false;
  void Function(String text)? _onResult;

  Future<bool> init() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'speechResult') {
        final text = (call.arguments as Map?)?['text'];
        if (text is String && text.isNotEmpty) _onResult?.call(text);
      }
    });
    _speechAvailable = await _channel.invokeMethod<bool>('initialize') ?? false;
    return _speechAvailable;
  }

  bool get isAvailable => _speechAvailable;
  bool get isListening => _speechAvailable;

  /// Démarre l'écoute et renvoie le texte reconnu en continu via [onResult].
  Future<void> startListening({
    required String localeId,
    required void Function(String text) onResult,
  }) async {
    _onResult = onResult;
    try {
      if (!_speechAvailable && !await init()) return;
      await _channel.invokeMethod<void>('startListening', {'localeId': localeId});
    } catch (_) {
      _speechAvailable = false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _channel.invokeMethod<void>('stopListening');
    } catch (_) {}
  }

  Future<void> speak(String text, {required String localeId}) async {
    if (text.trim().isEmpty) return;
    try {
      if (!_speechAvailable && !await init()) return;
      await _channel.invokeMethod<void>('speak', {'text': text, 'localeId': localeId});
    } catch (_) {
      _speechAvailable = false;
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _channel.invokeMethod<void>('stopSpeaking');
    } catch (_) {}
  }
}
