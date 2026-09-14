import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/profile/domain/entities/profile_entity.dart';
import 'package:genlink_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:genlink_frontend/features/profile/presentation/bindings/profile_binding.dart';
import 'package:genlink_frontend/features/profile/presentation/controllers/profile_controller.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

const _updatedOwnerProfile = ProfileEntity(
  userId: 'owner-1',
  fullName: 'Updated Owner',
  username: 'updated_owner',
  email: 'owner@genlink.kh',
  avatarUrl: 'https://cdn.genlink.kh/avatar.jpg',
  coverPreset: 7,
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 200,
  level: 3,
  preferredLanguage: 'ENGLISH',
);

const _cachedUser = UserEntity(
  id: 'owner-1',
  fullName: 'Old Owner',
  username: 'old_owner',
  email: 'owner@genlink.kh',
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 100,
  level: 2,
  preferredLanguage: 'ENGLISH',
  role: 'ADMIN',
  active: true,
);

const _publicInterest = InterestEntity(
  interestId: 'interest-1',
  code: 'FLUTTER',
  name: 'Flutter',
);

const _publicPortfolio = PortfolioItemEntity(
  portfolioId: 'portfolio-1',
  title: 'Public project',
);

const _publicLink = SocialLinkEntity(
  platform: 'GITHUB',
  url: 'https://github.com/public-user',
);

const _publicProfile = PublicProfileEntity(
  userId: 'public-1',
  fullName: 'Public User',
  username: 'public_user',
  totalXp: 500,
  level: 6,
  interests: [_publicInterest],
  portfolio: [_publicPortfolio],
  socialLinks: [_publicLink],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockProfileRepository repository;

  setUp(() {
    repository = _MockProfileRepository();
  });

  tearDown(Get.reset);

  test('public controller loads only public-safe profile data', () async {
    when(
      () => repository.getPublicProfile('public_user'),
    ).thenAnswer((_) async => _publicProfile);
    final controller = ProfileController(
      repository: repository,
      viewingUsername: 'public_user',
    );

    await controller.load();

    expect(controller.isOwner, isFalse);
    expect(controller.publicProfile.value, same(_publicProfile));
    expect(controller.interests, [_publicInterest]);
    expect(controller.portfolio, [_publicPortfolio]);
    expect(controller.socialLinks, [_publicLink]);
    verifyNever(() => repository.getMyProfile());
    verifyNever(() => repository.getMyInterests());
    verifyNever(() => repository.getPortfolio());
    verifyNever(() => repository.getSocialLinks());
    verifyNever(() => repository.getBadges());
    verifyNever(() => repository.getSavedItems());
  });

  test('public controller toggles the API-backed follow state', () async {
    when(
      () => repository.getPublicProfile('public_user'),
    ).thenAnswer((_) async => _publicProfile);
    when(() => repository.getFollowStats('public-1')).thenAnswer(
      (_) async =>
          const FollowStatsEntity(followers: 10, following: 4, friend: false),
    );
    when(
      () => repository.followUser('public-1'),
    ).thenAnswer((_) async => 'ACCEPTED');
    when(() => repository.unfollowUser('public-1')).thenAnswer((_) async {});

    final controller = ProfileController(
      repository: repository,
      viewingUsername: 'public_user',
    );

    await controller.load();
    expect(await controller.toggleFollow(), isTrue);
    expect(controller.followStats.value?.followStatus, 'ACCEPTED');
    expect(controller.followStats.value?.followers, 11);

    expect(await controller.toggleFollow(), isTrue);
    expect(controller.followStats.value?.followStatus, isNull);
    expect(controller.followStats.value?.followers, 10);
    verify(() => repository.followUser('public-1')).called(1);
    verify(() => repository.unfollowUser('public-1')).called(1);
  });

  test('owner mutations notify the cached-identity synchronizer', () async {
    when(
      () => repository.updateProfile(
        fullName: 'Updated Owner',
        username: null,
        phoneNumber: null,
        bio: null,
        dateOfBirth: null,
        gender: null,
        universityName: null,
        workStatus: null,
        location: null,
      ),
    ).thenAnswer((_) async => _updatedOwnerProfile);
    ProfileEntity? synchronized;
    final controller = ProfileController(
      repository: repository,
      onOwnerProfileChanged: (profile) => synchronized = profile,
    );

    final result = await controller.updateProfile(fullName: 'Updated Owner');

    expect(result, isTrue);
    expect(controller.profile.value, same(_updatedOwnerProfile));
    expect(synchronized, same(_updatedOwnerProfile));
  });

  test('owner cover selection uses the persisted cover preset', () async {
    when(
      () => repository.updateProfile(coverPreset: 7),
    ).thenAnswer((_) async => _updatedOwnerProfile);
    final controller = ProfileController(repository: repository);

    expect(await controller.updateCoverPreset(7), isTrue);
    expect(controller.profile.value?.coverPreset, 7);
    verify(() => repository.updateProfile(coverPreset: 7)).called(1);
  });

  test(
    'profile screen resolves owner and public controllers independently',
    () {
      final ownerController = ProfileController(repository: repository);
      final publicController = ProfileController(
        repository: repository,
        viewingUsername: 'public_user',
      );
      Get.put<ProfileController>(ownerController);
      Get.put<ProfileController>(
        publicController,
        tag: ProfileController.publicTag('public_user'),
      );

      expect(const ProfileScreen().controller, same(ownerController));
      expect(
        const ProfileScreen(viewingUsername: 'public_user').controller,
        same(publicController),
      );
    },
  );

  test(
    'owner binding synchronizes profile responses into AuthController',
    () async {
      when(
        () => repository.getMyProfile(),
      ).thenAnswer((_) async => _updatedOwnerProfile);
      when(() => repository.getMyInterests()).thenAnswer((_) async => []);
      when(() => repository.getPortfolio()).thenAnswer((_) async => []);
      when(() => repository.getSocialLinks()).thenAnswer((_) async => []);
      when(() => repository.getBadges()).thenAnswer((_) async => []);
      when(() => repository.getSavedItems()).thenAnswer((_) async => []);

      final auth = AuthController(
        authRepository: _MockAuthRepository(),
        secureStorage: _MockSecureStorage(),
        localization: LocalizationService(localStorage: LocalStorage()),
      )..currentUser.value = _cachedUser;
      Get
        ..put<AuthController>(auth)
        ..put<ProfileRepository>(repository);
      ProfileBinding().dependencies();

      final controller = Get.find<ProfileController>();
      await controller.load();

      final synchronized = auth.currentUser.value!;
      expect(synchronized.fullName, _updatedOwnerProfile.fullName);
      expect(synchronized.username, _updatedOwnerProfile.username);
      expect(synchronized.avatarUrl, _updatedOwnerProfile.avatarUrl);
      expect(synchronized.role, _cachedUser.role);
      expect(synchronized.active, _cachedUser.active);
    },
  );
}
