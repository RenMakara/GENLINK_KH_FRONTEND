/// Refresh token request matching backend RefreshTokenRequest record.
class RefreshTokenRequestModel {
  const RefreshTokenRequestModel({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}
