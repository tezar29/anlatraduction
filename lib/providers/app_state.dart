import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/language.dart';
import '../models/backend_models.dart';
import '../models/translation_entry.dart';
import '../services/backend_service.dart';
import '../services/guest_session_service.dart';
import '../services/language_pack_service.dart';
import '../services/translation_service.dart';
import '../services/voice_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.translationService,
    required this.voiceService,
    required this.backend,
  }) {
    _initSystemMicMonitor();
  }

  final TranslationService translationService;
  final VoiceService voiceService;
  final BackendService backend;

  bool isAuthenticated = false;
  bool isSessionLoading = false;
  String? sessionError;
  UserProfile? profile;
  Entitlements? entitlements;
  UserSubscription? subscription;
  List<SubscriptionPlan> availablePlans = [];
  List<BillingInvoice> invoices = [];
  List<PaymentRecord> payments = [];
  List<Conversation> conversations = [];
  Conversation? activeConversation;
  List<Speaker> speakers = [];
  List<Map<String, dynamic>> timeline = [];
  Map<String, dynamic> conversationUsage = {};
  List<LanguagePack> availableLanguagePacks = [];
  List<LanguagePack> recommendedLanguagePacks = [];
  List<LanguagePackInstallation> installedLanguagePacks = [];
  GuestSession? guestSession;
  Map<String, dynamic> guestDailyUsage = {};
  String? refreshToken;

  // --- États de saisie indépendants ---
  String inputText = '';
  String conversationInputText = '';
  String outputText = '';
  String lastRecordedText = '';
  final Map<int, String> _localOriginals = {};
  Map<int, String> get localOriginals => _localOriginals;

  bool isTranslating = false;
  bool isListening = false;
  bool _isAutoRestarting = false;
  bool _isTranslateMode = true;
  bool _conversationTurnInProgress = false;
  bool _conversationScreenActive = false;

  void _initSystemMicMonitor() {
    voiceService.setStatusListener((status) {
      debugPrint("System Mic Status: $status");
      if ((status == 'done' || status == 'notListening') && isListening && !_isAutoRestarting) {
        isListening = false;
        _stopRecordingTimer();
        notifyListeners();
      }
    });
  }

  void setConversationScreenActive(bool active) {
    _conversationScreenActive = active;
    if (!active && !_isTranslateMode) {
      stopAllListening();
    }
  }

  void setInputText(String text) {
    inputText = text;
    notifyListeners();
  }

  void setConversationInputText(String text) {
    conversationInputText = text;
    notifyListeners();
  }

  // --- Gestion de l'audio ---
  int recordingSeconds = 0;
  Timer? _recordingTimer;

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      recordingSeconds++;
      notifyListeners();
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    recordingSeconds = 0;
    notifyListeners();
  }

  Future<void> stopAllAudio() async {
    _isAutoRestarting = false;
    await voiceService.stopListening();
    await voiceService.stopSpeaking();
    if (isListening) {
      _stopRecordingTimer();
      isListening = false;
      notifyListeners();
    }
  }

  void stopAllListening() {
    unawaited(stopAllAudio());
  }

  // --- Langues ---
  AppLanguage sourceLang = AppLanguage.turkish;
  AppLanguage targetLang = AppLanguage.french;

  void swapLanguages() {
    final tmp = sourceLang;
    sourceLang = targetLang;
    targetLang = tmp;
    notifyListeners();
  }

  void setSourceLang(AppLanguage lang) {
    sourceLang = lang;
    notifyListeners();
  }

  void setTargetLang(AppLanguage lang) {
    targetLang = lang;
    notifyListeners();
  }

  void _syncLanguagesWithProfile() {
    if (profile == null) return;
    final prefCode = profile!.preferredLanguage.toLowerCase();
    try {
      final match = AppLanguage.all.firstWhere(
        (l) => l.code.toLowerCase() == prefCode,
      );
      sourceLang = match;
      if (targetLang.code == sourceLang.code) {
        targetLang = AppLanguage.all.firstWhere(
          (l) => l.code != sourceLang.code,
          orElse: () => AppLanguage.turkish,
        );
      }
    } catch (_) {}
  }

  // --- Authentification ---
  Future<void> login(String email, String password) async {
    isSessionLoading = true;
    sessionError = null;
    notifyListeners();
    try {
      final result = await backend.login(email, password);
      final accessToken = (result['accessToken'] ?? result['token'] ?? result['access_token'])?.toString();
      final incomingRefreshToken = (result['refreshToken'] ?? result['refresh_token'] ?? result['refreshTokenValue'])?.toString();

      if ((accessToken == null || accessToken.isEmpty) && (incomingRefreshToken == null || incomingRefreshToken.isEmpty)) {
        throw Exception('Aucun jeton d\'authentification reçu.');
      }

      backend.accessToken = accessToken ?? backend.accessToken;
      refreshToken = incomingRefreshToken?.isNotEmpty == true ? incomingRefreshToken : refreshToken;

      profile = await backend.profile();
      _syncLanguagesWithProfile();

      try {
        entitlements = await backend.entitlements();
        subscription = await backend.currentSubscription();
        conversations = await backend.conversations();
      } catch (_) {}

      isAuthenticated = true;
    } catch (error) {
      sessionError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isSessionLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String primaryLanguage,
    required String country,
    required String timezone,
  }) async {
    isSessionLoading = true;
    sessionError = null;
    notifyListeners();
    try {
      final result = await backend.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        primaryLanguage: primaryLanguage,
        country: country,
        timezone: timezone,
      );

      final accessToken = (result['accessToken'] ?? result['token'] ?? result['access_token'])?.toString();
      if (accessToken != null && accessToken.isNotEmpty) {
        backend.accessToken = accessToken;
        profile = await backend.profile();
        _syncLanguagesWithProfile();
        isAuthenticated = true;
      }
    } catch (error) {
      sessionError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isSessionLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    stopAllListening();
    if (refreshToken?.isNotEmpty == true) {
      try {
        await backend.logout(refreshToken!);
      } catch (_) {}
    }
    backend.accessToken = null;
    refreshToken = null;
    profile = null;
    isAuthenticated = false;
    notifyListeners();
  }

  Future<void> resendVerification(String email) async {
    isSessionLoading = true;
    sessionError = null;
    notifyListeners();
    try {
      await backend.resendVerification(email: email);
    } catch (error) {
      sessionError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isSessionLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyEmail({required String email, required String code}) async {
    isSessionLoading = true;
    sessionError = null;
    notifyListeners();
    try {
      await backend.verifyEmail(email: email, code: code);
    } catch (error) {
      sessionError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isSessionLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestPasswordReset(String email) async {
    isSessionLoading = true;
    sessionError = null;
    notifyListeners();
    try {
      await backend.forgotPassword(email: email);
    } catch (error) {
      sessionError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isSessionLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    isSessionLoading = true;
    sessionError = null;
    notifyListeners();
    try {
      await backend.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
    } catch (error) {
      sessionError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isSessionLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? preferredLanguage,
    String? country,
    String? timezone,
  }) async {
    isSessionLoading = true;
    sessionError = null;
    notifyListeners();
    try {
      final updated = await backend.updateProfile(
        fullName: fullName,
        preferredLanguage: preferredLanguage,
        country: country,
        timezone: timezone,
      );
      profile = updated;
      await refreshAccount();
    } catch (error) {
      sessionError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isSessionLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePlan(String planCode) async {
    isSessionLoading = true;
    sessionError = null;
    notifyListeners();
    try {
      subscription = await backend.changePlan(planCode);
      entitlements = await backend.entitlements();
    } catch (error) {
      sessionError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isSessionLoading = false;
      notifyListeners();
    }
  }

  Future<void> upgradePlan(String planCode) async {
    isSessionLoading = true;
    sessionError = null;
    notifyListeners();
    try {
      final updated = await backend.changePlan(planCode);
      subscription = updated;

      final invoice = await backend.createInvoice(subscriptionId: updated.id);
      if (invoice.id.isNotEmpty) {
        final payment = await backend.createPayment(
          invoiceId: invoice.id,
          provider: 'stripe',
          amount: invoice.amount,
          currency: invoice.currency,
        );
        if (payment.id.isNotEmpty) {
          await backend.confirmPayment(payment.id);
        }
      }

      entitlements = await backend.entitlements();
    } catch (error) {
      sessionError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isSessionLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelSubscription() async {
    isSessionLoading = true;
    sessionError = null;
    notifyListeners();
    try {
      subscription = await backend.cancelSubscription();
      entitlements = await backend.entitlements();
    } catch (error) {
      sessionError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isSessionLoading = false;
      notifyListeners();
    }
  }

  Future<void> renewSubscription() async {
    isSessionLoading = true;
    sessionError = null;
    notifyListeners();
    try {
      subscription = await backend.renewSubscription();
      entitlements = await backend.entitlements();
    } catch (error) {
      sessionError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isSessionLoading = false;
      notifyListeners();
    }
  }

  Future<void> createGuestSession({
    required String deviceId,
    required String displayName,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final service = GuestSessionService(
      baseUrl: 'https://api.anla.mybestsejour.com',
    );
    try {
      guestSession = await service.createSession(
        deviceId: deviceId,
        displayName: displayName,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      guestDailyUsage = await service.checkDailyUsage(guestSession!.id);
      notifyListeners();
    } catch (_) {
      sessionError = 'Impossible de créer la session invitée.';
      notifyListeners();
    }
  }

  Future<void> loadGuestDailyUsage() async {
    if (guestSession == null) return;
    final service = GuestSessionService(
      baseUrl: 'https://api.anla.mybestsejour.com',
    );
    try {
      guestDailyUsage = await service.getDailyUsage(guestSession!.id);
      notifyListeners();
    } catch (_) {
      guestDailyUsage = {};
      notifyListeners();
    }
  }

  Future<void> installLanguagePack(AppLanguage language) async {
    final packService = LanguagePackService(
      baseUrl: 'https://api.anla.mybestsejour.com',
      accessToken: backend.accessToken,
    );
    try {
      await packService.installPack(
        languageCode: language.code,
        deviceId: 'mobile-device',
        installedVersion: '1.0.0',
      );
      await loadLanguagePacks(service: packService);
    } catch (_) {
      sessionError = 'Erreur installation pack.';
      notifyListeners();
    }
  }

  Future<void> uninstallLanguagePack(AppLanguage language) async {
    final packService = LanguagePackService(
      baseUrl: 'https://api.anla.mybestsejour.com',
      accessToken: backend.accessToken,
    );
    try {
      await packService.uninstallPack(language.code);
      await loadLanguagePacks(service: packService);
    } catch (_) {
      sessionError = 'Erreur désinstallation pack.';
      notifyListeners();
    }
  }

  // --- Profil ---
  Future<void> refreshAccount() async {
    try {
      profile = await backend.profile();
      _syncLanguagesWithProfile();
    } catch (_) {}
    notifyListeners();
  }

  // --- Mode Traducteur ---
  Future<void> toggleMic() async {
    if (isListening) {
      stopAllListening();
      return;
    }

    _isTranslateMode = true;

    try {
      if (!voiceService.isAvailable) {
        await voiceService.init(onError: _handleVoiceError);
      }
      if (!voiceService.isAvailable) throw Exception('Micro non disponible');
    } catch (e) {
      sessionError = e.toString();
      notifyListeners();
      return;
    }

    isListening = true;
    _isAutoRestarting = true;
    _startRecordingTimer();
    notifyListeners();

    await voiceService.startListening(
      localeId: sourceLang.speechLocale,
      onPartialResult: (text) {
        inputText = text;
        notifyListeners();
      },
      onResult: (text) async {
        if (!isListening) return;
        inputText = text;
        isListening = false;
        _isAutoRestarting = false;
        _stopRecordingTimer();
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 600));
        await translate();
      },
      onServiceError: () async {
        if (_isAutoRestarting) {
          await voiceService.reset();
          if (_isAutoRestarting) toggleMic();
        }
      }
    );
  }

  void _handleVoiceError(String err) {
    final low = err.toLowerCase();
    if (!_isAutoRestarting) return;
    if (low.contains('timeout') || low.contains('no match') || low.contains('error_speech_timeout')) {
      debugPrint("Auto-relaunching mic after error: $err");
      if (_isTranslateMode) {
        toggleMic();
      } else {
        toggleConversationMic();
      }
    }
  }

  Future<void> translate() async {
    if (inputText.trim().isEmpty) return;
    isTranslating = true;
    notifyListeners();

    // Synchronisation du token avant l'appel
    if (translationService is ApiTranslationService) {
      (translationService as ApiTranslationService).accessToken = backend.accessToken;
    }

    try {
      final result = await translationService.translate(
        text: inputText,
        sourceLangCode: sourceLang.code,
        targetLangCode: targetLang.code,
      );
      outputText = result;
      lastRecordedText = inputText;
      await _addToHistory(result);

      inputText = '';
      notifyListeners();

      await speakOutput();

      if (isAuthenticated && _isTranslateMode) await toggleMic();
    } catch (error) {
      debugPrint('Translation error: $error');
      outputText = 'Erreur de traduction.';
    } finally {
      isTranslating = false;
      notifyListeners();
    }
  }

  Future<void> speakOutput() async {
    if (outputText.trim().isEmpty) return;
    await voiceService.stopListening();
    await voiceService.speak(outputText, localeId: targetLang.speechLocale);
  }

  void clear() {
    inputText = '';
    outputText = '';
    notifyListeners();
  }

  // --- Mode Conversation Face-à-face ---
  Future<void> createConversation({
    required String title,
    required String secondSpeaker,
    required String secondSpeakerLang,
  }) async {
    isSessionLoading = true;
    notifyListeners();
    try {
      final firstSpeakerName = profile?.fullName ?? 'Moi';
      final firstSpeakerLang = profile?.preferredLanguage ?? 'fr';

      activeConversation = await backend.createSameDevice(
        title: title,
        sourceLanguage: firstSpeakerLang,
        targetLanguage: secondSpeakerLang,
        firstSpeakerName: firstSpeakerName,
        secondSpeakerName: secondSpeaker,
      );

      await loadConversations();
      await openConversation(activeConversation!);
      await startConversation();
    } catch (e) {
      sessionError = "Erreur création : $e";
    } finally {
      isSessionLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadConversations() async {
    conversations = await backend.conversations();
    notifyListeners();
  }

  Future<void> openConversation(Conversation conversation) async {
    activeConversation = conversation;
    final list = await backend.speakers(conversation.id);
    speakers = list.map((s) {
      if (conversation.activeSpeakerId.isNotEmpty) {
        return s.copyWith(active: s.id == conversation.activeSpeakerId);
      }
      return s;
    }).toList();

    if (speakers.isNotEmpty && !speakers.any((s) => s.active)) {
      await activateSpeaker(speakers.first);
    }

    await refreshTimeline();
    notifyListeners();
  }

  Future<void> activateSpeaker(Speaker speaker) async {
    if (activeConversation == null) return;
    await backend.activateSpeaker(activeConversation!.id, speaker.id);
    speakers = speakers.map((s) => s.copyWith(active: s.id == speaker.id)).toList();
    notifyListeners();
  }

  Future<void> toggleConversationMic() async {
    if (isListening) {
      stopAllListening();
      return;
    }

    if (activeConversation == null || speakers.isEmpty) return;

    _isTranslateMode = false;

    try {
      if (!voiceService.isAvailable) {
        await voiceService.init(onError: _handleVoiceError);
      }
    } catch (_) {}

    final activeSpeaker = speakers.firstWhere((s) => s.active, orElse: () => speakers.first);
    final isMe = speakers.indexOf(activeSpeaker) == 0;
    final langCode = isMe ? activeConversation!.sourceLanguage : activeConversation!.targetLanguage;

    final locale = AppLanguage.all.firstWhere(
      (l) => l.code == langCode,
      orElse: () => AppLanguage.french,
    ).speechLocale;

    isListening = true;
    _isAutoRestarting = true;
    _startRecordingTimer();
    notifyListeners();

    await voiceService.startListening(
      localeId: locale,
      onPartialResult: (text) {
        conversationInputText = text;
        notifyListeners();
      },
      onResult: (text) async {
        if (_conversationTurnInProgress || !_conversationScreenActive || _isTranslateMode) return;
        _conversationTurnInProgress = true;
        conversationInputText = text;
        isListening = false;
        _isAutoRestarting = false;
        _stopRecordingTimer();
        notifyListeners();

        if (text.trim().isEmpty) {
          _conversationTurnInProgress = false;
          await voiceService.reset();
          return;
        }

        try {
          await Future.delayed(const Duration(milliseconds: 800));
          if (_conversationScreenActive && !_isTranslateMode) {
            await processTextTurn(text);
          }
        } finally {
          _conversationTurnInProgress = false;
        }
      },
      onServiceError: () async {
        if (_isAutoRestarting && !_isTranslateMode) {
          isListening = false;
          _stopRecordingTimer();
          await voiceService.reset();
        }
      }
    );
  }

  Future<void> processTextTurn(String text) async {
    if (activeConversation == null || speakers.isEmpty || text.trim().isEmpty) return;

    final speaker = speakers.firstWhere((item) => item.active, orElse: () => speakers.first);
    final isMe = speakers.indexOf(speaker) == 0;
    final source = isMe ? activeConversation!.sourceLanguage : activeConversation!.targetLanguage;
    final target = isMe ? activeConversation!.targetLanguage : activeConversation!.sourceLanguage;

    // Position du tour
    final int turnIndex = timeline.length;
    _localOriginals[turnIndex] = text;
    lastRecordedText = text;
    conversationInputText = '';
    notifyListeners();

    String translated = '';
    try {
      final result = await backend.processTextTurn(activeConversation!.id, speaker.id, text, source, target);
      final payload = result is Map ? Map<String, dynamic>.from(result) : <String, dynamic>{};

      // Extraction améliorée de la traduction
      final data = payload['data'] ?? payload;
      final transObj = data['translation'] ?? data;
      translated = (transObj['translatedText'] ?? transObj['text'] ?? '').toString();
    } catch (e) {
      debugPrint("ProcessTextTurn error: $e");
    }

    if (speakers.length >= 2) {
      final nextSpeaker = speakers.firstWhere((s) => s.id != speaker.id);
      await activateSpeaker(nextSpeaker);
    }

    await refreshTimeline();

    // Secours si traduction vide
    if (translated.isEmpty && timeline.isNotEmpty) {
      final last = timeline.last;
      translated = (last['translatedText'] ?? last['translation']?['translatedText'] ?? '').toString();
    }

    if (translated.isNotEmpty) {
      await speakMessage(translated, target);
    }

    // Nettoyage complet
    await voiceService.reset();
    isListening = false;
    _stopRecordingTimer();
    notifyListeners();
  }

  Future<void> speakMessage(String text, String langCode) async {
    final locale = AppLanguage.all.firstWhere(
      (l) => l.code == langCode,
      orElse: () => AppLanguage.french,
    ).speechLocale;
    await voiceService.stopListening();
    await voiceService.speak(text, localeId: locale);
  }

  Future<void> refreshTimeline() async {
    if (activeConversation == null) return;
    timeline = await backend.timeline(activeConversation!.id);
    notifyListeners();
  }

  Future<void> deleteConversation(String id) async {
    await backend.deleteConversation(id);
    conversations.removeWhere((c) => c.id == id);
    if (activeConversation?.id == id) activeConversation = null;
    notifyListeners();
  }

  Future<void> startConversation() async => _lifecycle('start');
  Future<void> pauseConversation() async => _lifecycle('pause');
  Future<void> resumeConversation() async => _lifecycle('resume');
  Future<void> endConversation() async => _lifecycle('end');

  Future<void> _lifecycle(String action) async {
    if (activeConversation == null) return;
    await backend.lifecycle(activeConversation!.id, action);
    await loadConversations();
    try {
      activeConversation = conversations.firstWhere((c) => c.id == activeConversation!.id);
    } catch (_) {}
    await refreshTimeline();
  }

  // --- Historique ---
  final List<TranslationEntry> history = [];

  Future<void> _addToHistory(String translated) async {
    final entry = TranslationEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourceText: inputText,
      translatedText: translated,
      sourceLangCode: sourceLang.code,
      targetLangCode: targetLang.code,
      date: DateTime.now(),
    );
    history.insert(0, entry);
    await _persistHistory();
  }

  Future<void> toggleFavorite(String id) async {
    final idx = history.indexWhere((e) => e.id == id);
    if (idx != -1) {
      history[idx] = history[idx].copyWith(isFavorite: !history[idx].isFavorite);
      notifyListeners();
      await _persistHistory();
    }
  }

  Future<void> deleteHistoryEntry(String id) async {
    history.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persistHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('history') ?? [];
    history..clear()..addAll(raw.map((e) => TranslationEntry.fromJson(jsonDecode(e))));
    notifyListeners();
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('history', history.map((e) => jsonEncode(e.toJson())).toList());
  }

  // --- Thème ---
  ThemeMode themeMode = ThemeMode.system;
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('themeMode');
    if (saved == 'dark') themeMode = ThemeMode.dark;
    if (saved == 'light') themeMode = ThemeMode.light;
    notifyListeners();
  }
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
  }

  // --- Language Packs ---
  Future<void> loadLanguagePacks({LanguagePackService? service}) async {
    final packService = service ?? LanguagePackService(
      baseUrl: 'https://api.anla.mybestsejour.com',
      accessToken: backend.accessToken,
    );
    try {
      availableLanguagePacks = await packService.fetchPacks();
      recommendedLanguagePacks = await packService.fetchRecommendedPacks();
      installedLanguagePacks = await packService.fetchInstalledPacks();
    } catch (_) {}
    notifyListeners();
  }
}
