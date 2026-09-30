import '../../domain/entities/user_entity.dart';

class UserResponseModel {
  const UserResponseModel({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    this.universityName,
    this.workStatus,
    this.location,
    required this.emailVerified,
    required this.accountStatus,
    required this.totalXp,
    required this.level,
    required this.preferredLanguage,
    required this.role,
    required this.active,
    this.hasPassword = false,
    this.authProvider = 'LOCAL',
  });

  final String userId;
  final String fullName;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final String? universityName;
  final String? workStatus;
  final String? location;
  final bool emailVerified;
  final String accountStatus;
  final int totalXp;
  final int level;
  final String preferredLanguage;
  final String role;
  final bool active;
  final bool hasPassword;
  final String authProvider;

  UserEntity toEntity() {
    return UserEntity(
      id: userId,
      fullName: fullName,
      username: username,
      email: email,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
      bio: bio,
      universityName: universityName,
      workStatus: workStatus,
      location: location,
      emailVerified: emailVerified,
      accountStatus: accountStatus,
      totalXp: totalXp,
      level: level,
      preferredLanguage: preferredLanguage,
      role: role,
      active: active,
      hasPassword: hasPassword,
      authProvider: authProvider,
    );
  }

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return defaultValue;
  }

  factory UserResponseModel.fromJson(Map<String, dynamic> json) {
    return UserResponseModel(
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? json['phone_number'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      universityName: json['universityName'] as String? ?? json['university_name'] as String?,
      workStatus: json['workStatus'] as String? ?? json['work_status'] as String?,
      location: json['location'] as String?,
      emailVerified: _parseBool(
        json['emailVerified'] ?? json['email_verified'],
        defaultValue: false,
      ),
      accountStatus: json['accountStatus'] as String? ?? json['account_status'] as String? ?? 'PENDING',
      totalXp: (json['totalXp'] ?? json['total_xp']) as int? ?? 0,
      level: json['level'] as int? ?? 1,
      preferredLanguage: json['preferredLanguage'] as String? ?? json['preferred_language'] as String? ?? 'ENGLISH',
      role: json['role'] as String? ?? 'USER',
      active: _parseBool(
        json['active'] ?? json['is_active'],
        defaultValue: false,
      ),
      hasPassword: _parseBool(
        json['hasPassword'] ?? json['has_password'] ?? json['isHasPassword'],
        defaultValue: false,
      ),
      authProvider: () {
        final raw = (json['authProvider'] ?? json['auth_provider'])?.toString().trim();
        if (raw != null && raw.isNotEmpty) return raw;
        final hasPw = _parseBool(
          json['hasPassword'] ?? json['has_password'] ?? json['isHasPassword'],
          defaultValue: false,
        );
        return hasPw ? 'LOCAL' : 'GOOGLE';
      }(),
    );
  }
}
