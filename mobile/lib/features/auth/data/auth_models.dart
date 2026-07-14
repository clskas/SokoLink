class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    this.company,
  });

  final String id;
  final String email;
  final String? fullName;
  final Map<String, dynamic>? company;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      company: json['company'] as Map<String, dynamic>?,
    );
  }

  String get companyName => company?['name'] as String? ?? 'Entreprise';
}

class AuthSession {
  AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
