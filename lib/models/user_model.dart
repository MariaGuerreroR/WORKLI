enum UserRole { principalInvestigator, coInvestigator, researcher, assistant, external }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.principalInvestigator:
        return 'Investigador Principal';
      case UserRole.coInvestigator:
        return 'Co-investigador';
      case UserRole.researcher:
        return 'Investigador';
      case UserRole.assistant:
        return 'Asistente';
      case UserRole.external:
        return 'Colaborador Externo';
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? institution;
  final String? avatarUrl;
  final UserRole role;
  final List<String> projectIds;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.institution,
    this.avatarUrl,
    this.role = UserRole.researcher,
    this.projectIds = const [],
    required this.createdAt,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      institution: json['institution'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.researcher,
      ),
      projectIds: List<String>.from(json['projectIds'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'institution': institution,
        'avatarUrl': avatarUrl,
        'role': role.name,
        'projectIds': projectIds,
        'createdAt': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? name,
    String? email,
    String? institution,
    String? avatarUrl,
    UserRole? role,
    List<String>? projectIds,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      institution: institution ?? this.institution,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      projectIds: projectIds ?? this.projectIds,
      createdAt: createdAt,
    );
  }
}
