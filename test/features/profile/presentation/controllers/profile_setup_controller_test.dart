import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/errors/app_error.dart';
import 'package:genlink_frontend/features/media/domain/entities/media_entity.dart';
import 'package:genlink_frontend/features/media/domain/media_upload_service.dart';
import 'package:genlink_frontend/features/media/presentation/media_picker.dart';
import 'package:genlink_frontend/features/profile/domain/entities/profile_entity.dart';
import 'package:genlink_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:genlink_frontend/features/profile/presentation/controllers/profile_setup_controller.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockMediaPicker extends Mock implements MediaPicker {}

class _MockMediaUploadService extends Mock implements MediaUploadService {}

const _sampleProfile = ProfileEntity(
  userId: 'user-1',
  fullName: 'Sok Kha',
  username: 'sokkha',
  email: 'sokkha@genlink.kh',
  emailVerified: true,
  accountStatus: 'ACTIVE',
  totalXp: 0,
  level: 1,
  preferredLanguage: 'ENGLISH',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(MediaPurpose.avatar);
    registerFallbackValue(ImageSource.gallery);
  });

  late _MockProfileRepository repository;
  late _MockMediaPicker mediaPicker;
  late _MockMediaUploadService mediaUploadService;
  late ProfileSetupController controller;

  setUp(() {
    Get.testMode = true;
    repository = _MockProfileRepository();
    mediaPicker = _MockMediaPicker();
    mediaUploadService = _MockMediaUploadService();

    when(
      () => repository.updateProfile(
        fullName: any(named: 'fullName'),
        username: any(named: 'username'),
        phoneNumber: any(named: 'phoneNumber'),
        avatarUrl: any(named: 'avatarUrl'),
        bio: any(named: 'bio'),
        dateOfBirth: any(named: 'dateOfBirth'),
        gender: any(named: 'gender'),
        universityName: any(named: 'universityName'),
        workStatus: any(named: 'workStatus'),
        location: any(named: 'location'),
        preferredLanguage: any(named: 'preferredLanguage'),
        coverPreset: any(named: 'coverPreset'),
      ),
    ).thenAnswer((_) async => _sampleProfile);

    when(() => repository.updateAvatar(any()))
        .thenAnswer((_) async => _sampleProfile);
    when(() => repository.updateAvatarFromMedia(any()))
        .thenAnswer((_) async => _sampleProfile);

    controller = ProfileSetupController(
      repository: repository,
      mediaPicker: mediaPicker,
      mediaUploadService: mediaUploadService,
    );
  });

  tearDown(() {
    Get.reset();
  });

  group('ProfileSetupController photo upload', () {
    test('pickAndUploadAvatar successfully picks, uploads and saves avatar',
        () async {
      final dummyBytes = Uint8List.fromList([1, 2, 3, 4]);
      final pickedMedia = PickedMedia(
        bytes: dummyBytes,
        contentType: 'image/jpeg',
      );

      when(() => mediaPicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => pickedMedia);

      when(
        () => mediaUploadService.upload(
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
          purpose: MediaPurpose.avatar,
          width: any(named: 'width'),
          height: any(named: 'height'),
          durationMs: any(named: 'durationMs'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer(
        (_) async => const MediaEntity(
          mediaId: 'media-123',
          url: 'https://cdn.genlink.kh/avatars/user-1.jpg',
          contentType: 'image/jpeg',
          sizeBytes: 4,
        ),
      );

      final result = await controller.pickAndUploadAvatar(
        source: ImageSource.gallery,
      );

      expect(result, isTrue);
      expect(controller.avatarUrl.value,
          'https://cdn.genlink.kh/avatars/user-1.jpg');
      expect(controller.avatarBytes.value, dummyBytes);
      expect(controller.isUploadingAvatar.value, isFalse);

      verify(() => repository.updateAvatarFromMedia('media-123')).called(1);
    });

    test('pickAndUploadAvatar returns false when user cancels picker',
        () async {
      when(() => mediaPicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => null);

      final result = await controller.pickAndUploadAvatar(
        source: ImageSource.gallery,
      );

      expect(result, isFalse);
      expect(controller.avatarUrl.value, isEmpty);
      expect(controller.avatarBytes.value, isNull);
      expect(controller.isUploadingAvatar.value, isFalse);
      verifyNever(() => mediaUploadService.upload(
            bytes: any(named: 'bytes'),
            contentType: any(named: 'contentType'),
            purpose: any(named: 'purpose'),
          ));
    });

    test('pickAndUploadAvatar handles upload failure gracefully', () async {
      final dummyBytes = Uint8List.fromList([1, 2, 3]);
      when(() => mediaPicker.pickImage(source: ImageSource.camera)).thenAnswer(
        (_) async => PickedMedia(bytes: dummyBytes, contentType: 'image/jpeg'),
      );

      when(
        () => mediaUploadService.upload(
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
          purpose: any(named: 'purpose'),
          width: any(named: 'width'),
          height: any(named: 'height'),
          durationMs: any(named: 'durationMs'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenThrow(const AppError(
        message: 'Upload failed',
        errorCode: 'UPLOAD_FAILED',
      ));

      final result = await controller.pickAndUploadAvatar(
        source: ImageSource.camera,
      );

      expect(result, isFalse);
      expect(controller.isUploadingAvatar.value, isFalse);
      expect(controller.avatarUploadProgress.value, isNull);
    });

    test('removeAvatar resets avatar state', () {
      controller.avatarUrl.value = 'https://some-avatar.jpg';
      controller.avatarBytes.value = Uint8List.fromList([1, 2]);

      controller.removeAvatar();

      expect(controller.avatarUrl.value, isEmpty);
      expect(controller.avatarBytes.value, isNull);
    });

    test('submitStep1 updates profile and avatar then navigates to step 2',
        () async {
      controller.displayName.value = 'Sok Kha';
      controller.role.value = 'STUDENT';
      controller.avatarUrl.value = 'https://cdn.genlink.kh/avatar.jpg';

      await controller.submitStep1();

      verify(
        () => repository.updateProfile(
          fullName: 'Sok Kha',
          workStatus: 'STUDENT',
          universityName: null,
          location: null,
        ),
      ).called(1);
      verify(() => repository.updateAvatar('https://cdn.genlink.kh/avatar.jpg'))
          .called(1);
      expect(controller.currentStep.value, 2);
    });
  });
}
