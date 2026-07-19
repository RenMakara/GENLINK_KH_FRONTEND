/// Forgot password request matching backend ForgotPasswordRequest record.
class ForgotPasswordRequestModel {
  const ForgotPasswordRequestModel({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}
