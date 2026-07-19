import 'user_response_model.dart';

/// Backend AuthResponse DTO.
///
/// Contract:
/// ```json
/// {
///   "accessToken": "...",
///   "refreshToken": "...",
///   "tokenType": "Bearer",
///   "user": { ... }
/// }
/// ```
class AuthResponseModel {
  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final UserResponseModel user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      user: UserResponseModel.fromJson(
        json['user'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
