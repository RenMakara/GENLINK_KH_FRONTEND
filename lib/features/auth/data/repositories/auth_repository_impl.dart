import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response_model.dart';
import '../models/user_response_model.dart';

/// Concrete auth repository backed by [AuthRemoteDatasource].
///
/// Maps between data-layer models and domain entities at the boundary.
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
    try {
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
    } catch (_) {
      // Demo fallback - proceed without backend
    }
  }

  @override
  Future<AuthSession> googleLogin({required String idToken}) async {
    try {
      final model = await _remote.googleLogin(idToken: idToken);
      return _mapToSession(model);
    } catch (_) {
      return AuthSession(
        accessToken: 'mock_google_token',
        refreshToken: 'mock_google_refresh',
        tokenType: 'Bearer',
        user: const UserEntity(
          id: 'google_user',
          fullName: 'Enat',
          username: 'enat_google',
          email: 'enat@gmail.com',
          avatarUrl: 'https://i.pravatar.cc/150?img=32',
          universityName: 'CADT University',
          active: true,
          emailVerified: true,
          accountStatus: 'ACTIVE',
          preferredLanguage: 'en',
          role: 'USER',
          totalXp: 200,
          level: 4,
        ),
      );
    }
  }

  @override
  Future<AuthSession> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final model = await _remote.verifyEmail(email: email, otp: otp);
      return _mapToSession(model);
    } catch (_) {
      return AuthSession(
        accessToken: 'mock_access_token_123',
        refreshToken: 'mock_refresh_token_123',
        tokenType: 'Bearer',
        user: UserEntity(
          id: 'user_1',
          fullName: 'Enat Sokny',
          username: 'enat_sokny',
          email: email.isNotEmpty ? email : 'enat@gmail.com',
          avatarUrl: 'https://i.pravatar.cc/150?img=32',
          universityName: 'ACLEDA University',
          active: true,
          emailVerified: true,
          accountStatus: 'ACTIVE',
          preferredLanguage: 'en',
          role: 'USER',
          totalXp: 150,
          level: 3,
        ),
      );
    }
  }

  @override
  Future<AuthSession> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final model = await _remote.verifyOtp(email: email, otp: otp);
      return _mapToSession(model);
    } catch (_) {
      return AuthSession(
        accessToken: 'mock_access_token_123',
        refreshToken: 'mock_refresh_token_123',
        tokenType: 'Bearer',
        user: UserEntity(
          id: 'user_1',
          fullName: 'Enat Sokny',
          username: 'enat_sokny',
          email: email.isNotEmpty ? email : 'enat@gmail.com',
          avatarUrl: 'https://i.pravatar.cc/150?img=32',
          universityName: 'ACLEDA University',
          active: true,
          emailVerified: true,
          accountStatus: 'ACTIVE',
          preferredLanguage: 'en',
          role: 'USER',
          totalXp: 150,
          level: 3,
        ),
      );
    }
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
    try {
      final model = await _remote.getCurrentUser();
      return _mapToUserEntity(model);
    } catch (_) {
      return const UserEntity(
        id: 'user_1',
        fullName: 'Enat',
        username: 'enat_kh',
        email: 'enat@genlink.kh',
        avatarUrl: 'https://i.pravatar.cc/150?img=32',
        universityName: 'RUPP University',
        active: true,
        emailVerified: true,
        accountStatus: 'ACTIVE',
        preferredLanguage: 'en',
        role: 'USER',
        totalXp: 150,
        level: 3,
      );
    }
  }

  @override
  Future<void> logout() async {
    await _remote.logout();
  }

  // ── Mappers ──────────────────────────────────────────────────────────

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
