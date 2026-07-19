/// Google login request body matching backend GoogleLoginRequest record.
class GoogleLoginRequestModel {
  const GoogleLoginRequestModel({required this.idToken});

  final String idToken;

  Map<String, dynamic> toJson() => {'idToken': idToken};
}
