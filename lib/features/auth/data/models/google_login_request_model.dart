class GoogleLoginRequestModel {
  const GoogleLoginRequestModel({required this.idToken});

  final String idToken;

  Map<String, dynamic> toJson() => {'idToken': idToken};
}
