import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/backend_models.dart';

class GuestSessionService {
  GuestSessionService({required this.baseUrl, this.accessToken});

  final String baseUrl;
  final String? accessToken;

  Uri _uri(String path) => Uri.parse(
        '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/api/v1$path',
      );

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken!.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final request = http.Request(method, _uri(path))..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final client = http.Client();
    try {
      final response = await client.send(request);
      final text = await response.stream.bytesToString();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final payload = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
        final message = _asMap(payload)['message'] ??
            _asMap(payload)['error'] ??
            'Erreur API (${response.statusCode})';
        throw Exception(message);
      }

      if (text.trim().isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(text);
      return decoded is Map ? _asMap(decoded) : decoded;
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Erreur API: $error');
    } finally {
      client.close();
    }
  }

  Future<GuestSession> createSession({
    required String deviceId,
    required String displayName,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final result = await _request(
      'POST',
      '/sessions-invites',
      body: {
        'deviceId': deviceId,
        'displayName': displayName,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
      },
    );
    return GuestSession.fromJson(_asMap(result));
  }

  Future<GuestSession> getSession(String guestSessionId) async {
    final result = await _request('GET', '/guest-sessions/$guestSessionId');
    return GuestSession.fromJson(_asMap(result));
  }

  Future<GuestSession> refreshSession(String guestSessionId) async {
    final result = await _request(
      'POST',
      '/guest-sessions/$guestSessionId/refresh',
    );
    return GuestSession.fromJson(_asMap(result));
  }

  Future<GuestSession> claimSession(String guestSessionId) async {
    final result = await _request(
      'POST',
      '/guest-sessions/$guestSessionId/claim',
    );
    return GuestSession.fromJson(_asMap(result));
  }

  Future<void> deleteSession(String guestSessionId) => _request(
        'DELETE',
        '/guest-sessions/$guestSessionId',
      );

  Future<Map<String, dynamic>> checkDailyUsage(String guestSessionId) async {
    final result = await _request(
      'POST',
      '/guest-sessions/$guestSessionId/usage/daily/check',
    );
    return _asMap(result);
  }

  Future<Map<String, dynamic>> getDailyUsage(String guestSessionId) async {
    final result = await _request(
      'GET',
      '/guest-sessions/$guestSessionId/usage/daily',
    );
    return _asMap(result);
  }
}
