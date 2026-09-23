import 'dart:convert';
import '../models/project_model.dart';
import '../models/objective_model.dart';
import 'api_client.dart';

export 'api_client.dart' show ApiException;

class ProjectService {
  static final ProjectService instance = ProjectService._();
  factory ProjectService() => instance;
  ProjectService._();

  static const String _resource = '/projects';

  List<ProjectModel> _cache = [];
  bool _connectionFailed = false;

  bool get connectionFailed => _connectionFailed;

  Future<void> _fetchAll() async {
    try {
      final res = await ApiClient.get(_resource);
      _connectionFailed = false;
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        _cache = list.map((j) => _fromApi(j as Map<String, dynamic>)).toList();
      } else {
        _cache = [];
      }
    } on ApiException {
      _connectionFailed = true;
    }
  }

  List<ProjectModel> getAllProjects() => List.unmodifiable(_cache);

  ProjectModel? getProjectById(String id) {
    try {
      return _cache.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ObjectiveModel> getObjectivesForProject(String projectId) {
    return _objectivesCache.where((o) => o.projectId == projectId).toList();
  }

  ObjectiveModel? getObjectiveById(String id) {
    try {
      return _objectivesCache.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  void addObjective(ObjectiveModel objective) {
    _objectivesCache.add(objective);
  }

  void updateObjective(ObjectiveModel objective) {
    final idx = _objectivesCache.indexWhere((o) => o.id == objective.id);
    if (idx != -1) _objectivesCache[idx] = objective;
  }

  void deleteObjective(String id) {
    _objectivesCache.removeWhere((o) => o.id == id);
  }

  final List<ObjectiveModel> _objectivesCache = [];

  List<ProjectModel> getProjectsByStatus(ProjectStatus status) {
    return _cache.where((p) => p.status == status).toList();
  }

  Future<void> addProject(ProjectModel project) async {
    final res = await ApiClient.post(_resource, body: _toApi(project));
    if (res.statusCode == 201) {
      final created = _fromApi(jsonDecode(res.body) as Map<String, dynamic>);
      _cache.insert(0, created);
    }
  }

  Future<void> updateProject(ProjectModel project) async {
    final res = await ApiClient.put('$_resource/${project.id}', body: _toApi(project));
    if (res.statusCode == 200) {
      final updated = _fromApi(jsonDecode(res.body) as Map<String, dynamic>);
      final idx = _cache.indexWhere((p) => p.id == project.id);
      if (idx != -1) _cache[idx] = updated;
    }
  }

  Future<void> deleteProject(String id) async {
    await ApiClient.delete('$_resource/$id');
    _cache.removeWhere((p) => p.id == id);
    _objectivesCache.removeWhere((o) => o.projectId == id);
  }

  int get totalProjects => _cache.length;

  int get activeProjects =>
      _cache.where((p) => p.status == ProjectStatus.active).length;

  double get totalBudget =>
      _cache.fold(0, (sum, p) => sum + p.budget);

  double get totalSpent =>
      _cache.fold(0, (sum, p) => sum + p.spent);

  double get averageProgress {
    if (_cache.isEmpty) return 0;
    return _cache.fold(0, (sum, p) => sum + p.progress) / _cache.length;
  }

  Future<void> refresh() async {
    await _fetchAll();
  }

  ProjectModel _fromApi(Map<String, dynamic> j) {
    return ProjectModel(
      id: j['_id'] as String? ?? j['id'] as String,
      title: j['title'] as String,
      description: j['description'] as String? ?? '',
      area: j['area'] as String?,
      status: ProjectStatus.values.firstWhere(
        (s) => s.name == j['status'],
        orElse: () => ProjectStatus.planning,
      ),
      leadId: j['leadId'] as String? ?? 'u1',
      memberIds: List<String>.from(j['memberIds'] as List? ?? []),
      startDate: DateTime.tryParse(j['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate: j['endDate'] != null
          ? DateTime.tryParse(j['endDate'] as String)
          : null,
      budget: (j['budget'] as num?)?.toDouble() ?? 0,
      spent: (j['spent'] as num?)?.toDouble() ?? 0,
      progress: j['progress'] as int? ?? 0,
      tags: List<String>.from(j['tags'] as List? ?? []),
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _toApi(ProjectModel p) => {
        'title': p.title,
        'description': p.description,
        'area': p.area,
        'status': p.status.name,
        'leadId': p.leadId,
        'memberIds': p.memberIds,
        'startDate': p.startDate.toIso8601String(),
        'endDate': p.endDate?.toIso8601String(),
        'budget': p.budget,
        'spent': p.spent,
        'progress': p.progress,
        'tags': p.tags,
      };
}
