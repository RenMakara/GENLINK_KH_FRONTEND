import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

/// Drives the three-step profile setup shown right after registration.
///
/// Each step saves as the user leaves it rather than batching everything to
/// the end, so someone who drops out halfway keeps what they already
/// entered. Every step is skippable — the account is already usable, this
/// only enriches it.
class ProfileSetupController extends GetxController {
  ProfileSetupController({required ProfileRepository repository})
      : _repository = repository;

  final ProfileRepository _repository;

  static const totalSteps = 3;

  /// Minimum interests before step 3 can be completed, per the design.
  static const minInterests = 2;

  /// The four roles offered in the design, as backend `WorkStatus` values.
  static const roles = <String>[
    'STUDENT',
    'YOUNG_PROFESSIONAL',
    'CREATOR',
    'FREELANCER',
  ];

  final isSaving = false.obs;
  final currentStep = 1.obs;

  // Step 1
  final avatarUrl = ''.obs;
  final displayName = ''.obs;
  final role = RxnString();
  final universityName = ''.obs;
  final location = ''.obs;

  // Step 2
  final bio = ''.obs;
  final links = <String>['', ''].obs;

  // Step 3
  final catalog = <InterestEntity>[].obs;
  final selectedInterestIds = <String>{}.obs;
  final isLoadingCatalog = false.obs;

  bool get hasEnoughInterests =>
      selectedInterestIds.length >= minInterests;

  // ── Step 1 ────────────────────────────────────────────────────────────

  Future<void> submitStep1() async {
    final saved = await _save(() async {
      await _repository.updateProfile(
        fullName: _blankToNull(displayName.value),
        workStatus: role.value,
        universityName: _blankToNull(universityName.value),
        location: _blankToNull(location.value),
      );
      // Avatar has its own endpoint.
      final avatar = avatarUrl.value.trim();
      if (avatar.isNotEmpty) await _repository.updateAvatar(avatar);
    });
    if (saved) goToStep(2);
  }

  // ── Step 2 ────────────────────────────────────────────────────────────

  Future<void> submitStep2() async {
    final saved = await _save(() async {
      final trimmedBio = _blankToNull(bio.value);
      if (trimmedBio != null) {
        await _repository.updateProfile(bio: trimmedBio);
      }
      // The design offers two free-form links. The backend keys social
      // links by platform and allows one per platform, so the first is
      // stored as WEBSITE and the second as OTHER.
      const platforms = ['WEBSITE', 'OTHER'];
      for (var i = 0; i < links.length && i < platforms.length; i++) {
        final url = links[i].trim();
        if (url.isEmpty) continue;
        await _repository.upsertSocialLink(platform: platforms[i], url: url);
      }
    });
    if (saved) goToStep(3);
  }

  // ── Step 3 ────────────────────────────────────────────────────────────

  Future<void> loadCatalog() async {
    if (catalog.isNotEmpty) return;
    isLoadingCatalog.value = true;
    try {
      catalog.value = await _repository.getInterestCatalog();
    } catch (_) {
      // Leave it empty; the screen shows its own empty state and the step
      // can still be skipped.
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

  // ── Navigation ────────────────────────────────────────────────────────

  void goToStep(int step) => currentStep.value = step;

  /// Leaves setup for the app. Used by both "Skip for now" and the final
  /// step, since the account is already active either way.
  void finish() => Get.offAllNamed<void>(AppRoutes.home);

  // ── Helpers ───────────────────────────────────────────────────────────

  /// The update request is a partial patch and blank strings would
  /// overwrite real values with "", so empty fields are dropped.
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
