class UserEntity {
  const UserEntity({
    required this.id,
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
  });

  final String id;
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

  UserEntity copyWith({bool? hasPassword}) {
    return UserEntity(
      id: id,
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
      hasPassword: hasPassword ?? this.hasPassword,
    );
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isPending => accountStatus == 'PENDING';
  bool get isActive => accountStatus == 'ACTIVE' && active;
}
