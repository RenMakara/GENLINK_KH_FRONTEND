import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;

import '../../../../core/errors/app_error.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../media/domain/entities/media_entity.dart';
import '../../../media/domain/media_upload_service.dart';
import '../../../media/presentation/media_picker.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileController extends GetxController {
  ProfileController({
    required this._repository,
    this.viewingUsername,
    this.onOwnerProfileChanged,
  });

  final ProfileRepository _repository;
  final void Function(ProfileEntity profile)? onOwnerProfileChanged;

  final String? viewingUsername;

  static String publicTag(String username) => 'public-profile:$username';

  bool get isOwner => viewingUsername == null;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  final profile = Rxn<ProfileEntity>();
  final publicProfile = Rxn<PublicProfileEntity>();
  final interests = <InterestEntity>[].obs;
  final portfolio = <PortfolioItemEntity>[].obs;
  final socialLinks = <SocialLinkEntity>[].obs;
  final badges = <BadgeEntity>[].obs;
  final isBadgesLoading = false.obs;
  final badgesErrorMessage = RxnString();
  final savedItems = <SavedItemEntity>[].obs;
  final followStats = Rxn<FollowStatsEntity>();
  final isRelationshipSaving = false.obs;

  final interestCatalog = <InterestEntity>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    followStats.value = null;

    if (isOwner) {
      final auth = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : null;
      if (auth != null &&
          !auth.isAuthenticated.value &&
          auth.currentUser.value == null) {
        isLoading.value = false;
        return;
      }
    }

    if (!isOwner) {
      try {
        final loaded = await _repository.getPublicProfile(viewingUsername!);
        publicProfile.value = loaded;
        interests.assignAll(loaded.interests);
        portfolio.assignAll(loaded.portfolio);
        socialLinks.assignAll(loaded.socialLinks);
        // The public profile should remain usable if the optional relationship
        // endpoint is slow or unavailable.
        isLoading.value = false;
        await _loadSection(
          () async => followStats.value = await _repository.getFollowStats(
            loaded.userId,
          ),
        );
      } on AppError catch (e) {
        errorMessage.value = e.message;
      } catch (_) {
        errorMessage.value = 'common.error'.tr;
      } finally {
        isLoading.value = false;
      }
      return;
    }

    try {
      _setOwnerProfile(await _repository.getMyProfile());
    } on AppError catch (e) {
      errorMessage.value = e.message;
      isLoading.value = false;
      return;
    } catch (_) {
      errorMessage.value = 'common.error'.tr;
      isLoading.value = false;
      return;
    } finally {
      isLoading.value = false;
    }

    await Future.wait([
      _loadSection(() async {
        final owner = profile.value;
        if (owner == null) return;
        followStats.value = await _repository.getFollowStats(owner.userId);
      }),
      _loadSection(
        () async => interests.value = await _repository.getMyInterests(),
      ),
      _loadSection(
        () async => portfolio.value = await _repository.getPortfolio(),
      ),
      _loadSection(
        () async => socialLinks.value = await _repository.getSocialLinks(),
      ),
      _loadSection(loadBadges),
      _loadSection(
        () async => savedItems.value = await _repository.getSavedItems(),
      ),
    ]);
  }

  Future<void> reload() => load();

  Future<void> reloadSavedItems() async {
    await _loadSection(
      () async => savedItems.value = await _repository.getSavedItems(),
    );
  }

  /// Loads the backend badge catalog, including both earned and locked badges.
  ///
  /// Badge loading has its own state because the profile endpoint and the badge
  /// catalog are separate backend resources. A catalog failure must not be
  /// rendered as a truthful-looking "no badges" state.
  Future<void> loadBadges() async {
    if (!isOwner) return;
    isBadgesLoading.value = true;
    badgesErrorMessage.value = null;
    try {
      badges.assignAll(await _repository.getBadges());
    } on AppError catch (e) {
      badgesErrorMessage.value = e.message;
    } catch (_) {
      badgesErrorMessage.value = 'common.error'.tr;
    } finally {
      isBadgesLoading.value = false;
    }
  }

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
      _setOwnerProfile(
        await _repository.updateProfile(
          fullName: fullName,
          username: username,
          phoneNumber: phoneNumber,
          bio: bio,
          dateOfBirth: dateOfBirth,
          gender: gender,
          universityName: universityName,
          workStatus: workStatus,
          location: location,
        ),
      );
      AppSnackbar.show('profile.updated'.tr);
    });
  }

  Future<bool> updateAvatar(String avatarUrl) {
    return _save(() async {
      _setOwnerProfile(await _repository.updateAvatar(avatarUrl));
    });
  }

  /// Stores only the id of one of the app-bundled cover presets.  The public
  /// profile response carries the same id, so the selected treatment survives
  /// devices and is visible to other people.
  Future<bool> updateCoverPreset(int coverPreset) {
    if (!isOwner || coverPreset < 0 || coverPreset > 9) {
      return Future.value(false);
    }

    return _save(() async {
      _setOwnerProfile(
        await _repository.updateProfile(coverPreset: coverPreset),
      );
      AppSnackbar.show('profile.coverUpdated'.tr);
    });
  }

  Future<bool> pickAndUploadAvatar({
    ImageSource source = ImageSource.gallery,
  }) async {
    final picked = await Get.find<MediaPicker>().pickImage(source: source);
    if (picked == null) return false;

    avatarUploadProgress.value = 0;
    final ok = await _save(() async {
      final media = await Get.find<MediaUploadService>().upload(
        bytes: picked.bytes,
        contentType: picked.contentType,
        purpose: MediaPurpose.avatar,
        width: picked.width,
        height: picked.height,
        onProgress: (fraction) => avatarUploadProgress.value = fraction,
      );
      _setOwnerProfile(await _repository.updateAvatarFromMedia(media.mediaId));
    });
    avatarUploadProgress.value = null;
    return ok;
  }

  final avatarUploadProgress = RxnDouble();

  List<BadgeEntity> get sortedBadges {
    final earned = badges.where((b) => b.earned).toList();
    final locked = badges.where((b) => !b.earned).toList();
    return [...earned, ...locked];
  }

  Future<void> loadInterestCatalog() async {
    if (interestCatalog.isNotEmpty) return;
    await _loadSection(
      () async =>
          interestCatalog.value = await _repository.getInterestCatalog(),
    );
  }

  Future<bool> toggleFollow() async {
    final target = publicProfile.value;
    if (isOwner || target == null || target.userId.isEmpty) return false;
    if (isRelationshipSaving.value) return false;

    final current = followStats.value;
    final wasFollowing = current?.isFollowing ?? false;
    final wasAccepted = current?.isAccepted ?? false;

    isRelationshipSaving.value = true;
    try {
      if (wasFollowing) {
        await _repository.unfollowUser(target.userId);
        followStats.value = FollowStatsEntity(
          followers: wasAccepted && (current?.followers ?? 0) > 0
              ? current!.followers - 1
              : current?.followers ?? 0,
          following: current?.following ?? 0,
          followStatus: null,
          friend: false,
        );
      } else {
        final status = await _repository.followUser(target.userId);
        final accepted = (status ?? 'ACCEPTED') == 'ACCEPTED';
        followStats.value = FollowStatsEntity(
          followers: accepted
              ? (current?.followers ?? 0) + 1
              : current?.followers ?? 0,
          following: current?.following ?? 0,
          followStatus: status ?? 'ACCEPTED',
          friend: current?.friend ?? false,
        );
      }
      return true;
    } on AppError catch (e) {
      AppSnackbar.error(e.message);
      return false;
    } catch (_) {
      AppSnackbar.error('common.error'.tr);
      return false;
    } finally {
      isRelationshipSaving.value = false;
    }
  }

  Future<bool> replaceInterests(List<String> interestIds) {
    return _save(() async {
      interests.value = await _repository.replaceInterests(interestIds);
    });
  }

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
      final current = List<PortfolioItemEntity>.from(portfolio);
      current.removeWhere(
        (existing) =>
            existing.portfolioId.isNotEmpty &&
            existing.portfolioId == item.portfolioId,
      );
      current.insert(0, item);
      portfolio.value = current;
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
      final current = List<PortfolioItemEntity>.from(portfolio);
      final index = current.indexWhere(
        (item) => item.portfolioId == portfolioId,
      );
      if (index >= 0) {
        current[index] = updated;
      } else {
        current.add(updated);
      }
      portfolio.value = current;
    });
  }

  Future<bool> deletePortfolioItem(String portfolioId) {
    return _save(() async {
      await _repository.deletePortfolioItem(portfolioId);
      final current = List<PortfolioItemEntity>.from(portfolio);
      current.removeWhere((item) => item.portfolioId == portfolioId);
      portfolio.value = current;
    });
  }

  Future<bool> upsertSocialLink({
    required String platform,
    required String url,
  }) {
    return _save(() async {
      final link = await _repository.upsertSocialLink(
        platform: platform,
        url: url,
      );
      final current = List<SocialLinkEntity>.from(socialLinks);
      final index = current.indexWhere(
        (existing) => existing.platform == platform,
      );
      if (index >= 0) {
        current[index] = link;
      } else {
        current.add(link);
      }
      socialLinks.value = current;
    });
  }

  Future<bool> deleteSocialLink(String platform) {
    return _save(() async {
      await _repository.deleteSocialLink(platform);
      final current = List<SocialLinkEntity>.from(socialLinks);
      current.removeWhere((link) => link.platform == platform);
      socialLinks.value = current;
    });
  }

  void _setOwnerProfile(ProfileEntity updated) {
    profile.value = updated;
    onOwnerProfileChanged?.call(updated);
  }

  Future<bool> _save(Future<void> Function() action) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    errorMessage.value = null;
    try {
      await action();
      return true;
    } on AppError catch (e) {
      debugPrint('[PROFILE-SAVE] AppError: ${e.message} (${e.errorCode})');
      errorMessage.value = e.message;
      AppSnackbar.error(e.message);
      return false;
    } catch (e, stack) {
      debugPrint('[PROFILE-SAVE] Unexpected error: $e\n$stack');
      errorMessage.value = 'common.error'.tr;
      AppSnackbar.error('common.error'.tr);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _loadSection(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }
}
