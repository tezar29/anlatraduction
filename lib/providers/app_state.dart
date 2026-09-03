import 'dart:convert';
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
  AppState(
      {required this.translationService,
      required this.voiceService,
      required this.backend});

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

  Future<void> login(String email, String password) async {
    isSessionLoading = true;
    sessionError = null;
    notifyListeners();
    try {
      final result = await backend.login(email, password);
      final accessToken = (result['accessToken'] ?? result['token'] ?? result['access_token'])?.toString();
      final incomingRefreshToken = (result['refreshToken'] ?? result['refresh_token'] ?? result['refreshTokenValue'])?.toString();

      if ((accessToken == null || accessToken.isEmpty) && (incomingRefreshToken == null || incomingRefreshToken.isEmpty)) {
        throw Exception('Aucun jeton d\'authentification reçu par le backend.');
      }

      backend.accessToken = accessToken ?? backend.accessToken;
      refreshToken = incomingRefreshToken?.isNotEmpty == true ? incomingRefreshToken : refreshToken;

      profile = null;
      entitlements = null;
      subscription = null;
      conversations = [];

      try {
        profile = await backend.profile();
      } catch (_) {}
      try {
        entitlements = await backend.entitlements();
      } catch (_) {}
      try {
        subscription = await backend.currentSubscription();
      } catch (_) {}
      try {
        conversations = await backend.conversations();
      } catch (_) {}

      isAuthenticated = true;
    } catch (error) {
      backend.accessToken = null;
      refreshToken = null;
      profile = null;
      entitlements = null;
      subscription = null;
      conversations = [];
      isAuthenticated = false;
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
      await backend.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        primaryLanguage: primaryLanguage,
        country: country,
        timezone: timezone,
      );
      backend.accessToken = null;
      refreshToken = null;
      profile = null;
      entitlements = null;
      subscription = null;
      conversations = [];
      isAuthenticated = false;
    } catch (error) {
      sessionError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isSessionLoading = false;
      notifyListeners();
    }
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

  Future<void> logout() async {
    if (refreshToken?.isNotEmpty == true) {
      try {
        await backend.logout(refreshToken!);
      } catch (_) {}
    }
    backend.accessToken = null;
    refreshToken = null;
    profile = null;
    entitlements = null;
    subscription = null;
    isAuthenticated = false;
    notifyListeners();
  }

  Future<void> refreshAccount() async {
    try {
      profile = await backend.profile();
      entitlements = await backend.entitlements();
      subscription = await backend.currentSubscription();
      availablePlans = await backend.plans();
      invoices = await backend.invoices();
      payments = await backend.payments();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadSubscriptionCatalog() async {
    try {
      availablePlans = await backend.plans();
      invoices = await backend.invoices();
      payments = await backend.payments();
    } catch (_) {}
    notifyListeners();
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
      await loadSubscriptionCatalog();
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
      await loadSubscriptionCatalog();
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

  Future<void> loadConversations() async {
    conversations = await backend.conversations();
    notifyListeners();
  }

  Future<void> createConversation(
      {required String title,
      required String firstSpeaker,
      required String secondSpeaker}) async {
    activeConversation = await backend.createSameDevice(
        title: title,
        sourceLanguage: 'fr',
        targetLanguage: 'tr',
        firstSpeakerName: firstSpeaker,
        secondSpeakerName: secondSpeaker);
    await openConversation(activeConversation!);
    await startConversation();
  }

  Future<void> openConversation(Conversation conversation) async {
    activeConversation = conversation;
    speakers = await backend.speakers(conversation.id);
    await refreshTimeline();
    notifyListeners();
  }

  Future<void> refreshTimeline() async {
    if (activeConversation == null) return;
    timeline = await backend.timeline(activeConversation!.id);
    conversationUsage = await backend.usage(activeConversation!.id);
    notifyListeners();
  }

  Future<void> startConversation() async {
    await _lifecycle('start');
  }

  Future<void> pauseConversation() async {
    await _lifecycle('pause');
  }

  Future<void> resumeConversation() async {
    await _lifecycle('resume');
  }

  Future<void> endConversation() async {
    await _lifecycle('end');
  }

  Future<void> _lifecycle(String action) async {
    if (activeConversation == null) return;
    await backend.lifecycle(activeConversation!.id, action);
    await refreshTimeline();
  }

  Future<void> activateSpeaker(Speaker speaker) async {
    if (activeConversation == null) return;
    await backend.activateSpeaker(activeConversation!.id, speaker.id);
    speakers = await backend.speakers(activeConversation!.id);
    notifyListeners();
  }

  Future<void> processTextTurn(String text) async {
    if (activeConversation == null || speakers.isEmpty || text.trim().isEmpty) {
      return;
    }
    final speaker = speakers.firstWhere((item) => item.active,
        orElse: () => speakers.first);
    await backend.processTextTurn(activeConversation!.id, speaker.id, text,
        activeConversation!.sourceLanguage, activeConversation!.targetLanguage);
    await refreshTimeline();
  }

  // --- Langues ---
  AppLanguage sourceLang = AppLanguage.turkish;
  AppLanguage targetLang = AppLanguage.french;

  void swapLanguages() {
    // Le turc reste toujours l'une des deux langues actives,
    // on échange simplement source <-> cible.
    final tmp = sourceLang;
    sourceLang = targetLang;
    targetLang = tmp;
    notifyListeners();
  }

  void setTargetLang(AppLanguage lang) {
    targetLang = lang;
    notifyListeners();
  }

  // --- Texte / traduction en cours ---
  String inputText = '';
  String outputText = '';
  bool isTranslating = false;
  bool isListening = false;

  void setInputText(String text) {
    inputText = text;
    notifyListeners();
  }

  Future<void> translate() async {
    if (inputText.trim().isEmpty) return;
    isTranslating = true;
    notifyListeners();

    try {
      final result = await translationService.translate(
        text: inputText,
        sourceLangCode: sourceLang.code,
        targetLangCode: targetLang.code,
      );
      outputText = result;
      await _addToHistory(result);
    } on Exception catch (error) {
      outputText = 'Erreur de traduction. Réessayez plus tard.';
      debugPrint('Translation error: $error');
    } finally {
      isTranslating = false;
      notifyListeners();
    }
  }

  Future<void> toggleMic() async {
    if (isListening) {
      await voiceService.stopListening();
      isListening = false;
      notifyListeners();
      return;
    }

    try {
      if (!voiceService.isAvailable) {
        await voiceService.init();
      }
      if (!voiceService.isAvailable) {
        sessionError = 'La synthèse vocale est indisponible sur cet appareil.';
        notifyListeners();
        return;
      }
    } catch (_) {
      sessionError = 'La synthèse vocale est indisponible sur cet appareil.';
      notifyListeners();
      return;
    }

    isListening = true;
    notifyListeners();
    await voiceService.startListening(
      localeId: sourceLang.speechLocale,
      onResult: (text) {
        inputText = text;
        notifyListeners();
      },
    );
  }

  Future<void> speakOutput() async {
    if (outputText.trim().isEmpty) return;
    try {
      if (!voiceService.isAvailable) {
        await voiceService.init();
      }
      if (!voiceService.isAvailable) return;
      await voiceService.speak(outputText, localeId: targetLang.speechLocale);
    } catch (_) {
      // Fail silently to keep guest and non-supported flows usable.
    }
  }

  void clear() {
    inputText = '';
    outputText = '';
    notifyListeners();
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
    final index = history.indexWhere((e) => e.id == id);
    if (index == -1) return;
    history[index] = history[index].copyWith(
      isFavorite: !history[index].isFavorite,
    );
    notifyListeners();
    await _persistHistory();
  }

  Future<void> deleteHistoryEntry(String id) async {
    history.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persistHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('history') ?? [];
    history
      ..clear()
      ..addAll(raw.map((e) => TranslationEntry.fromJson(jsonDecode(e))));
    notifyListeners();
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'history',
      history.map((e) => jsonEncode(e.toJson())).toList(),
    );
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

  Future<void> createGuestSession({
    required String deviceId,
    required String displayName,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final service = GuestSessionService(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.anla.mybestsejour.com',
      ),
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

  Future<void> refreshGuestSession() async {
    if (guestSession == null) return;
    final service = GuestSessionService(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.anla.mybestsejour.com',
      ),
    );
    try {
      guestSession = await service.refreshSession(guestSession!.id);
      guestDailyUsage = await service.getDailyUsage(guestSession!.id);
      notifyListeners();
    } catch (_) {
      sessionError = 'Impossible de rafraîchir la session invitée.';
      notifyListeners();
    }
  }

  Future<void> claimGuestSession() async {
    if (guestSession == null) return;
    final service = GuestSessionService(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.anla.mybestsejour.com',
      ),
    );
    try {
      guestSession = await service.claimSession(guestSession!.id);
      notifyListeners();
    } catch (_) {
      sessionError = 'Impossible de rattacher la session invitée à votre compte.';
      notifyListeners();
    }
  }

  Future<void> loadGuestDailyUsage() async {
    if (guestSession == null) return;
    final service = GuestSessionService(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.anla.mybestsejour.com',
      ),
    );
    try {
      guestDailyUsage = await service.getDailyUsage(guestSession!.id);
      notifyListeners();
    } catch (_) {
      guestDailyUsage = {};
      notifyListeners();
    }
  }

  Future<void> loadLanguagePacks({LanguagePackService? service}) async {
    final packService = service ??
        LanguagePackService(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'https://api.anla.mybestsejour.com',
          ),
          accessToken: backend.accessToken,
        );

    try {
      availableLanguagePacks = await packService.fetchPacks();
      recommendedLanguagePacks = await packService.fetchRecommendedPacks();
      installedLanguagePacks = await packService.fetchInstalledPacks();

      final installedCodes = installedLanguagePacks
          .map((entry) => entry.languageCode.toLowerCase())
          .toSet();
      final recommendedCodes = recommendedLanguagePacks
          .map((entry) => entry.code.toLowerCase())
          .toSet();

      final allLanguages = AppLanguage.all.map((lang) {
        final matchingPack = availableLanguagePacks.firstWhere(
          (pack) => pack.code.toLowerCase() == lang.code.toLowerCase(),
          orElse: () => const LanguagePack(),
        );
        final isInstalled = installedCodes.contains(lang.code.toLowerCase()) ||
            (matchingPack.code.isNotEmpty && matchingPack.offlineAvailable);

        return AppLanguage(
          code: lang.code,
          label: lang.label,
          flagEmoji: lang.flagEmoji,
          speechLocale: lang.speechLocale,
          isPackInstalled: isInstalled,
          isRecommended: recommendedCodes.contains(lang.code.toLowerCase()),
        );
      }).toList();

      if (allLanguages.isNotEmpty) {
        final sourceMatch = allLanguages.firstWhere(
          (lang) => lang.code == sourceLang.code,
          orElse: () => allLanguages.first,
        );
        final targetMatch = allLanguages.firstWhere(
          (lang) => lang.code == targetLang.code,
          orElse: () => allLanguages.first,
        );
        sourceLang = sourceMatch;
        targetLang = targetMatch;
      }
    } catch (_) {
      // Keep the default app languages if the API is unavailable.
    }

    notifyListeners();
  }

  Future<void> installLanguagePack(AppLanguage language) async {
    final packService = LanguagePackService(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.anla.mybestsejour.com',
      ),
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
      sessionError = 'Impossible d\'installer le pack de langue.';
      notifyListeners();
    }
  }

  Future<void> uninstallLanguagePack(AppLanguage language) async {
    final packService = LanguagePackService(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.anla.mybestsejour.com',
      ),
      accessToken: backend.accessToken,
    );

    try {
      await packService.uninstallPack(language.code);
      await loadLanguagePacks(service: packService);
      sessionError = null;
    } catch (_) {
      sessionError = 'Impossible de désinstaller le pack de langue.';
      notifyListeners();
    }
  }
}
