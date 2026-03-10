/// Mirrors the `users` table row.
class UserModel {
  final int id;
  final String phone;
  final String? name;
  final UserType? userType;
  final String? city;
  final String? companyName;
  final bool isActive;
  final int trialDays;
  final DateTime? trialEndsAt;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final String? currentSessionToken;
  final String? userCode;

  const UserModel({
    required this.id,
    required this.phone,
    this.name,
    this.userType,
    this.city,
    this.companyName,
    required this.isActive,
    required this.trialDays,
    this.trialEndsAt,
    this.lastLoginAt,
    required this.createdAt,
    this.currentSessionToken,
    this.userCode,
  });

  /// Days left in free trial (0 if expired).
  int get trialDaysLeft {
    if (trialEndsAt == null) return 0;
    final diff = trialEndsAt!.difference(DateTime.now().toUtc()).inDays;
    return diff.clamp(0, 9999);
  }

  bool get isTrial     => trialDaysLeft > 0;
  bool get profileDone => name != null && name!.isNotEmpty && companyName != null;

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        id:           m['id'] as int,
        phone:        m['phone'] as String,
        name:         m['name'] as String?,
        userType:     UserType.fromString(m['user_type'] as String?),
        city:         m['city'] as String?,
        companyName:  m['company_name'] as String?,
        isActive:     (m['is_active'] as bool?) ?? true,
        trialDays:    (m['trial_days'] as int?) ?? 30,
        trialEndsAt:  m['trial_ends_at'] as DateTime?,
        lastLoginAt:  m['last_login_at'] as DateTime?,
        createdAt:    (m['created_at'] as DateTime?) ?? DateTime.now(),
        currentSessionToken: m['current_session_token'] as String?,
        userCode:     m['user_code'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id':            id,
        'phone':         phone,
        'name':          name,
        'user_type':     userType?.value,
        'city':          city,
        'company_name':  companyName,
        'is_active':     isActive,
        'trial_days':    trialDays,
        'trial_ends_at': trialEndsAt?.toIso8601String(),
        'last_login_at': lastLoginAt?.toIso8601String(),
        'created_at':    createdAt.toIso8601String(),
        'current_session_token': currentSessionToken,
        'user_code':     userCode,
      };
}

// ─── Enums ────────────────────────────────────────────────────────────────────

enum UserType {
  broker('Broker'),
  builder('Builder');

  const UserType(this.value);
  final String value;

  static UserType? fromString(String? s) {
    if (s == null) return null;
    return UserType.values.firstWhere(
      (e) => e.value.toLowerCase() == s.toLowerCase(),
      orElse: () => UserType.broker,
    );
  }
}
