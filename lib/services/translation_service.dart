import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class TranslationService {
  /// Traduit [text] de [sourceLangCode] vers [targetLangCode].
  /// Les codes suivent la norme ISO courte : "tr", "fr", "en".
  Future<String> translate({
    required String text,
    required String sourceLangCode,
    required String targetLangCode,
    String? conversationId,
    String? messageId,
  });
}

class ApiTranslationService implements TranslationService {
  ApiTranslationService({required this.baseUrl, this.accessToken});

  final String baseUrl;
  String? accessToken;

  static dynamic _safeJsonDecode(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> buildRequestBody({
    required String text,
    required String sourceLangCode,
    required String targetLangCode,
    String? conversationId,
    String? messageId,
  }) {
    final body = <String, dynamic>{
      'text': text,
      'sourceLanguage': sourceLangCode,
      'targetLanguage': targetLangCode,
    };

    if (conversationId != null && conversationId.trim().isNotEmpty) {
      body['conversationId'] = conversationId.trim();
    }
    if (messageId != null && messageId.trim().isNotEmpty) {
      body['messageId'] = messageId.trim();
    }

    return body;
  }

  static String extractTranslatedText(dynamic body) {
    final payload = body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    final nested = payload['data'] is Map ? Map<String, dynamic>.from(payload['data']) : payload;

    final result = nested['translatedText'] ??
        nested['translation'] ??
        nested['text'] ??
        nested['result'] ??
        payload['translatedText'] ??
        payload['translation'] ??
        payload['text'] ??
        payload['result'];

    if (result is String && result.trim().isNotEmpty) {
      return result;
    }

    throw const FormatException('Réponse backend invalide');
  }

  @override
  Future<String> translate({
    required String text,
    required String sourceLangCode,
    required String targetLangCode,
    String? conversationId,
    String? messageId,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken!.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/api/v1/translations'),
            headers: headers,
            body: jsonEncode(buildRequestBody(
              text: text,
              sourceLangCode: sourceLangCode,
              targetLangCode: targetLangCode,
              conversationId: conversationId,
              messageId: messageId,
            )),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Délai de traduction dépassé (15s)'),
          );
    } on Exception {
      rethrow;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _safeJsonDecode(response.body);
      final message = decoded is Map
          ? (decoded['message'] ?? decoded['error'])
          : null;
      throw Exception(message ?? 'Erreur de traduction (${response.statusCode})');
    }

    final body = _safeJsonDecode(response.body);
    if (body == null) {
      throw const FormatException('Réponse vide du backend de traduction');
    }
    return extractTranslatedText(body);
  }
}

/// Implémentation factice utilisée tant que l'API du backend
/// n'est pas branchée. Permet de développer et tester les interfaces
/// de façon autonome.
class MockTranslationService implements TranslationService {
  @override
  Future<String> translate({
    required String text,
    required String sourceLangCode,
    required String targetLangCode,
    String? conversationId,
    String? messageId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (text.trim().isEmpty) return '';

    return '[$sourceLangCode → $targetLangCode] $text';
  }
}
