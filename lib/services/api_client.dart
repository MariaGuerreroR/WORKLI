import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static String? _token;

  static void setToken(String? token) => _token = token;

  static String get baseUrl {
    const renderApiUrl = String.fromEnvironment(
      'API_URL',
      defaultValue: 'https://worklii-backend-1.onrender.com/api',
    );
    return renderApiUrl;
  }

  static final http.Client _client = http.Client();

  static http.Client get client => _client;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Future<http.Response> get(String path) async {
    try {
      return await _client
          .get(Uri.parse('$baseUrl$path'), headers: _headers)
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw ApiException.connectionFailed();
    }
  }

  static Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    try {
      return await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw ApiException.connectionFailed();
    }
  }

  static Future<http.Response> put(String path, {Map<String, dynamic>? body}) async {
    try {
      return await _client
          .put(
            Uri.parse('$baseUrl$path'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw ApiException.connectionFailed();
    }
  }

  static Future<http.Response> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      return await _client
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw ApiException.connectionFailed();
    }
  }

  static Future<http.Response> delete(String path) async {
    try {
      return await _client
          .delete(Uri.parse('$baseUrl$path'), headers: _headers)
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw ApiException.connectionFailed();
    }
  }
}

class ApiException implements Exception {
  final String message;
  final bool isConnectionError;

  const ApiException._(this.message, {this.isConnectionError = false});

  factory ApiException.connectionFailed() =>
      const ApiException._('No hay conexión con el servidor', isConnectionError: true);

  factory ApiException.message(String message) => ApiException._(message);

  @override
  String toString() => message;
}

