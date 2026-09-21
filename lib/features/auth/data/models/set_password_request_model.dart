class SetPasswordRequestModel {
  const SetPasswordRequestModel({required this.password});

  final String password;

  Map<String, dynamic> toJson() => {'password': password};
}
