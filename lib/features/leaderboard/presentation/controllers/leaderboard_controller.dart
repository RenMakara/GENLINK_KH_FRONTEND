import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/models/leaderboard_models.dart';
import '../../domain/repositories/leaderboard_repository.dart';

class LeaderboardController extends GetxController {
  LeaderboardController({LeaderboardRepository? repository})
    : _repository =
          repository ??
          (Get.isRegistered<LeaderboardRepository>()
              ? Get.find<LeaderboardRepository>()
              : null);

  final LeaderboardRepository? _repository;

  final selectedCategory = LeaderboardCategory.overallXp.obs;
  final selectedPeriod = LeaderboardPeriod.allTime.obs;
  final response = Rxn<LeaderboardResponse>();
  final entries = <LeaderboardEntry>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final repository = _repository;
      if (repository == null) {
        throw StateError('Leaderboard repository is unavailable');
      }
      final loaded = await repository.getLeaderboard(
        category: selectedCategory.value,
        period: selectedPeriod.value,
      );
      final normalized = loaded.markCurrentUserByRank();
      response.value = normalized;
      entries.assignAll(normalized.entries);
    } catch (error) {
      response.value = null;
      entries.clear();
      errorMessage.value = _messageForError(error);
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(LeaderboardCategory category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    load();
  }

  void selectPeriod(LeaderboardPeriod period) {
    if (selectedPeriod.value == period) return;
    selectedPeriod.value = period;
    load();
  }

  LeaderboardMe? get me => response.value?.me;

  LeaderboardEntry? get topUser => entries.isEmpty ? null : entries.first;

  String get categoryLabel => selectedCategory.value.translationKey.tr;

  String get periodLabel => selectedPeriod.value.translationKey.tr;

  String _messageForError(Object error) {
    if (error is AppError && error.isUnauthorized) {
      return 'leaderboard.sessionExpired'.tr;
    }
    final translated = 'leaderboard.loadFailed'.tr;
    return translated == 'leaderboard.loadFailed'
        ? 'common.requestFailed'.tr
        : translated;
  }
}
