import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/backend_models.dart';

class BackendService {
  BackendService({required this.baseUrl, this.accessToken});

  final String baseUrl;
  String? accessToken;

  Uri _uri(String path) => Uri.parse(
        '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/api/v1$path',
      );

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
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (accessToken?.isNotEmpty == true)
        'Authorization': 'Bearer $accessToken',
    };

    final request = http.Request(method, _uri(path))..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    final client = http.Client();
    try {
      final response = await client.send(request);
      final text = await response.stream.bytesToString();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final payload = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
        final message = _normalizeJson(payload)['message'] ??
            _normalizeJson(payload)['error'] ??
            'Erreur API (${response.statusCode})';
        throw Exception(message);
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

    if (accessToken == null && refreshToken == null) {
      return map;
    }

    return {
      ...map,
      if (accessToken != null) 'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
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
    final fullName = [firstName.trim(), lastName.trim()]
        .where((value) => value.isNotEmpty)
        .join(' ');

    final payload = {
      'email': email.trim(),
      'password': password,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'fullName': fullName,
      'primaryLanguage': primaryLanguage.trim().isNotEmpty ? primaryLanguage.trim() : 'fr',
      'preferredLanguage': primaryLanguage.trim().isNotEmpty ? primaryLanguage.trim() : 'fr',
      'country': country.trim(),
      'timezone': timezone.trim(),
    };

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

  Future<List<SubscriptionPlan>> plans() async {
    final result = await _request('GET', '/subscriptions/plans');
    return _asMapList(result)
        .map<SubscriptionPlan>((e) => SubscriptionPlan.fromJson(e))
        .toList();
  }

  Future<List<LanguagePack>> languagePacks() async {
    final result = await _request('GET', '/packs-langues');
    return _asMapList(result)
        .map<LanguagePack>((e) => LanguagePack.fromJson(e))
        .toList();
  }

  Future<LanguagePack> languagePack(String languageCode) async {
    final result = await _request('GET', '/packs-langues/$languageCode');
    return LanguagePack.fromJson(_normalizeJson(result));
  }

  Future<List<LanguagePack>> recommendedLanguagePacks() async {
    final result = await _request('GET', '/packs-langues/recommendations');
    return _asMapList(result)
        .map<LanguagePack>((e) => LanguagePack.fromJson(e))
        .toList();
  }

  Future<List<LanguagePackInstallation>> installedLanguagePacks() async {
    final result = await _request('GET', '/packs-langues/installations');
    return _asMapList(result)
        .map<LanguagePackInstallation>((e) => LanguagePackInstallation.fromJson(e))
        .toList();
  }

  Future<LanguagePackInstallation> installLanguagePack(
    String languageCode, {
    required String deviceId,
    required String installedVersion,
  }) async {
    final result = await _request(
      'POST',
      '/packs-langues/$languageCode/installations',
      body: {
        'deviceId': deviceId,
        'installedVersion': installedVersion,
      },
    );
    return LanguagePackInstallation.fromJson(_normalizeJson(result));
  }

  Future<void> uninstallLanguagePack(String languageCode) => _request(
        'DELETE',
        '/packs-langues/$languageCode/installations',
      );

  Future<void> syncLanguagePackMetadata(Map<String, dynamic> metadata) => _request(
        'POST',
        '/offline/sync-metadata',
        body: metadata,
      );

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

  Future<BillingInvoice> invoice(String invoiceId) async {
    final result = await _request('GET', '/billing/invoices/$invoiceId');
    return BillingInvoice.fromJson(_normalizeJson(result));
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

  Future<PaymentRecord> failPayment(String paymentId) async {
    final result = await _request('POST', '/billing/payments/$paymentId/fail');
    return PaymentRecord.fromJson(_normalizeJson(result));
  }

  Future<PaymentRecord> refundPayment(String paymentId) async {
    final result = await _request('POST', '/billing/payments/$paymentId/refund');
    return PaymentRecord.fromJson(_normalizeJson(result));
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

  Future<List<Conversation>> conversations() async {
    final result = await _request('GET', '/conversations');
    return _asMapList(result)
        .map<Conversation>((e) => Conversation.fromJson(e))
        .toList();
  }

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
    return Conversation.fromJson((result as Map).cast<String, dynamic>());
  }

  Future<List<Speaker>> speakers(String id) async {
    final result = await _request(
      'GET',
      '/conversations/$id/same-device/speakers',
    );
    return _asMapList(result)
        .map<Speaker>((e) => Speaker.fromJson(e))
        .toList();
  }

  Future<void> lifecycle(String id, String action) => _request(
        'POST',
        '/conversations/$id/same-device/$action',
      );

  Future<void> activateSpeaker(String conversationId, String speakerId) =>
      _request(
        'POST',
        '/conversations/$conversationId/same-device/speakers/$speakerId/activate',
      );

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

  Future<List<Map<String, dynamic>>> timeline(String id) async {
    final result = await _request(
      'GET',
      '/conversations/$id/same-device/timeline',
    );
    return _mapList(result);
  }

  Future<Map<String, dynamic>> usage(String id) async =>
      ((await _request('GET', '/conversations/$id/same-device/usage')) as Map)
          .cast<String, dynamic>();

  Future<Map<String, dynamic>> dailyUsage() async =>
      ((await _request('GET', '/usage/me/daily')) as Map)
          .cast<String, dynamic>();

  Future<TtsGeneration> synthesizeTts({
    required String conversationId,
    required String messageId,
    required String text,
    required String languageCode,
    String voiceName = '',
    String voiceGender = '',
    num speakingRate = 0,
    num pitch = 0,
    String audioFormat = 'mp3',
  }) async {
    final result = await _request(
      'POST',
      '/tts/synthesiser',
      body: {
        'conversationId': conversationId,
        'messageId': messageId,
        'text': text,
        'languageCode': languageCode,
        if (voiceName.trim().isNotEmpty) 'voiceName': voiceName,
        if (voiceGender.trim().isNotEmpty) 'voiceGender': voiceGender,
        'speakingRate': speakingRate,
        'pitch': pitch,
        'audioFormat': audioFormat,
      },
    );
    return TtsGeneration.fromJson(_normalizeJson(result));
  }

  Future<List<TtsGeneration>> ttsGenerations() async {
    final result = await _request('GET', '/tts/generations');
    return _asMapList(result)
        .map<TtsGeneration>((entry) => TtsGeneration.fromJson(entry))
        .toList();
  }

  List<Map<String, dynamic>> _mapList(dynamic result) {
    return _asMapList(result);
  }

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