import 'dart:convert';
import '../models/document_model.dart';
import 'api_client.dart';

export 'api_client.dart' show ApiException;

class DocumentService {
  static const String _resource = '/documents';

  List<DocumentModel> _cache = [];
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

  List<DocumentModel> getAllDocuments() => List.unmodifiable(_cache);

  List<DocumentModel> getDocumentsForProject(String projectId) {
    return _cache.where((d) => d.projectId == projectId).toList();
  }

  List<DocumentModel> getDocumentsByType(DocumentType type) {
    return _cache.where((d) => d.type == type).toList();
  }

  Future<void> addDocument(DocumentModel doc) async {
    final res = await ApiClient.post(_resource, body: _toApi(doc));
    if (res.statusCode == 201) {
      final created = _fromApi(jsonDecode(res.body) as Map<String, dynamic>);
      _cache.insert(0, created);
    }
  }

  Future<void> updateDocument(DocumentModel doc) async {
    final res = await ApiClient.put('$_resource/${doc.id}', body: _toApi(doc));
    if (res.statusCode == 200) {
      final idx = _cache.indexWhere((d) => d.id == doc.id);
      if (idx != -1) _cache[idx] = doc;
    }
  }

  Future<void> deleteDocument(String id) async {
    await ApiClient.delete('$_resource/$id');
    _cache.removeWhere((d) => d.id == id);
  }

  int get totalDocuments => _cache.length;

  double get totalSizeMb =>
      _cache.fold(0, (sum, d) => sum + d.sizeKb) / 1024;

  Future<void> refresh() async {
    _loaded = false;
    await _ensureLoaded();
  }

  DocumentModel _fromApi(Map<String, dynamic> j) {
    return DocumentModel(
      id: j['_id'] as String? ?? j['id'] as String,
      projectId: j['projectId'] as String,
      title: j['title'] as String,
      type: DocumentType.values.firstWhere(
        (t) => t.name == j['type'],
        orElse: () => DocumentType.other,
      ),
      fileUrl: j['fileUrl'] as String?,
      fileType: j['fileType'] as String? ?? 'pdf',
      sizeKb: j['sizeKb'] as int? ?? 0,
      uploadedById: j['uploadedById'] as String? ?? 'u1',
      version: j['version'] as String?,
      tags: List<String>.from(j['tags'] as List? ?? []),
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _toApi(DocumentModel d) => {
        'projectId': d.projectId,
        'title': d.title,
        'type': d.type.name,
        'fileUrl': d.fileUrl,
        'fileType': d.fileType,
        'sizeKb': d.sizeKb,
        'uploadedById': d.uploadedById,
        'version': d.version,
        'tags': d.tags,
      };
}
