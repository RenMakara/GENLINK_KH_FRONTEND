/// Resend OTP request matching backend ResendOtpRequest record.
class ResendOtpRequestModel {
  const ResendOtpRequestModel({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}
