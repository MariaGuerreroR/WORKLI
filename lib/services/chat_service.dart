import 'dart:convert';
import '../models/message_model.dart';
import 'api_client.dart';

export 'api_client.dart' show ApiException;

class ChatService {
  static const String _resource = '/messages';

  final Map<String, List<MessageModel>> _cache = {};
  final Map<String, DateTime> _lastReadAt = {};
  bool _connectionFailed = false;

  bool get connectionFailed => _connectionFailed;

  Future<List<MessageModel>> _getForProject(String projectId) async {
    if (_cache.containsKey(projectId)) return _cache[projectId]!;
    try {
      final res = await ApiClient.get('$_resource/$projectId');
      _connectionFailed = false;
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        _cache[projectId] = list.map((j) => _fromApi(j as Map<String, dynamic>)).toList();
      } else {
        _cache[projectId] = [];
      }
    } on ApiException {
      _connectionFailed = true;
      _cache[projectId] = [];
    }
    return _cache[projectId]!;
  }

  List<MessageModel> getMessagesForProject(String projectId) {
    final msgs = _cache[projectId] ?? [];
    return List.unmodifiable(msgs..sort((a, b) => a.sentAt.compareTo(b.sentAt)));
  }

  Future<void> ensureLoaded(String projectId) async {
    await _getForProject(projectId);
  }

  Future<void> refreshAll() async {
    final projectIds = _cache.keys.toList();
    _cache.clear();
    for (final id in projectIds) {
      await _getForProject(id);
    }
  }

  List<MessageModel> getRecentMessages({int limit = 5}) {
    final all = <MessageModel>[];
    for (final msgs in _cache.values) {
      all.addAll(msgs);
    }
    all.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return all.take(limit).toList();
  }

  MessageModel? getLastMessage(String projectId) {
    final msgs = _cache[projectId];
    if (msgs == null || msgs.isEmpty) return null;
    msgs.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return msgs.first;
  }

  int getUnreadCount(String projectId, String currentUserId) {
    final msgs = _cache[projectId];
    if (msgs == null || msgs.isEmpty) return 0;
    final lastRead = _lastReadAt[projectId];
    int count = 0;
    for (final m in msgs) {
      if (m.senderId == currentUserId) continue;
      if (lastRead == null || m.sentAt.isAfter(lastRead)) {
        count++;
      }
    }
    return count;
  }

  int get totalUnreadCount {
    final userId = _currentUserId;
    if (userId == null) return 0;
    int total = 0;
    for (final pid in _cache.keys) {
      total += getUnreadCount(pid, userId);
    }
    return total;
  }

  String? _currentUserId;
  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  void markAsRead(String projectId) {
    _lastReadAt[projectId] = DateTime.now();
  }

  Future<void> sendMessage(MessageModel message) async {
    final messages = _cache.putIfAbsent(message.projectId, () => []);
    messages.add(message);
    try {
      final res = await ApiClient.post(_resource, body: _toApi(message));
      if (res.statusCode != 201) {
        throw ApiException.message('No se pudo enviar el mensaje');
      }
      final created = _fromApi(jsonDecode(res.body) as Map<String, dynamic>);
      messages.removeWhere((item) => item.id == message.id);
      messages.add(created);
    } catch (_) {
      messages.removeWhere((item) => item.id == message.id);
      rethrow;
    }
  }

  MessageModel _fromApi(Map<String, dynamic> j) {
    return MessageModel(
      id: j['_id'] as String? ?? j['id'] as String,
      projectId: j['projectId'] as String,
      senderId: j['senderId'] as String,
      senderName: j['senderName'] as String,
      content: j['content'] as String,
      isEdited: j['isEdited'] as bool? ?? false,
      sentAt: DateTime.tryParse(j['sentAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _toApi(MessageModel m) => {
        'projectId': m.projectId,
        'senderId': m.senderId,
        'senderName': m.senderName,
        'content': m.content,
        'isEdited': m.isEdited,
        'sentAt': m.sentAt.toIso8601String(),
      };
}
