import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/app_translations.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/design_system/theme/app_theme.dart';
import 'package:genlink_frontend/features/media/domain/media_upload_service.dart';
import 'package:genlink_frontend/features/media/presentation/media_picker.dart';
import 'package:genlink_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:genlink_frontend/features/profile/presentation/controllers/profile_setup_controller.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockMediaPicker extends Mock implements MediaPicker {}

class _MockMediaUploadService extends Mock implements MediaUploadService {}

// Minimal valid 1x1 transparent PNG
final _validPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockProfileRepository repository;
  late _MockMediaPicker mediaPicker;
  late _MockMediaUploadService mediaUploadService;
  late ProfileSetupController controller;

  setUp(() {
    Get.testMode = true;
    repository = _MockProfileRepository();
    mediaPicker = _MockMediaPicker();
    mediaUploadService = _MockMediaUploadService();

    when(() => repository.getInterestCatalog()).thenAnswer((_) async => []);

    controller = ProfileSetupController(
      repository: repository,
      mediaPicker: mediaPicker,
      mediaUploadService: mediaUploadService,
    );
    Get.put<ProfileSetupController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestWidget() {
    return GetMaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      translations: AppTranslations(),
      locale: LocalizationService.englishLocale,
      fallbackLocale: LocalizationService.englishLocale,
      theme: AppTheme.lightFor('en'),
      home: const ProfileSetupScreen(),
    );
  }

  testWidgets('renders step 1 with upload photo and skip button',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.text('Set up your profile'), findsOneWidget);
    expect(find.text('Upload photo'), findsOneWidget);
    expect(find.text('JPG, PNG or GIF'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
  });

  testWidgets('tapping upload photo opens bottom sheet with gallery and camera',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    final uploadBtn = find.text('Upload photo');
    expect(uploadBtn, findsOneWidget);
    await tester.tap(uploadBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Remove photo'), findsNothing);
  });

  testWidgets(
      'when avatar is set, shows Change photo and bottom sheet includes Remove photo',
      (tester) async {
    controller.avatarBytes.value = _validPng;

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.text('Change photo'), findsOneWidget);

    await tester.tap(find.text('Change photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Remove photo'), findsOneWidget);

    await tester.tap(find.text('Remove photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.avatarBytes.value, isNull);
    expect(controller.avatarUrl.value, isEmpty);
    expect(find.text('Upload photo'), findsOneWidget);
  });
}
