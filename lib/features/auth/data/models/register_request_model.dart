/// Register request body matching backend RegisterRequest record.
class RegisterRequestModel {
  const RegisterRequestModel({
    required this.fullName,
    required this.username,
    required this.email,
    this.phoneNumber,
    required this.password,
    this.universityName,
    this.workStatus,
    this.preferredLanguage,
  });

  final String fullName;
  final String username;
  final String email;
  final String? phoneNumber;
  final String password;
  final String? universityName;
  final String? workStatus;
  final String? preferredLanguage;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'universityName': universityName,
        'workStatus': workStatus,
        'preferredLanguage': preferredLanguage,
      };
}
