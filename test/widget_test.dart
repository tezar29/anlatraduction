import 'package:flutter_test/flutter_test.dart';
import 'package:transturc/main.dart';
import 'package:transturc/models/backend_models.dart';
import 'package:transturc/providers/app_state.dart';
import 'package:transturc/services/backend_service.dart';
import 'package:transturc/services/translation_service.dart';
import 'package:transturc/services/voice_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TranslationApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Continuer en invité'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
  });

  test('Login stays valid when optional subscription data is unavailable', () async {
    final state = AppState(
      translationService: const MockTranslationService(),
      voiceService: VoiceService(),
      backend: _TestBackendService(),
    );

    await state.login('user@example.com', 'password');

    expect(state.isAuthenticated, isTrue);
    expect(state.sessionError, isNull);
    expect(state.profile?.email, 'user@example.com');
  });

  test('User profile and subscription payloads are parsed correctly', () {
    final profile = UserProfile.fromJson({
      'id': 'abc',
      'email': 'user@example.com',
      'fullName': 'Jane Doe',
      'preferredLanguage': 'fr',
      'country': 'FR',
      'timezone': 'Europe/Paris',
      'emailVerified': true,
    });

    expect(profile.fullName, 'Jane Doe');
    expect(profile.country, 'FR');
    expect(profile.emailVerified, isTrue);

    final subscription = UserSubscription.fromJson({
      'id': 'sub-1',
      'userId': 'user-1',
      'status': 'PENDING',
      'plan': {
        'id': 'plan-1',
        'code': 'PRO',
        'name': 'Pro',
        'description': 'Premium',
        'priceAmount': 19,
        'currency': 'USD',
        'billingPeriod': 'MONTHLY',
        'audioMinutesLimit': 120,
        'translatedCharactersLimit': 50000,
        'ttsCharactersLimit': 50000,
        'conversationsLimit': 20,
      },
      'currentPeriodStart': '2026-08-29T11:55:54.913Z',
      'currentPeriodEnd': '2026-08-29T11:55:54.913Z',
      'trialEnd': '2026-08-29T11:55:54.913Z',
      'canceledAt': null,
      'createdAt': '2026-08-29T11:55:54.913Z',
      'updatedAt': '2026-08-29T11:55:54.913Z',
    });

    expect(subscription.plan.code, 'PRO');
    expect(subscription.plan.audioMinutesLimit, 120);
    expect(subscription.status, 'PENDING');
  });

  test('Conversation payloads match the backend contract', () {
    final conversation = Conversation.fromJson({
      'id': 'conv-1',
      'ownerId': 'user-1',
      'title': 'Conversation face-à-face',
      'sourceLanguage': 'fr',
      'targetLanguage': 'tr',
      'status': 'CREATED',
      'mode': 'same_device',
      'activeSpeakerId': 'speaker-1',
      'startedAt': '2026-08-30T08:00:00.000Z',
      'endedAt': null,
    });

    expect(conversation.id, 'conv-1');
    expect(conversation.title, 'Conversation face-à-face');
    expect(conversation.status, 'CREATED');
    expect(conversation.sourceLanguage, 'fr');
    expect(conversation.targetLanguage, 'tr');

    final nestedConversation = Conversation.fromJson({
      'data': {
        'id': 'conv-2',
        'ownerId': 'user-2',
        'title': 'Other conversation',
        'sourceLanguage': 'en',
        'targetLanguage': 'fr',
        'status': 'ACTIVE',
      }
    });

    expect(nestedConversation.id, 'conv-2');
    expect(nestedConversation.status, 'ACTIVE');
  });

  test('Registration payload is compatible with the backend contract', () {
    final payload = BackendService.buildRegisterPayload(
      email: ' jane@example.com ',
      password: 'Password123!',
      firstName: 'Jane ',
      lastName: ' Doe',
      primaryLanguage: ' fr ',
      country: ' FR ',
      timezone: ' Europe/Paris ',
    );

    expect(payload['email'], 'jane@example.com');
    expect(payload['password'], 'Password123!');
    expect(payload['firstName'], 'Jane');
    expect(payload['lastName'], 'Doe');
    expect(payload['fullName'], 'Jane Doe');
    expect(payload['name'], 'Jane Doe');
    expect(payload['preferredLanguage'], 'fr');
    expect(payload['primaryLanguage'], 'fr');
    expect(payload['country'], 'FR');
    expect(payload['countryCode'], 'FR');
    expect(payload['timezone'], 'Europe/Paris');
    expect(payload['timeZone'], 'Europe/Paris');
  });

  test('Translation API payload matches backend contract', () {
    final request = ApiTranslationService.buildRequestBody(
      text: 'Bonjour',
      sourceLangCode: 'fr',
      targetLangCode: 'tr',
      conversationId: 'conv-1',
      messageId: 'msg-1',
    );

    expect(request['text'], 'Bonjour');
    expect(request['sourceLanguage'], 'fr');
    expect(request['targetLanguage'], 'tr');
    expect(request['conversationId'], 'conv-1');
    expect(request['messageId'], 'msg-1');

    final translated = ApiTranslationService.extractTranslatedText({
      'id': 'id-1',
      'conversationId': 'conv-1',
      'messageId': 'msg-1',
      'translatedText': 'Merhaba',
      'sourceLanguage': 'fr',
      'targetLanguage': 'tr',
    });

    expect(translated, 'Merhaba');

    final nestedTranslated = ApiTranslationService.extractTranslatedText({
      'data': {'translatedText': 'Merhaba'}
    });

    expect(nestedTranslated, 'Merhaba');
  });

  test('Language packs payloads match the backend contract', () {
    final pack = LanguagePack.fromJson({
      'code': 'tr',
      'name': 'Turc',
      'nativeName': 'Türkçe',
      'description': 'Pack offline turc',
      'version': '1.2.3',
      'offlineAvailable': true,
      'recommended': true,
    });

    expect(pack.code, 'tr');
    expect(pack.name, 'Turc');
    expect(pack.offlineAvailable, isTrue);
    expect(pack.recommended, isTrue);

    final installation = LanguagePackInstallation.fromJson({
      'id': 'inst-1',
      'userId': 'user-1',
      'languageCode': 'tr',
      'deviceId': 'device-1',
      'installedVersion': '1.2.3',
      'installedAt': '2026-08-30T10:31:38.110Z',
    });

    expect(installation.languageCode, 'tr');
    expect(installation.deviceId, 'device-1');
    expect(installation.installedAt, isNotNull);
  });

  test('TTS payloads match the backend contract', () {
    final generation = TtsGeneration.fromJson({
      'id': 'tts-1',
      'conversationId': 'conv-1',
      'messageId': 'msg-1',
      'provider': 'azure',
      'inputText': 'Bonjour',
      'languageCode': 'fr',
      'voiceName': 'fr-FR-JennyNeural',
      'voiceGender': 'female',
      'speakingRate': 0,
      'pitch': 0,
      'audioFormat': 'mp3',
      'audioUri': 'https://cdn.example.com/audio.mp3',
      'audioBase64': 'UklGRiQAAABXQVZFZm10',
      'status': 'COMPLETED',
      'createdAt': '2026-08-30T10:31:38.110Z',
    });

    expect(generation.conversationId, 'conv-1');
    expect(generation.messageId, 'msg-1');
    expect(generation.audioUri, 'https://cdn.example.com/audio.mp3');
    expect(generation.audioBase64, startsWith('UklGRiQAAABXQVZFZm10'));
    expect(generation.status, 'COMPLETED');
    expect(generation.createdAt, isNotNull);
  });

  test('Nested backend payloads are unwrapped before model parsing', () {
    final profile = UserProfile.fromJson({
      'data': {
        'id': 'abc',
        'email': 'nested@example.com',
        'fullName': 'Nested User',
        'preferredLanguage': 'en',
        'country': 'GB',
        'timezone': 'Europe/London',
        'emailVerified': true,
      }
    });

    expect(profile.email, 'nested@example.com');
    expect(profile.fullName, 'Nested User');
    expect(profile.country, 'GB');

    final entitlements = Entitlements.fromJson({
      'data': {
        'planCode': 'BUSINESS',
        'limits': {'audioMinutes': 300},
        'features': {'translation': true},
      }
    });

    expect(entitlements.planCode, 'BUSINESS');
    expect(entitlements.limits['audioMinutes'], 300);

    final subscription = UserSubscription.fromJson({
      'data': {
        'subscription': {
          'id': 'sub-2',
          'userId': 'user-2',
          'status': 'ACTIVE',
          'plan': {
            'code': 'BUSINESS',
            'name': 'Business',
            'audioMinutesLimit': 300,
            'translatedCharactersLimit': 200000,
            'ttsCharactersLimit': 200000,
            'conversationsLimit': 50,
          },
        }
      }
    });

    expect(subscription.status, 'ACTIVE');
    expect(subscription.plan.code, 'BUSINESS');
    expect(subscription.plan.conversationsLimit, 50);

    final invoice = BillingInvoice.fromJson({
      'data': {
        'id': 'inv-1',
        'subscriptionId': 'sub-2',
        'amount': 19.0,
        'currency': 'USD',
        'status': 'PAID',
      }
    });

    expect(invoice.amount, 19.0);
    expect(invoice.status, 'PAID');

    final payment = PaymentRecord.fromJson({
      'data': {
        'id': 'pay-1',
        'invoiceId': 'inv-1',
        'provider': 'stripe',
        'providerReference': 'ref-1',
        'amount': 19.0,
        'currency': 'USD',
        'status': 'CONFIRMED',
      }
    });

    expect(payment.provider, 'stripe');
    expect(payment.status, 'CONFIRMED');
  });
}

class _TestBackendService extends BackendService {
  _TestBackendService() : super(baseUrl: 'https://example.com');

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    return {'accessToken': 'demo-token', 'refreshToken': 'demo-refresh'};
  }

  @override
  Future<UserProfile> profile() async {
    return const UserProfile(
      id: 'user-1',
      email: 'user@example.com',
      fullName: 'Jane Doe',
      preferredLanguage: 'fr',
      country: 'FR',
      timezone: 'Europe/Paris',
      emailVerified: true,
    );
  }

  @override
  Future<Entitlements> entitlements() async {
    return const Entitlements(planCode: 'FREE');
  }

  @override
  Future<UserSubscription> currentSubscription() async {
    throw Exception('404 not found');
  }

  @override
  Future<List<Conversation>> conversations({String? status}) async => const [];
}

class MockTranslationService implements TranslationService {
  const MockTranslationService();

  @override
  Future<String> translate({
    required String text,
    required String sourceLangCode,
    required String targetLangCode,
    String? conversationId,
    String? messageId,
  }) async => 'translation';
}
