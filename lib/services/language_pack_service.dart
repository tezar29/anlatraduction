import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/backend_models.dart';

class LanguagePackService {
  LanguagePackService({required this.baseUrl, this.accessToken});

  final String baseUrl;
  final String? accessToken;

  Uri _uri(String path) => Uri.parse(
        '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/api/v1$path',
      );

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }

    if (value is Map) {
      final nested = value['content'] ??
          value['items'] ??
          value['data'] ??
          value['results'] ??
          <dynamic>[];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
      if (nested is Map) {
        return [Map<String, dynamic>.from(nested)];
      }
    }

    return const <Map<String, dynamic>>[];
  }

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

      if (text.trim().isEmpty) {
        return <String, dynamic>{};
      }

      final decoded = jsonDecode(text);
      return decoded is Map ? _asMap(decoded) : decoded;
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Erreur API: $error');
    } finally {
      client.close();
    }
  }

  Future<List<LanguagePack>> fetchPacks() async {
    final result = await _request('GET', '/packs-langues');
    return _asMapList(result)
        .map<LanguagePack>((entry) => LanguagePack.fromJson(entry))
        .toList();
  }

  Future<LanguagePack> fetchPack(String languageCode) async {
    final result = await _request('GET', '/packs-langues/$languageCode');
    return LanguagePack.fromJson(_asMap(result));
  }

  Future<List<LanguagePack>> fetchRecommendedPacks() async {
    final result = await _request('GET', '/packs-langues/recommendations');
    return _asMapList(result)
        .map<LanguagePack>((entry) => LanguagePack.fromJson(entry))
        .toList();
  }

  Future<List<LanguagePackInstallation>> fetchInstalledPacks() async {
    final result = await _request('GET', '/packs-langues/installations');
    return _asMapList(result)
        .map<LanguagePackInstallation>((entry) => LanguagePackInstallation.fromJson(entry))
        .toList();
  }

  Future<LanguagePackInstallation> installPack({
    required String languageCode,
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
    return LanguagePackInstallation.fromJson(_asMap(result));
  }

  Future<void> uninstallPack(String languageCode) => _request(
        'DELETE',
        '/packs-langues/$languageCode/installations',
      );

  Future<void> syncMetadata(Map<String, dynamic> metadata) => _request(
        'POST',
        '/offline/sync-metadata',
        body: metadata,
      );
}
