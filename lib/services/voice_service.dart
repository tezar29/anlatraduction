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
  String? _lastListenLocale;
  Completer<void>? _activeSpeechCompletion;

  // On mémorise les callbacks une fois fournis, pour pouvoir les
  // réappliquer automatiquement à chaque réinitialisation (reset), sans
  // que l'appelant ait à les repasser à chaque fois. C'est ce qui manquait
  // avant : reset() appelait init() sans callback d'erreur, donc après le
  // premier message, une erreur de reconnaissance (timeout, "no match")
  // ne relançait plus le micro — la conversation "s'arrêtait" de capter.
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
    // Arrêt propre de toute écoute ou lecture en cours.
    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 100));

    // Cas particulier : changement de langue par rapport au dernier
    // lancement (typiquement en conversation, où on alterne entre les deux
    // langues à chaque tour — contrairement à la Traduction, qui garde
    // toujours la même). Demander au moteur natif d'écouter dans une
    // nouvelle langue juste après avoir utilisé la précédente le laisse
    // parfois "occupé" en interne sans erreur visible ; ça ne se débloque
    // alors que plus tard tout seul (ou en coupant/relançant le micro à la
    // main) — exactement le symptôme observé. On force donc ici une
    // réinitialisation complète avant de changer de langue, avec un délai
    // plus long pour laisser le moteur natif vraiment se libérer.
    final localeChanged = _lastListenLocale != null && _lastListenLocale != localeId;
    if (localeChanged) {
      await Future.delayed(const Duration(milliseconds: 400));
      _speechAvailable = false;
    }

    // On initialise seulement si nécessaire (ou si on vient de forcer une
    // réinit ci-dessus à cause du changement de langue). Réinitialiser à
    // CHAQUE appui, même sans changement de langue, a été essayé et a
    // provoqué une régression plus large (double init en rafale faisant
    // échouer la capture y compris en Traduction) — le problème est donc
    // spécifiquement lié au changement de langue, pas à la relance en soi.
    if (!_speechAvailable) {
      final ok = await init();
      if (!ok) {
        if (onServiceError != null) onServiceError();
        return;
      }
    }

    _lastListenLocale = localeId;

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        cancelOnError: false, // Gestion manuelle pour relance auto
        partialResults: true,
        onDevice: true,
        listenFor: const Duration(seconds: 40),
        pauseFor: const Duration(seconds: 5),
      ),
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        } else if (onPartialResult != null) {
          onPartialResult(result.recognizedWords);
        }
      },
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> speak(String text, {required String localeId}) async {
    if (text.trim().isEmpty) return;
    
    // Étape 1 : Désactiver temporairement l'écouteur avant de parler
    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 150));
    }
    
    await _tts.stop();
    await _tts.setLanguage(localeId);
    await _tts.setSpeechRate(0.5);

    // Étape 2 : Détection de la fin de lecture via Completer
    final completion = Completer<void>();
    _activeSpeechCompletion = completion;
    _tts.setCompletionHandler(() {
      if (!completion.isCompleted) completion.complete();
    });
    _tts.setErrorHandler((msg) {
      if (!completion.isCompleted) completion.complete();
    });

    await _tts.speak(text);
    
    // On attend vraiment la fin de la lecture (UtteranceProgressListener onDone)
    await completion.future.timeout(const Duration(seconds: 15), onTimeout: () {});
    if (identical(_activeSpeechCompletion, completion)) {
      _activeSpeechCompletion = null;
    }
    
    // TEMPS D'ATTENTE AUGMENTÉ : On laisse le matériel audio "souffler" 
    // pour éviter les échos au redémarrage du micro. Augmenté de 2000ms à 2500ms
    // pour réduire les blocages lors des changements d'écran.
    await Future.delayed(const Duration(milliseconds: 2500));
  }

  /// Écoute les changements d'état du système (ex: désactivation par l'OS).
  /// On se contente de mémoriser le listener : il sera appliqué au prochain
  /// vrai appel à init() (voir plus haut), au lieu de forcer une
  /// initialisation immédiate du moteur de reconnaissance ici.
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

  /// Réinitialise complètement le service voix pour repartir de zéro,
  /// tout en conservant le rappel d'erreur déjà enregistré — sinon
  /// l'auto-relance du micro ne fonctionne plus qu'au tout premier
  /// message de la conversation.
  Future<void> reset() async {
    await stopListening();
    await stopSpeaking();
    // Attendre que le matériel audio soit vraiment libéré
    await Future.delayed(const Duration(milliseconds: 600));
    _speechAvailable = false;
    _lastListenLocale = null;
    await init(onError: _lastErrorHandler);
  }
}
