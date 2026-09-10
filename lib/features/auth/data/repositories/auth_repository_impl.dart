import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response_model.dart';
import '../models/user_response_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDatasource _remote;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final model = await _remote.login(email: email, password: password);
    return _mapToSession(model);
  }

  @override
  Future<void> register({
    required String fullName,
    required String username,
    required String email,
    String? phoneNumber,
    required String password,
    String? universityName,
    String? workStatus,
    String? preferredLanguage,
  }) async {
    await _remote.register(
      fullName: fullName,
      username: username,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      universityName: universityName,
      workStatus: workStatus,
      preferredLanguage: preferredLanguage,
    );
  }

  @override
  Future<AuthSession> googleLogin({required String idToken}) async {
    final model = await _remote.googleLogin(idToken: idToken);
    return _mapToSession(model);
  }

  @override
  Future<AuthSession> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final model = await _remote.verifyEmail(email: email, otp: otp);
    return _mapToSession(model);
  }

  @override
  Future<AuthSession> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final model = await _remote.verifyOtp(email: email, otp: otp);
    return _mapToSession(model);
  }

  @override
  Future<void> resendOtp({required String email}) async {
    await _remote.resendOtp(email: email);
  }

  @override
  Future<void> resendVerificationOtp({required String email}) async {
    await _remote.resendVerificationOtp(email: email);
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _remote.forgotPassword(email: email);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _remote.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
  }

  @override
  Future<AuthSession> refreshToken({required String refreshToken}) async {
    final model = await _remote.refreshToken(refreshToken: refreshToken);
    return _mapToSession(model);
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    final model = await _remote.getCurrentUser();
    return _mapToUserEntity(model);
  }

  @override
  Future<void> logout() async {
    await _remote.logout();
  }


  AuthSession _mapToSession(AuthResponseModel model) {
    return AuthSession(
      accessToken: model.accessToken,
      refreshToken: model.refreshToken,
      tokenType: model.tokenType,
      user: _mapToUserEntity(model.user),
    );
  }

  UserEntity _mapToUserEntity(UserResponseModel model) {
    return UserEntity(
      id: model.userId,
      fullName: model.fullName,
      username: model.username,
      email: model.email,
      phoneNumber: model.phoneNumber,
      avatarUrl: model.avatarUrl,
      bio: model.bio,
      universityName: model.universityName,
      workStatus: model.workStatus,
      location: model.location,
      emailVerified: model.emailVerified,
      accountStatus: model.accountStatus,
      totalXp: model.totalXp,
      level: model.level,
      preferredLanguage: model.preferredLanguage,
      role: model.role,
      active: model.active,
    );
  }
}
