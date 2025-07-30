/// Entité représentant un utilisateur authentifié dans l'application
class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  final bool isEmailConfirmed;
  final Map<String, dynamic>? metadata;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.lastSignInAt,
    required this.isEmailConfirmed,
    this.metadata,
  });

  /// Créer une instance AppUser depuis les données utilisateur Supabase
  factory AppUser.fromSupabaseUser(dynamic supabaseUser) {
    return AppUser(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      displayName: supabaseUser.userMetadata?['display_name'] ?? 
                   supabaseUser.userMetadata?['full_name'] ?? 
                   supabaseUser.email?.split('@')[0] ?? 
                   'Utilisateur',
      avatarUrl: supabaseUser.userMetadata?['avatar_url'],
      createdAt: supabaseUser.createdAt != null 
          ? DateTime.parse(supabaseUser.createdAt!) 
          : DateTime.now(),
      lastSignInAt: supabaseUser.lastSignInAt != null 
          ? DateTime.parse(supabaseUser.lastSignInAt!) 
          : null,
      isEmailConfirmed: supabaseUser.emailConfirmedAt != null,
      metadata: supabaseUser.userMetadata,
    );
  }

  /// Copier avec de nouvelles valeurs
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    bool? isEmailConfirmed,
    Map<String, dynamic>? metadata,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      isEmailConfirmed: isEmailConfirmed ?? this.isEmailConfirmed,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convertir en Map pour serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastSignInAt': lastSignInAt?.toIso8601String(),
      'isEmailConfirmed': isEmailConfirmed,
      'metadata': metadata,
    };
  }

  /// Créer depuis Map
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      avatarUrl: map['avatarUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      lastSignInAt: map['lastSignInAt'] != null 
          ? DateTime.parse(map['lastSignInAt']) 
          : null,
      isEmailConfirmed: map['isEmailConfirmed'] ?? false,
      metadata: map['metadata'],
    );
  }

  /// Obtenir les initiales pour l'avatar
  String get initials {
    if (displayName.isNotEmpty) {
      List<String> names = displayName.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        return displayName[0].toUpperCase();
      }
    }
    return email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }

  /// Vérifier si l'utilisateur a un profil complet
  bool get hasCompleteProfile {
    return displayName.isNotEmpty && isEmailConfirmed;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.avatarUrl == avatarUrl &&
        other.createdAt == createdAt &&
        other.lastSignInAt == lastSignInAt &&
        other.isEmailConfirmed == isEmailConfirmed;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        avatarUrl.hashCode ^
        createdAt.hashCode ^
        lastSignInAt.hashCode ^
        isEmailConfirmed.hashCode;
  }

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, displayName: $displayName, isEmailConfirmed: $isEmailConfirmed)';
  }
}