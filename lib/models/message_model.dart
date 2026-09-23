class MessageModel {
  final String id;
  final String projectId;
  final String senderId;
  final String senderName;
  final String content;
  final bool isEdited;
  final DateTime sentAt;

  const MessageModel({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.isEdited = false,
    required this.sentAt,
  });

  MessageModel copyWith({
    String? content,
    bool? isEdited,
  }) {
    return MessageModel(
      id: id,
      projectId: projectId,
      senderId: senderId,
      senderName: senderName,
      content: content ?? this.content,
      isEdited: isEdited ?? this.isEdited,
      sentAt: sentAt,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      isEdited: json['isEdited'] as bool? ?? false,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'isEdited': isEdited,
        'sentAt': sentAt.toIso8601String(),
      };
}
