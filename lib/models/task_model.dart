enum TaskPriority { low, medium, high, urgent }
enum TaskStatus { todo, inProgress, review, done }

extension TaskPriorityLabel on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Baja';
      case TaskPriority.medium:
        return 'Media';
      case TaskPriority.high:
        return 'Alta';
      case TaskPriority.urgent:
        return 'Urgente';
    }
  }
}

extension TaskStatusLabel on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'Por Hacer';
      case TaskStatus.inProgress:
        return 'En Progreso';
      case TaskStatus.review:
        return 'En Revisión';
      case TaskStatus.done:
        return 'Completado';
    }
  }
}

class TaskModel {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assigneeId;
  final String? objectiveId;
  final DateTime? dueDate;
  final List<String> subtasks;
  final int completedSubtasks;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.assigneeId,
    this.objectiveId,
    this.dueDate,
    this.subtasks = const [],
    this.completedSubtasks = 0,
    required this.createdAt,
  });

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status != TaskStatus.done;
  }

  double get subtaskProgress {
    if (subtasks.isEmpty) return 0;
    return completedSubtasks / subtasks.length;
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      status: TaskStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TaskStatus.todo,
      ),
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      assigneeId: json['assigneeId'] as String?,
      objectiveId: json['objectiveId'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      subtasks: List<String>.from(json['subtasks'] as List? ?? []),
      completedSubtasks: json['completedSubtasks'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'status': status.name,
        'priority': priority.name,
        'assigneeId': assigneeId,
        'objectiveId': objectiveId,
        'dueDate': dueDate?.toIso8601String(),
        'subtasks': subtasks,
        'completedSubtasks': completedSubtasks,
        'createdAt': createdAt.toIso8601String(),
      };

  TaskModel copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    String? objectiveId,
    DateTime? dueDate,
    List<String>? subtasks,
    int? completedSubtasks,
  }) {
    return TaskModel(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: assigneeId ?? this.assigneeId,
      objectiveId: objectiveId ?? this.objectiveId,
      dueDate: dueDate ?? this.dueDate,
      subtasks: subtasks ?? this.subtasks,
      completedSubtasks: completedSubtasks ?? this.completedSubtasks,
      createdAt: createdAt,
    );
  }
}
