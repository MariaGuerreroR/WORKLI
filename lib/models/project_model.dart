enum ProjectStatus { planning, active, onHold, completed, cancelled }

extension ProjectStatusLabel on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.planning:
        return 'Planificación';
      case ProjectStatus.active:
        return 'Activo';
      case ProjectStatus.onHold:
        return 'En Pausa';
      case ProjectStatus.completed:
        return 'Completado';
      case ProjectStatus.cancelled:
        return 'Cancelado';
    }
  }
}

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String? area;
  final ProjectStatus status;
  final String leadId;
  final List<String> memberIds;
  final DateTime startDate;
  final DateTime? endDate;
  final double budget;
  final double spent;
  final int progress;
  final List<String> tags;
  final DateTime createdAt;

  const ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    this.area,
    this.status = ProjectStatus.planning,
    required this.leadId,
    this.memberIds = const [],
    required this.startDate,
    this.endDate,
    this.budget = 0,
    this.spent = 0,
    this.progress = 0,
    this.tags = const [],
    required this.createdAt,
  });

  double get budgetUtilization => budget > 0 ? (spent / budget) * 100 : 0;

  bool get isOverBudget => spent > budget && budget > 0;

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      area: json['area'] as String?,
      status: ProjectStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ProjectStatus.planning,
      ),
      leadId: json['leadId'] as String,
      memberIds: List<String>.from(json['memberIds'] as List? ?? []),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      budget: (json['budget'] as num?)?.toDouble() ?? 0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0,
      progress: json['progress'] as int? ?? 0,
      tags: List<String>.from(json['tags'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'area': area,
        'status': status.name,
        'leadId': leadId,
        'memberIds': memberIds,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'budget': budget,
        'spent': spent,
        'progress': progress,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
      };

  ProjectModel copyWith({
    String? title,
    String? description,
    String? area,
    ProjectStatus? status,
    String? leadId,
    List<String>? memberIds,
    DateTime? endDate,
    double? budget,
    double? spent,
    int? progress,
    List<String>? tags,
  }) {
    return ProjectModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      area: area ?? this.area,
      status: status ?? this.status,
      leadId: leadId ?? this.leadId,
      memberIds: memberIds ?? this.memberIds,
      startDate: startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      progress: progress ?? this.progress,
      tags: tags ?? this.tags,
      createdAt: createdAt,
    );
  }
}
