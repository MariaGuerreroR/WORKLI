enum DocumentType { paper, dataset, presentation, report, protocol, other }

extension DocumentTypeLabel on DocumentType {
  String get label {
    switch (this) {
      case DocumentType.paper:
        return 'Artículo';
      case DocumentType.dataset:
        return 'Dataset';
      case DocumentType.presentation:
        return 'Presentación';
      case DocumentType.report:
        return 'Informe';
      case DocumentType.protocol:
        return 'Protocolo';
      case DocumentType.other:
        return 'Otro';
    }
  }
}

class DocumentModel {
  final String id;
  final String projectId;
  final String title;
  final DocumentType type;
  final String? fileUrl;
  final String fileType;
  final int sizeKb;
  final String uploadedById;
  final String? version;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.type = DocumentType.other,
    this.fileUrl,
    this.fileType = 'pdf',
    this.sizeKb = 0,
    required this.uploadedById,
    this.version = '1.0',
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get sizeLabel {
    if (sizeKb < 1024) return '${sizeKb}KB';
    return '${(sizeKb / 1024).toStringAsFixed(1)}MB';
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      type: DocumentType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DocumentType.other,
      ),
      fileUrl: json['fileUrl'] as String?,
      fileType: json['fileType'] as String? ?? 'pdf',
      sizeKb: json['sizeKb'] as int? ?? 0,
      uploadedById: json['uploadedById'] as String,
      version: json['version'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'type': type.name,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'sizeKb': sizeKb,
        'uploadedById': uploadedById,
        'version': version,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
