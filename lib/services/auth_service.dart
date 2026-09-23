import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  static const _tokenKey = 'workly_auth_token';
  UserModel? currentUser;
  bool initialized = false;

  Future<bool> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(_tokenKey);
    if (token == null) {
      initialized = true;
      return false;
    }
    ApiClient.setToken(token);
    try {
      final response = await ApiClient.get('/auth/me');
      if (response.statusCode == 200) {
        currentUser = UserModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        initialized = true;
        return true;
      }
    } catch (_) {}
    await logout();
    initialized = true;
    return false;
  }

  Future<UserModel> login(String email, String password) async {
    final response = await ApiClient.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return _saveSession(response);
  }

  Future<UserModel> register(String name, String email, String password) async {
    final response = await ApiClient.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });
    return _saveSession(response);
  }

  Future<UserModel> loginWithGoogle() async {
    final google = GoogleSignIn.instance;
    const serverClientId = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '360904661131-p69go9sb2p9sq7o7kh5tuj7qjc78ub55.apps.googleusercontent.com',
    );
    await google.initialize(serverClientId: serverClientId);
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw ApiException.message('Google no devolvió un token válido');
    final response = await ApiClient.post('/auth/google', body: {'idToken': idToken});
    return _saveSession(response);
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    ApiClient.setToken(null);
    currentUser = null;
  }

  Future<UserModel> _saveSession(dynamic response) async {
    final body = response.body.toString().trim();
    if (body.isEmpty) {
      throw ApiException.message(
        'El servidor no devolvió una respuesta. Verifica que Render esté activo.',
      );
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException.message(
        'El servidor devolvió una respuesta inválida (${response.statusCode}).',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.message(data['error'] as String? ?? 'No se pudo iniciar sesión');
    }
    final token = data['token'];
    final userData = data['user'];
    if (token is! String || userData is! Map<String, dynamic>) {
      throw ApiException.message('Respuesta de autenticación incompleta.');
    }
    final user = UserModel.fromJson(userData);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
    ApiClient.setToken(token);
    currentUser = user;
    return user;
  }
}