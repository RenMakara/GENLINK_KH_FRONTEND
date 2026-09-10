class VerifyEmailRequestModel {
  const VerifyEmailRequestModel({required this.email, required this.otp});

  final String email;
  final String otp;

  Map<String, dynamic> toJson() => {'email': email, 'otp': otp};
}
