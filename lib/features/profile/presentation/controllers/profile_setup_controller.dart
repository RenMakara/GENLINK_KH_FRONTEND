import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileSetupController extends GetxController {
  ProfileSetupController({required this._repository});

  final ProfileRepository _repository;

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


  Future<void> submitStep1() async {
    final saved = await _save(() async {
      await _repository.updateProfile(
        fullName: _blankToNull(displayName.value),
        workStatus: role.value,
        universityName: _blankToNull(universityName.value),
        location: _blankToNull(location.value),
      );
      final avatar = avatarUrl.value.trim();
      if (avatar.isNotEmpty) await _repository.updateAvatar(avatar);
    });
    if (saved) goToStep(2);
  }


  Future<void> submitStep2() async {
    final saved = await _save(() async {
      final trimmedBio = _blankToNull(bio.value);
      if (trimmedBio != null) {
        await _repository.updateProfile(bio: trimmedBio);
      }
      const platforms = ['WEBSITE', 'OTHER'];
      for (var i = 0; i < links.length && i < platforms.length; i++) {
        final url = links[i].trim();
        if (url.isEmpty) continue;
        await _repository.upsertSocialLink(platform: platforms[i], url: url);
      }
    });
    if (saved) goToStep(3);
  }


  Future<void> loadCatalog() async {
    if (catalog.isNotEmpty) return;
    isLoadingCatalog.value = true;
    try {
      catalog.value = await _repository.getInterestCatalog();
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
      await _repository.replaceInterests(selectedInterestIds.toList());
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
