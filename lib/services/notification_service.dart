import 'dart:convert';
import '../models/notification_model.dart';
import 'api_client.dart';

export 'api_client.dart' show ApiException;

class NotificationService {
  static const String _resource = '/notifications';

  List<NotificationModel> _cache = [];
  bool _loaded = false;
  bool _connectionFailed = false;

  bool get connectionFailed => _connectionFailed;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final res = await ApiClient.get(_resource);
      _connectionFailed = false;
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        _cache = list.map((j) => _fromApi(j as Map<String, dynamic>)).toList();
      }
    } on ApiException {
      _connectionFailed = true;
    }
    _loaded = true;
  }

  List<NotificationModel> getAllNotifications() {
    final sorted = List<NotificationModel>.from(_cache)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  List<NotificationModel> getUnreadNotifications() {
    return getAllNotifications().where((n) => !n.isRead).toList();
  }

  Future<void> markAsRead(String id) async {
    final res = await ApiClient.patch('$_resource/$id/read');
    if (res.statusCode == 200) {
      final idx = _cache.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _cache[idx] = _cache[idx].copyWith(isRead: true);
      }
    }
  }

  Future<void> markAllAsRead() async {
    final res = await ApiClient.patch('$_resource/read-all');
    if (res.statusCode == 200) {
      for (var i = 0; i < _cache.length; i++) {
        _cache[i] = _cache[i].copyWith(isRead: true);
      }
    }
  }

  int get unreadCount => _cache.where((n) => !n.isRead).length;

  void addLocalNotification(NotificationModel notification) {
    _cache.insert(0, notification);
  }

  Future<void> refresh() async {
    _loaded = false;
    await _ensureLoaded();
  }

  NotificationModel _fromApi(Map<String, dynamic> j) {
    return NotificationModel(
      id: j['_id'] as String? ?? j['id'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.name == j['type'],
        orElse: () => NotificationType.projectUpdate,
      ),
      title: j['title'] as String,
      body: j['body'] as String,
      projectId: j['projectId'] as String?,
      isRead: j['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
