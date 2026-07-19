import '../../domain/entities/user_entity.dart';

/// Backend UserResponse DTO.
///
/// Matches the Java record:
/// ```json
/// {
///   "userId": "uuid",
///   "fullName": "...",
///   "username": "...",
///   "email": "...",
///   "phoneNumber": "...",
///   "avatarUrl": "...",
///   "bio": "...",
///   "universityName": "...",
///   "workStatus": "STUDENT",
///   "location": "...",
///   "emailVerified": true,
///   "accountStatus": "ACTIVE",
///   "totalXp": 0,
///   "level": 1,
///   "preferredLanguage": "ENGLISH",
///   "role": "USER",
///   "active": true
/// }
/// ```
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
    );
  }

  factory UserResponseModel.fromJson(Map<String, dynamic> json) {
    return UserResponseModel(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      universityName: json['universityName'] as String?,
      workStatus: json['workStatus'] as String?,
      location: json['location'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      accountStatus: json['accountStatus'] as String? ?? 'PENDING',
      totalXp: json['totalXp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'ENGLISH',
      role: json['role'] as String? ?? 'USER',
      active: json['active'] as bool? ?? false,
    );
  }
}
