enum ObjectiveStatus { notStarted, inProgress, achieved, deferred }

extension ObjectiveStatusLabel on ObjectiveStatus {
  String get label {
    switch (this) {
      case ObjectiveStatus.notStarted:
        return 'No Iniciado';
      case ObjectiveStatus.inProgress:
        return 'En Progreso';
      case ObjectiveStatus.achieved:
        return 'Alcanzado';
      case ObjectiveStatus.deferred:
        return 'Postergado';
    }
  }
}

class ObjectiveModel {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final ObjectiveStatus status;
  final double weight;
  final DateTime? targetDate;
  final List<String> milestones;
  final int completedMilestones;
  final DateTime createdAt;

  const ObjectiveModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.status = ObjectiveStatus.notStarted,
    this.weight = 1.0,
    this.targetDate,
    this.milestones = const [],
    this.completedMilestones = 0,
    required this.createdAt,
  });

  double get progress {
    if (milestones.isEmpty) {
      return status == ObjectiveStatus.achieved ? 1.0 : 0.0;
    }
    return completedMilestones / milestones.length;
  }

  factory ObjectiveModel.fromJson(Map<String, dynamic> json) {
    return ObjectiveModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      status: ObjectiveStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ObjectiveStatus.notStarted,
      ),
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      milestones: List<String>.from(json['milestones'] as List? ?? []),
      completedMilestones: json['completedMilestones'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'status': status.name,
        'weight': weight,
        'targetDate': targetDate?.toIso8601String(),
        'milestones': milestones,
        'completedMilestones': completedMilestones,
        'createdAt': createdAt.toIso8601String(),
      };

  ObjectiveModel copyWith({
    String? title,
    String? description,
    ObjectiveStatus? status,
    double? weight,
    DateTime? targetDate,
    List<String>? milestones,
    int? completedMilestones,
  }) {
    return ObjectiveModel(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      weight: weight ?? this.weight,
      targetDate: targetDate ?? this.targetDate,
      milestones: milestones ?? this.milestones,
      completedMilestones: completedMilestones ?? this.completedMilestones,
      createdAt: createdAt,
    );
  }
}
