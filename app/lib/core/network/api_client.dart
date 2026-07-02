import 'dart:convert';
import 'package:http/http.dart' as http;

import 'token_store.dart';

/// Тонкая обёртка над http с JWT из [TokenStore].
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    TokenStore? tokenStore,
  })  : _client = client ?? http.Client(),
        _tokens = tokenStore ?? InMemoryTokenStore();

  final String baseUrl;
  final http.Client _client;
  final TokenStore _tokens;

  Future<Map<String, String>> _headers() async {
    final token = await _tokens.read();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async {
    final res = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<dynamic> post(String path, Object body) async {
    final res = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, res.body);
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'ApiException($statusCode): $body';
}
