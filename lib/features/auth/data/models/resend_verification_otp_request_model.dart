/// Resend verification OTP request matching backend ResendVerificationOtpRequest.
class ResendVerificationOtpRequestModel {
  const ResendVerificationOtpRequestModel({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}
