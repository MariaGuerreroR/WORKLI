class ReportModel {
  final String id;
  final String projectId;
  final String title;
  final String summary;
  final String authorId;
  final String authorName;
  final int progressBefore;
  final int progressAfter;
  final List<String> highlights;
  final List<String> challenges;
  final List<String> nextSteps;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.summary = '',
    required this.authorId,
    required this.authorName,
    this.progressBefore = 0,
    this.progressAfter = 0,
    this.highlights = const [],
    this.challenges = const [],
    this.nextSteps = const [],
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
  });

  int get progressDelta => progressAfter - progressBefore;

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String? ?? '',
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      progressBefore: json['progressBefore'] as int? ?? 0,
      progressAfter: json['progressAfter'] as int? ?? 0,
      highlights: List<String>.from(json['highlights'] as List? ?? []),
      challenges: List<String>.from(json['challenges'] as List? ?? []),
      nextSteps: List<String>.from(json['nextSteps'] as List? ?? []),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'summary': summary,
        'authorId': authorId,
        'authorName': authorName,
        'progressBefore': progressBefore,
        'progressAfter': progressAfter,
        'highlights': highlights,
        'challenges': challenges,
        'nextSteps': nextSteps,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}
