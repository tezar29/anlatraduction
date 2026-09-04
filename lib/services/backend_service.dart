import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/backend_models.dart';

class BackendService {
  BackendService({required this.baseUrl, this.accessToken});

  final String baseUrl;
  String? accessToken;

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/api/v1$path');
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...queryParameters,
    });
  }

  Map<String, dynamic> _normalizeJson(dynamic value) {
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  String? _pickString(Map<String, dynamic> payload, List<String> keys) {
    final pending = <Map<String, dynamic>>[payload];
    while (pending.isNotEmpty) {
      final current = pending.removeAt(0);
      for (final key in keys) {
        final value = current[key];
        if (value is String && value.trim().isNotEmpty) return value;
      }
      for (final value in current.values) {
        if (value is Map) {
          pending.add(Map<String, dynamic>.from(value));
        } else if (value is List) {
          for (final item in value) {
            if (item is Map) {
              pending.add(Map<String, dynamic>.from(item));
            }
          }
        }
      }
    }
    return null;
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (accessToken?.isNotEmpty == true)
        'Authorization': 'Bearer $accessToken',
    };

    final request = http.Request(method, _uri(path, query))..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    final client = http.Client();
    try {
      final response = await client.send(request);
      final text = await response.stream.bytesToString();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final payload = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
        final normalized = _normalizeJson(payload);
        var message = normalized['message'] ?? normalized['error'];
        if (message is List) message = message.join(', ');
        throw Exception(message ?? 'Erreur API (${response.statusCode})');
      }
      if (text.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(text);
      return decoded is Map ? _normalizeJson(decoded) : decoded;
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Erreur API: $error');
    } finally {
      client.close();
    }
  }

  // --- Auth ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await _request(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    final payload = _normalizeJson(result);
    final nested = _normalizeJson(payload['data']);
    final map = {
      ...nested,
      ...payload,
    };

    final accessToken = _pickString(map, ['accessToken', 'token', 'access_token']);
    final refreshToken =
        _pickString(map, ['refreshToken', 'refresh_token', 'refreshTokenValue']);

    return {
      ...map,
      if (accessToken != null) 'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
    };
  }

  static Map<String, dynamic> buildRegisterPayload({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String primaryLanguage,
    required String country,
    required String timezone,
  }) {
    final fn = firstName.trim();
    final ln = lastName.trim();
    final full = '$fn $ln'.trim();
    
    return {
      'email': email.trim(),
      'password': password,
      'firstName': fn,
      'lastName': ln,
      'fullName': full,
      'name': full,
      'primaryLanguage': primaryLanguage.trim().isNotEmpty ? primaryLanguage.trim() : 'fr',
      'preferredLanguage': primaryLanguage.trim().isNotEmpty ? primaryLanguage.trim() : 'fr',
      'country': country.trim(),
      'countryCode': country.trim(),
      'timezone': timezone.trim(),
    };
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String primaryLanguage,
    required String country,
    required String timezone,
  }) async {
    final payload = buildRegisterPayload(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      primaryLanguage: primaryLanguage,
      country: country,
      timezone: timezone,
    );

    final result = await _request('POST', '/auth/register', body: payload);
    return _normalizeJson(result);
  }

  Future<void> resendVerification({required String email}) => _request(
        'POST',
        '/auth/resend-verification',
        body: {'email': email.trim()},
      );

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final result = await _request(
      'POST',
      '/auth/verify-email',
      body: {'email': email.trim(), 'code': code.trim()},
    );
    return _normalizeJson(result);
  }

  Future<void> forgotPassword({required String email}) => _request(
        'POST',
        '/auth/forgot-password',
        body: {'email': email.trim()},
      );

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _request(
        'POST',
        '/auth/reset-password',
        body: {
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword,
        },
      );

  Future<void> logout(String refreshToken) => _request(
        'POST',
        '/auth/logout',
        body: {'refreshToken': refreshToken},
      );

  // --- Profil ---
  Future<UserProfile> profile() async => UserProfile.fromJson(
        (await _request('GET', '/users/me') as Map).cast<String, dynamic>(),
      );

  Future<Entitlements> entitlements() async => Entitlements.fromJson(
        (await _request('GET', '/subscriptions/me/entitlements') as Map)
            .cast<String, dynamic>(),
      );

  Future<UserSubscription> currentSubscription() async => UserSubscription.fromJson(
        (await _request('GET', '/subscriptions/me/current') as Map)
            .cast<String, dynamic>(),
      );

  Future<UserProfile> updateProfile({
    String? fullName,
    String? preferredLanguage,
    String? country,
    String? timezone,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (preferredLanguage != null) body['preferredLanguage'] = preferredLanguage;
    if (country != null) body['country'] = country;
    if (timezone != null) body['timezone'] = timezone;

    final result = await _request('PATCH', '/users/me', body: body);
    return UserProfile.fromJson(_normalizeJson(result));
  }

  // --- Conversations (Capture 20) ---
  Future<List<Conversation>> conversations({String? status}) async {
    final result = await _request(
      'GET', 
      '/conversations',
      query: status != null ? {'status': status} : null,
    );
    return _asMapList(result)
        .map<Conversation>((e) => Conversation.fromJson(e))
        .toList();
  }

  Future<List<Conversation>> searchConversations(String query) async {
    final result = await _request(
      'GET',
      '/conversations/search',
      query: {'query': query},
    );
    return _asMapList(result)
        .map<Conversation>((e) => Conversation.fromJson(e))
        .toList();
  }

  Future<Conversation> getConversation(String id) async {
    final result = await _request('GET', '/conversations/$id');
    return Conversation.fromJson(_normalizeJson(result));
  }

  Future<void> deleteConversation(String id) => _request('DELETE', '/conversations/$id');

  Future<void> archiveConversation(String id) => _request('POST', '/conversations/$id/archive');

  // --- Same Device (Captures 21-26) ---
  Future<Conversation> createSameDevice({
    required String title,
    required String sourceLanguage,
    required String targetLanguage,
    required String firstSpeakerName,
    required String secondSpeakerName,
  }) async {
    final result = await _request(
      'POST',
      '/conversations/same-device',
      body: {
        'title': title,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
        'firstSpeakerName': firstSpeakerName,
        'secondSpeakerName': secondSpeakerName,
      },
    );
    return Conversation.fromJson(_normalizeJson(result));
  }

  Future<List<Speaker>> speakers(String id) async {
    final result = await _request('GET', '/conversations/$id/same-device/speakers');
    return _asMapList(result)
        .map<Speaker>((e) => Speaker.fromJson(e))
        .toList();
  }

  Future<void> lifecycle(String id, String action) => 
      _request('POST', '/conversations/$id/same-device/$action');

  Future<void> activateSpeaker(String conversationId, String speakerId) =>
      _request(
        'POST',
        '/conversations/$conversationId/same-device/speakers/$speakerId/activate',
      );

  Future<Speaker> addSpeaker(String conversationId, {
    required String participantId,
    required String label,
    String detectedLanguage = 'fr',
  }) async {
    final result = await _request(
      'POST',
      '/conversations/$conversationId/speakers',
      body: {
        'participantId': participantId,
        'label': label,
        'detectedLanguage': detectedLanguage,
        'status': 'ACTIVE',
      },
    );
    return Speaker.fromJson(_normalizeJson(result));
  }

  Future<dynamic> processTextTurn(
    String conversationId,
    String speakerId,
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) =>
      _request(
        'POST',
        '/conversations/$conversationId/same-device/process-text-turn',
        body: {
          'speakerId': speakerId,
          'text': text,
          'sourceLanguage': sourceLanguage,
          'targetLanguage': targetLanguage,
        },
      );

  Future<dynamic> processTurn({
    required String conversationId,
    required String speakerId,
    required String audioUri,
    required String sourceLanguage,
    required String targetLanguage,
    int audioDurationMs = 0,
    int audioBytes = 0,
  }) => _request(
    'POST',
    '/conversations/$conversationId/same-device/process-turn',
    body: {
      'speakerId': speakerId,
      'audioUri': audioUri,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'audioDurationMs': audioDurationMs,
      'audioBytes': audioBytes,
    },
  );

  Future<List<Map<String, dynamic>>> timeline(String id) async {
    final result = await _request('GET', '/conversations/$id/same-device/timeline');
    return _mapList(result);
  }

  Future<Map<String, dynamic>> usage(String id) async =>
      _normalizeJson(await _request('GET', '/conversations/$id/same-device/usage'));

  /// GET /conversations/{id}/same-device/turn-policy
  /// Source de vérité côté serveur pour savoir qui doit parler : mode
  /// (MANUAL/AUTO_ALTERNATE), locuteur actif, et prochain locuteur attendu.
  Future<Map<String, dynamic>> turnPolicy(String id) async =>
      _normalizeJson(await _request('GET', '/conversations/$id/same-device/turn-policy'));

  /// PATCH /conversations/{id}/same-device/turn-policy — change le mode
  /// (ex: "AUTO_ALTERNATE" pour que le tour de parole avance tout seul).
  Future<Map<String, dynamic>> updateTurnPolicy(String id, String mode) async =>
      _normalizeJson(await _request(
        'PATCH',
        '/conversations/$id/same-device/turn-policy',
        body: {'mode': mode},
      ));

  /// PATCH /conversations/{id}/same-device/speakers/{speakerId}/display
  /// Enregistre côté serveur l'affichage d'un locuteur dans l'écran
  /// face-à-face (couleur, position).
  Future<Map<String, dynamic>> updateSpeakerDisplay(
    String id,
    String speakerId, {
    required String displayColor,
    required String displayPosition,
  }) async =>
      _normalizeJson(await _request(
        'PATCH',
        '/conversations/$id/same-device/speakers/$speakerId/display',
        body: {
          'displayColor': displayColor,
          'displayPosition': displayPosition,
        },
      ));

  /// GET /conversations/{id}/speakers/usage — métriques voix/silence.
  Future<Map<String, dynamic>> speakersUsage(String id) async =>
      _normalizeJson(await _request('GET', '/conversations/$id/speakers/usage'));

  /// POST /conversations/{id}/messages — enregistre le message complet
  /// (texte original + traduction déjà connue) pour une conversation.
  Future<Map<String, dynamic>> addMessage(
    String id, {
    required String participantId,
    required String originalText,
    required String sourceLanguage,
    required String targetLanguage,
    String translatedText = '',
    String type = 'TEXT',
    String detectedLanguage = '',
    double transcriptionConfidence = 0,
    double translationConfidence = 0,
    int audioDurationMs = 0,
    int audioBytes = 0,
  }) async =>
      _normalizeJson(await _request(
        'POST',
        '/conversations/$id/messages',
        body: {
          'participantId': participantId,
          'type': type,
          'originalText': originalText,
          'translatedText': translatedText,
          'sourceLanguage': sourceLanguage,
          'targetLanguage': targetLanguage,
          if (detectedLanguage.isNotEmpty) 'detectedLanguage': detectedLanguage,
          'transcriptionConfidence': transcriptionConfidence,
          'translationConfidence': translationConfidence,
          'audioDurationMs': audioDurationMs,
          'audioBytes': audioBytes,
        },
      ));

  /// POST /conversations/{id}/speakers/turns — enregistre un tour de
  /// parole côté serveur (utile notamment pour que l'alternance AUTO
  /// avance correctement). Best-effort : les valeurs non connues côté
  /// client (timing précis, confiance) sont envoyées à 0/1 par défaut.
  Future<Map<String, dynamic>> addSpeakerTurn(
    String id, {
    required String speakerId,
    String participantId = '',
    String messageId = '',
    int turnIndex = 0,
    int startMs = 0,
    int endMs = 0,
    double confidence = 1,
  }) async =>
      _normalizeJson(await _request(
        'POST',
        '/conversations/$id/speakers/turns',
        body: {
          'speakerId': speakerId,
          'participantId': participantId.isNotEmpty ? participantId : speakerId,
          if (messageId.isNotEmpty) 'messageId': messageId,
          'turnIndex': turnIndex,
          'startMs': startMs,
          'endMs': endMs,
          'confidence': confidence,
        },
      ));

  // --- Abonnements ---
  Future<List<SubscriptionPlan>> plans() async {
    final result = await _request('GET', '/subscriptions/plans');
    return _asMapList(result)
        .map<SubscriptionPlan>((e) => SubscriptionPlan.fromJson(e))
        .toList();
  }

  Future<UserSubscription> changePlan(String planCode) async {
    final result = await _request(
      'POST',
      '/subscriptions/me/change-plan',
      body: {'planCode': planCode},
    );
    return UserSubscription.fromJson(_normalizeJson(result));
  }

  Future<UserSubscription> cancelSubscription() async {
    final result = await _request('POST', '/subscriptions/me/cancel');
    return UserSubscription.fromJson(_normalizeJson(result));
  }

  Future<UserSubscription> renewSubscription() async {
    final result = await _request('POST', '/subscriptions/me/renew');
    return UserSubscription.fromJson(_normalizeJson(result));
  }

  // --- Facturation ---
  Future<BillingInvoice> createInvoice({String? subscriptionId}) async {
    final result = await _request(
      'POST',
      '/billing/invoices',
      body: subscriptionId != null ? {'subscriptionId': subscriptionId} : {},
    );
    return BillingInvoice.fromJson(_normalizeJson(result));
  }

  Future<List<BillingInvoice>> invoices() async {
    final result = await _request('GET', '/billing/invoices');
    return _asMapList(result)
        .map<BillingInvoice>((e) => BillingInvoice.fromJson(e))
        .toList();
  }

  Future<PaymentRecord> createPayment({
    required String invoiceId,
    String provider = 'stripe',
    String? providerReference,
    num amount = 0,
    String currency = 'EUR',
  }) async {
    final result = await _request(
      'POST',
      '/billing/payments',
      body: {
        'invoiceId': invoiceId,
        'provider': provider,
        if (providerReference != null) 'providerReference': providerReference,
        'amount': amount,
        'currency': currency,
      },
    );
    return PaymentRecord.fromJson(_normalizeJson(result));
  }

  Future<List<PaymentRecord>> payments() async {
    final result = await _request('GET', '/billing/payments');
    return _asMapList(result)
        .map<PaymentRecord>((e) => PaymentRecord.fromJson(e))
        .toList();
  }

  Future<PaymentRecord> confirmPayment(String paymentId) async {
    final result = await _request('POST', '/billing/payments/$paymentId/confirm');
    return PaymentRecord.fromJson(_normalizeJson(result));
  }

  // --- Utilitaires ---
  List<Map<String, dynamic>> _mapList(dynamic result) => _asMapList(result);

  List<Map<String, dynamic>> _asMapList(dynamic result) {
    List<dynamic> list;
    if (result is List) {
      list = result;
    } else if (result is Map) {
      final nested = result['items'] ?? result['data'] ?? result['content'] ?? [];
      if (nested is Map) return _asMapList(nested);
      list = nested is List ? nested : <dynamic>[];
    } else {
      list = <dynamic>[];
    }
    return list
        .whereType<Map>()
        .map<Map<String, dynamic>>((e) => e.cast<String, dynamic>())
        .toList();
  }
}
