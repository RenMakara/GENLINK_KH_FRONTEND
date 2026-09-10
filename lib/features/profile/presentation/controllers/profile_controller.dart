import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;

import '../../../../core/errors/app_error.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
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
  final savedItems = <SavedItemEntity>[].obs;

  final interestCatalog = <InterestEntity>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    if (!isOwner) {
      try {
        final loaded = await _repository.getPublicProfile(viewingUsername!);
        publicProfile.value = loaded;
        interests.assignAll(loaded.interests);
        portfolio.assignAll(loaded.portfolio);
        socialLinks.assignAll(loaded.socialLinks);
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
    } catch (_) {
      errorMessage.value = 'common.error'.tr;
    } finally {
      isLoading.value = false;
    }

    await Future.wait([
      _loadSection(
        () async => interests.value = await _repository.getMyInterests(),
      ),
      _loadSection(
        () async => portfolio.value = await _repository.getPortfolio(),
      ),
      _loadSection(
        () async => socialLinks.value = await _repository.getSocialLinks(),
      ),
      _loadSection(() async => badges.value = await _repository.getBadges()),
      _loadSection(
        () async => savedItems.value = await _repository.getSavedItems(),
      ),
    ]);
  }

  Future<void> reload() => load();


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
      final index = portfolio.indexWhere(
        (item) => item.portfolioId == portfolioId,
      );
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


  Future<bool> upsertSocialLink({
    required String platform,
    required String url,
  }) {
    return _save(() async {
      final link = await _repository.upsertSocialLink(
        platform: platform,
        url: url,
      );
      final index = socialLinks.indexWhere(
        (existing) => existing.platform == platform,
      );
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


  void _setOwnerProfile(ProfileEntity updated) {
    profile.value = updated;
    onOwnerProfileChanged?.call(updated);
  }

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

  Future<void> _loadSection(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
    }
  }
}
