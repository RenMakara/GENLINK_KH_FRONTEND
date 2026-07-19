/// Reset password request matching backend ResetPasswordRequest record.
class ResetPasswordRequestModel {
  const ResetPasswordRequestModel({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  final String email;
  final String otp;
  final String newPassword;

  Map<String, dynamic> toJson() => {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      };
}
