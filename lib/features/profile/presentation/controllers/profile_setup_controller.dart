import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../media/domain/entities/media_entity.dart';
import '../../../media/domain/media_upload_service.dart';
import '../../../media/presentation/media_picker.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileSetupController extends GetxController {
  ProfileSetupController({
    required this.repository,
    this.mediaPicker,
    this.mediaUploadService,
  });

  final ProfileRepository repository;
  final MediaPicker? mediaPicker;
  final MediaUploadService? mediaUploadService;

  MediaPicker get _picker =>
      mediaPicker ??
      (Get.isRegistered<MediaPicker>()
          ? Get.find<MediaPicker>()
          : MediaPicker());

  MediaUploadService? get _uploadService =>
      mediaUploadService ??
      (Get.isRegistered<MediaUploadService>()
          ? Get.find<MediaUploadService>()
          : null);

  static const totalSteps = 3;

  static const minInterests = 2;

  static const roles = <String>[
    'STUDENT',
    'YOUNG_PROFESSIONAL',
    'CREATOR',
    'FREELANCER',
  ];

  final isSaving = false.obs;
  final currentStep = 1.obs;

  final avatarUrl = ''.obs;
  final avatarBytes = Rxn<Uint8List>();
  final isUploadingAvatar = false.obs;
  final avatarUploadProgress = RxnDouble();

  final displayName = ''.obs;
  final role = RxnString();
  final universityName = ''.obs;
  final location = ''.obs;

  final bio = ''.obs;
  final links = <String>['', ''].obs;

  final catalog = <InterestEntity>[].obs;
  final selectedInterestIds = <String>{}.obs;
  final isLoadingCatalog = false.obs;

  bool get hasEnoughInterests => selectedInterestIds.length >= minInterests;

  Future<bool> pickAndUploadAvatar({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return false;

      avatarBytes.value = picked.bytes;

      final uploadService = _uploadService;
      if (uploadService == null) {
        avatarUrl.value = 'local_preview';
        return true;
      }

      isUploadingAvatar.value = true;
      avatarUploadProgress.value = 0.0;

      final media = await uploadService.upload(
        bytes: picked.bytes,
        contentType: picked.contentType,
        purpose: MediaPurpose.avatar,
        width: picked.width,
        height: picked.height,
        onProgress: (fraction) => avatarUploadProgress.value = fraction,
      );

      avatarUrl.value = media.url;
      try {
        await repository.updateAvatarFromMedia(media.mediaId);
      } catch (_) {
        await repository.updateAvatar(media.url);
      }
      return true;
    } on AppError catch (e) {
      AppSnackbar.error(e.message);
      return false;
    } catch (_) {
      AppSnackbar.error('common.error'.tr);
      return false;
    } finally {
      isUploadingAvatar.value = false;
      avatarUploadProgress.value = null;
    }
  }

  void removeAvatar() {
    avatarUrl.value = '';
    avatarBytes.value = null;
  }

  Future<void> submitStep1() async {
    final saved = await _save(() async {
      await repository.updateProfile(
        fullName: _blankToNull(displayName.value),
        workStatus: role.value,
        universityName: _blankToNull(universityName.value),
        location: _blankToNull(location.value),
      );
      final avatar = avatarUrl.value.trim();
      if (avatar.isNotEmpty && avatar != 'local_preview') {
        try {
          await repository.updateAvatar(avatar);
        } catch (_) {}
      }
    });
    if (saved) goToStep(2);
  }


  Future<void> submitStep2() async {
    final saved = await _save(() async {
      final trimmedBio = _blankToNull(bio.value);
      if (trimmedBio != null) {
        await repository.updateProfile(bio: trimmedBio);
      }
      const platforms = ['WEBSITE', 'OTHER'];
      for (var i = 0; i < links.length && i < platforms.length; i++) {
        final url = links[i].trim();
        if (url.isEmpty) continue;
        await repository.upsertSocialLink(platform: platforms[i], url: url);
      }
    });
    if (saved) goToStep(3);
  }


  Future<void> loadCatalog() async {
    if (catalog.isNotEmpty) return;
    isLoadingCatalog.value = true;
    try {
      catalog.value = await repository.getInterestCatalog();
    } catch (_) {
    } finally {
      isLoadingCatalog.value = false;
    }
  }

  void toggleInterest(String interestId) {
    if (selectedInterestIds.contains(interestId)) {
      selectedInterestIds.remove(interestId);
    } else {
      selectedInterestIds.add(interestId);
    }
  }

  Future<void> submitStep3() async {
    final saved = await _save(() async {
      await repository.replaceInterests(selectedInterestIds.toList());
    });
    if (saved) finish();
  }


  void goToStep(int step) => currentStep.value = step;

  void finish() => Get.offAllNamed<void>(AppRoutes.home);


  static String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<bool> _save(Future<void> Function() action) async {
    isSaving.value = true;
    try {
      await action();
      return true;
    } on AppError catch (e) {
      AppSnackbar.error(e.message);
      return false;
    } catch (_) {
      AppSnackbar.error('common.error'.tr);
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
