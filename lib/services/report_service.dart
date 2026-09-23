import 'dart:convert';
import '../models/report_model.dart';
import 'api_client.dart';

export 'api_client.dart' show ApiException;

class ReportService {
  static const String _resource = '/reports';

  List<ReportModel> _cache = [];
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

  List<ReportModel> getAllReports() {
    final sorted = List<ReportModel>.from(_cache)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  List<ReportModel> getReportsForProject(String projectId) {
    return _cache.where((r) => r.projectId == projectId).toList();
  }

  Future<void> addReport(ReportModel report) async {
    final res = await ApiClient.post(_resource, body: _toApi(report));
    if (res.statusCode == 201) {
      final created = _fromApi(jsonDecode(res.body) as Map<String, dynamic>);
      _cache.insert(0, created);
    }
  }

  Future<void> deleteReport(String id) async {
    await ApiClient.delete('$_resource/$id');
    _cache.removeWhere((r) => r.id == id);
  }

  int get totalReports => _cache.length;

  Future<void> refresh() async {
    _loaded = false;
    await _ensureLoaded();
  }

  ReportModel _fromApi(Map<String, dynamic> j) {
    return ReportModel(
      id: j['_id'] as String? ?? j['id'] as String,
      projectId: j['projectId'] as String,
      title: j['title'] as String,
      summary: j['summary'] as String? ?? '',
      authorId: j['authorId'] as String? ?? 'u1',
      authorName: j['authorName'] as String? ?? '',
      progressBefore: j['progressBefore'] as int? ?? 0,
      progressAfter: j['progressAfter'] as int? ?? 0,
      highlights: List<String>.from(j['highlights'] as List? ?? []),
      challenges: List<String>.from(j['challenges'] as List? ?? []),
      nextSteps: List<String>.from(j['nextSteps'] as List? ?? []),
      periodStart: DateTime.tryParse(j['periodStart'] as String? ?? '') ?? DateTime.now(),
      periodEnd: DateTime.tryParse(j['periodEnd'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _toApi(ReportModel r) => {
        'projectId': r.projectId,
        'title': r.title,
        'summary': r.summary,
        'authorId': r.authorId,
        'authorName': r.authorName,
        'progressBefore': r.progressBefore,
        'progressAfter': r.progressAfter,
        'highlights': r.highlights,
        'challenges': r.challenges,
        'nextSteps': r.nextSteps,
        'periodStart': r.periodStart.toIso8601String(),
        'periodEnd': r.periodEnd.toIso8601String(),
      };
}
