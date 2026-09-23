enum NotificationType { taskAssigned, deadlineReminder, documentShared, messageReceived, projectUpdate, mention }

extension NotificationTypeLabel on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.taskAssigned:
        return 'Tarea Asignada';
      case NotificationType.deadlineReminder:
        return 'Recordatorio de Fecha';
      case NotificationType.documentShared:
        return 'Documento Compartido';
      case NotificationType.messageReceived:
        return 'Mensaje Recibido';
      case NotificationType.projectUpdate:
        return 'Actualización de Proyecto';
      case NotificationType.mention:
        return 'Mención';
    }
  }
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? projectId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.projectId,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      projectId: projectId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.projectUpdate,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      projectId: json['projectId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'projectId': projectId,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
      };
}
