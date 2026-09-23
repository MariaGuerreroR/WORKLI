import 'dart:convert';
import '../models/user_model.dart';
import 'api_client.dart';

export 'api_client.dart' show ApiException;

class UserService {
  static const String _resource = '/users';

  UserModel? _currentUser;
  bool _loaded = false;
  bool _connectionFailed = false;

  bool get connectionFailed => _connectionFailed;

  Future<UserModel?> _ensureLoaded() async {
    if (_loaded) return _currentUser;
    await fetchCurrentUser();
    return _currentUser;
  }

  Future<void> fetchCurrentUser() async {
    try {
      final res = await ApiClient.get('/auth/me');
      _connectionFailed = false;
      if (res.statusCode == 200) {
        _currentUser = _fromApi(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } on ApiException {
      _connectionFailed = true;
    }
    _loaded = true;
  }

  UserModel? get currentUser => _currentUser;

  Future<UserModel?> updateProfile({
    required String name,
    required String email,
    String? institution,
    UserRole? role,
  }) async {
    if (_currentUser == null) return null;
    final body = <String, dynamic>{
      'name': name,
      'email': email,
    };
    if (institution != null) body['institution'] = institution;
    if (role != null) body['role'] = role.name;

    final res = await ApiClient.put('$_resource/${_currentUser!.id}', body: body);
    if (res.statusCode == 200) {
      _currentUser = _fromApi(jsonDecode(res.body) as Map<String, dynamic>);
    }
    return _currentUser;
  }

  Future<void> refresh() async {
    _loaded = false;
    await _ensureLoaded();
  }

  UserModel _fromApi(Map<String, dynamic> j) {
    return UserModel(
      id: j['_id'] as String? ?? j['id'] as String,
      name: j['name'] as String,
      email: j['email'] as String,
      institution: j['institution'] as String?,
      avatarUrl: j['avatarUrl'] as String?,
      role: UserRole.values.firstWhere(
        (r) => r.name == j['role'],
        orElse: () => UserRole.researcher,
      ),
      projectIds: List<String>.from(j['projectIds'] as List? ?? []),
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
