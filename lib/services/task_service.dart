import 'dart:convert';
import '../models/task_model.dart';
import 'api_client.dart';

export 'api_client.dart' show ApiException;

class TaskService {
  static const String _resource = '/tasks';

  List<TaskModel> _cache = [];
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

  List<TaskModel> getAllTasks() => List.unmodifiable(_cache);

  List<TaskModel> getTasksForProject(String projectId) {
    return _cache.where((t) => t.projectId == projectId).toList();
  }

  List<TaskModel> getTasksByStatus(TaskStatus status) {
    return _cache.where((t) => t.status == status).toList();
  }

  List<TaskModel> getTasksByAssignee(String userId) {
    return _cache.where((t) => t.assigneeId == userId).toList();
  }

  List<TaskModel> getTasksByObjective(String objectiveId) {
    return _cache.where((t) => t.objectiveId == objectiveId).toList();
  }

  List<TaskModel> getOverdueTasks() {
    return _cache.where((t) => t.isOverdue).toList();
  }

  List<TaskModel> getUpcomingTasks({int days = 7}) {
    final limit = DateTime.now().add(Duration(days: days));
    return _cache.where((t) {
      if (t.dueDate == null || t.status == TaskStatus.done) return false;
      return t.dueDate!.isBefore(limit);
    }).toList();
  }

  Future<void> addTask(TaskModel task) async {
    final res = await ApiClient.post(_resource, body: _toApi(task));
    if (res.statusCode == 201) {
      final created = _fromApi(jsonDecode(res.body) as Map<String, dynamic>);
      _cache.insert(0, created);
    }
  }

  Future<void> updateTask(TaskModel task) async {
    final res = await ApiClient.put('$_resource/${task.id}', body: _toApi(task));
    if (res.statusCode == 200) {
      final updated = _fromApi(jsonDecode(res.body) as Map<String, dynamic>);
      final idx = _cache.indexWhere((t) => t.id == task.id);
      if (idx != -1) _cache[idx] = updated;
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final res = await ApiClient.patch('$_resource/$taskId/status', body: {'status': status.name});
    if (res.statusCode == 200) {
      final idx = _cache.indexWhere((t) => t.id == taskId);
      if (idx != -1) {
        _cache[idx] = _cache[idx].copyWith(status: status);
      }
    }
  }

  Future<void> deleteTask(String id) async {
    await ApiClient.delete('$_resource/$id');
    _cache.removeWhere((t) => t.id == id);
  }

  int get totalTasks => _cache.length;

  int get completedTasks =>
      _cache.where((t) => t.status == TaskStatus.done).length;

  int get overdueCount => getOverdueTasks().length;

  double get completionRate {
    if (_cache.isEmpty) return 0;
    return completedTasks / _cache.length * 100;
  }

  Future<void> refresh() async {
    _loaded = false;
    await _ensureLoaded();
  }

  TaskModel _fromApi(Map<String, dynamic> j) {
    return TaskModel(
      id: j['_id'] as String? ?? j['id'] as String,
      projectId: j['projectId'] as String,
      title: j['title'] as String,
      description: j['description'] as String? ?? '',
      status: TaskStatus.values.firstWhere(
        (s) => s.name == j['status'],
        orElse: () => TaskStatus.todo,
      ),
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == j['priority'],
        orElse: () => TaskPriority.medium,
      ),
      assigneeId: j['assigneeId'] as String?,
      objectiveId: j['objectiveId'] as String?,
      dueDate: j['dueDate'] != null
          ? DateTime.tryParse(j['dueDate'] as String)
          : null,
      subtasks: List<String>.from(j['subtasks'] as List? ?? []),
      completedSubtasks: j['completedSubtasks'] as int? ?? 0,
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _toApi(TaskModel t) => {
        'projectId': t.projectId,
        'title': t.title,
        'description': t.description,
        'status': t.status.name,
        'priority': t.priority.name,
        'assigneeId': t.assigneeId,
        'objectiveId': t.objectiveId,
        'dueDate': t.dueDate?.toIso8601String(),
        'subtasks': t.subtasks,
        'completedSubtasks': t.completedSubtasks,
      };
}
