import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

/// Owns the signed-in user's profile, interests, portfolio and social links.
///
/// Each section loads independently so one failing call (say, portfolio)
/// does not blank the whole screen.
class ProfileController extends GetxController {
  ProfileController({required this._repository});

  final ProfileRepository _repository;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  final profile = Rxn<ProfileEntity>();
  final interests = <InterestEntity>[].obs;
  final portfolio = <PortfolioItemEntity>[].obs;
  final socialLinks = <SocialLinkEntity>[].obs;
  final badges = <BadgeEntity>[].obs;
  final savedItems = <SavedItemEntity>[].obs;

  /// Full catalog, loaded lazily the first time the interest picker opens.
  final interestCatalog = <InterestEntity>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Load every section. Sections settle independently — a failure in one
  /// leaves the others populated.
  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      profile.value = await _repository.getMyProfile();
    } on AppError catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'common.error'.tr;
    } finally {
      isLoading.value = false;
    }

    await Future.wait([
      _loadSection(
          () async => interests.value = await _repository.getMyInterests()),
      _loadSection(
          () async => portfolio.value = await _repository.getPortfolio()),
      _loadSection(
          () async => socialLinks.value = await _repository.getSocialLinks()),
      _loadSection(() async => badges.value = await _repository.getBadges()),
      _loadSection(
          () async => savedItems.value = await _repository.getSavedItems()),
    ]);
  }

  /// Pull-to-refresh entry point. Named `reload` because `GetxController`
  /// already defines a non-async `refresh()`.
  Future<void> reload() => load();

  // ── Profile ───────────────────────────────────────────────────────────

  Future<bool> updateProfile({
    String? fullName,
    String? username,
    String? phoneNumber,
    String? bio,
    String? dateOfBirth,
    String? gender,
    String? universityName,
    String? workStatus,
    String? location,
  }) {
    return _save(() async {
      profile.value = await _repository.updateProfile(
        fullName: fullName,
        username: username,
        phoneNumber: phoneNumber,
        bio: bio,
        dateOfBirth: dateOfBirth,
        gender: gender,
        universityName: universityName,
        workStatus: workStatus,
        location: location,
      );
      AppSnackbar.show('profile.updated'.tr);
    });
  }

  Future<bool> updateAvatar(String avatarUrl) {
    return _save(() async {
      profile.value = await _repository.updateAvatar(avatarUrl);
    });
  }

  /// Earned badges first, then locked ones — the achievements row shows
  /// what the user has before what they can still get.
  List<BadgeEntity> get sortedBadges {
    final earned = badges.where((b) => b.earned).toList();
    final locked = badges.where((b) => !b.earned).toList();
    return [...earned, ...locked];
  }

  // ── Interests ─────────────────────────────────────────────────────────

  Future<void> loadInterestCatalog() async {
    if (interestCatalog.isNotEmpty) return;
    await _loadSection(
      () async => interestCatalog.value = await _repository.getInterestCatalog(),
    );
  }

  /// Replaces the whole selection — the backend PUT is not additive.
  Future<bool> replaceInterests(List<String> interestIds) {
    return _save(() async {
      interests.value = await _repository.replaceInterests(interestIds);
    });
  }

  // ── Portfolio ─────────────────────────────────────────────────────────

  Future<bool> addPortfolioItem({
    required String title,
    String? description,
    String? link,
    String? imageUrl,
  }) {
    return _save(() async {
      final item = await _repository.createPortfolioItem(
        title: title,
        description: description,
        link: link,
        imageUrl: imageUrl,
      );
      portfolio.add(item);
    });
  }

  Future<bool> updatePortfolioItem({
    required String portfolioId,
    required String title,
    String? description,
    String? link,
    String? imageUrl,
  }) {
    return _save(() async {
      final updated = await _repository.updatePortfolioItem(
        portfolioId: portfolioId,
        title: title,
        description: description,
        link: link,
        imageUrl: imageUrl,
      );
      final index =
          portfolio.indexWhere((item) => item.portfolioId == portfolioId);
      if (index >= 0) {
        portfolio[index] = updated;
      } else {
        portfolio.add(updated);
      }
    });
  }

  Future<bool> deletePortfolioItem(String portfolioId) {
    return _save(() async {
      await _repository.deletePortfolioItem(portfolioId);
      portfolio.removeWhere((item) => item.portfolioId == portfolioId);
    });
  }

  // ── Social links ──────────────────────────────────────────────────────

  Future<bool> upsertSocialLink({
    required String platform,
    required String url,
  }) {
    return _save(() async {
      final link =
          await _repository.upsertSocialLink(platform: platform, url: url);
      final index =
          socialLinks.indexWhere((existing) => existing.platform == platform);
      if (index >= 0) {
        socialLinks[index] = link;
      } else {
        socialLinks.add(link);
      }
    });
  }

  Future<bool> deleteSocialLink(String platform) {
    return _save(() async {
      await _repository.deleteSocialLink(platform);
      socialLinks.removeWhere((link) => link.platform == platform);
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Run a mutation with saving state + snackbar error reporting.
  Future<bool> _save(Future<void> Function() action) async {
    isSaving.value = true;
    errorMessage.value = null;
    try {
      await action();
      return true;
    } on AppError catch (e) {
      errorMessage.value = e.message;
      AppSnackbar.error(e.message);
      return false;
    } catch (_) {
      errorMessage.value = 'common.error'.tr;
      AppSnackbar.error('common.error'.tr);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Load one section, swallowing its error so siblings still render.
  Future<void> _loadSection(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Section stays empty; the screen shows its own empty state.
    }
  }
}
