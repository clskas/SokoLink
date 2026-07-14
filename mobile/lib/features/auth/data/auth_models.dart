class AuthUser {
  AuthUser({
    required this.id,
    this.email,
    this.phone,
    this.fullName,
    this.platformRole,
    this.companyId,
    this.company,
  });

  final String id;
  final String? email;
  final String? phone;
  final String? fullName;
  final String? platformRole;
  final String? companyId;
  final Map<String, dynamic>? company;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      fullName: json['fullName'] as String?,
      platformRole: json['role'] as String?,
      companyId: json['companyId'] as String?,
      company: json['company'] is Map
          ? Map<String, dynamic>.from(json['company'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'fullName': fullName,
        'role': platformRole,
        'companyId': companyId,
        'company': company,
      };

  String get companyName => company?['name'] as String? ?? 'Entreprise';

  List<String> get companyRoles {
    final raw = company?['roles'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  String get plan => company?['plan']?.toString() ?? 'FREE';
  String get planStatus => company?['planStatus']?.toString() ?? 'ACTIVE';
  bool get isPro => plan == 'PRO';
  bool get isAdmin => platformRole == 'ADMIN';

  bool get canSellMp => companyRoles.contains('SUPPLIER_MP');
  bool get canSellFinished => companyRoles.contains('PROCESSOR');
  bool get canManageCatalog => canSellMp || canSellFinished;
  bool get canCreateRfq => companyRoles.contains('BUYER');
  bool get canRespondRfq => canSellMp || canSellFinished;
  bool get canBuy => canCreateRfq;

  List<String> get roleLabels {
    return companyRoles.map((r) {
      switch (r) {
        case 'SUPPLIER_MP':
          return 'Fournisseur MP';
        case 'PROCESSOR':
          return 'Transformateur';
        case 'BUYER':
          return 'Acheteur';
        default:
          return r;
      }
    }).toList();
  }
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
