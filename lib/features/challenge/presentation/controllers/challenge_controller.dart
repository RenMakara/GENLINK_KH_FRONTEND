import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/challenge_models.dart';
import '../../domain/repositories/challenge_repository.dart';

class ChallengeController extends GetxController {
  ChallengeController({ChallengeRepository? repository, this.authController})
    : _repository = repository ?? Get.find<ChallengeRepository>();

  final ChallengeRepository _repository;
  final AuthController? authController;

  final challenges = <ChallengeModel>[].obs;
  final myChallenges = <ChallengeModel>[].obs;
  final selectedChallenge = Rxn<ChallengeModel>();

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isDetailLoading = false.obs;
  final errorMessage = RxnString();
  final detailErrorMessage = RxnString();
  final actionErrorMessage = RxnString();

  final joiningChallengeIds = <String>{}.obs;
  final completingChallengeIds = <String>{}.obs;
  final claimingChallengeIds = <String>{}.obs;

  String? _detailRequestId;

  @override
  void onInit() {
    super.onInit();
    loadChallenges();
  }

  Future<void> loadChallenges() async {
    if (isLoading.value || isRefreshing.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final loaded = await _repository.getActiveChallenges();
      challenges.assignAll(_validChallenges(loaded));
      _syncSelectedFromLists();
    } catch (error) {
      errorMessage.value = _messageForLoadError(error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshChallenges() async {
    if (isLoading.value || isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      final loaded = await _repository.getActiveChallenges();
      challenges.assignAll(_validChallenges(loaded));
      errorMessage.value = null;
      _syncSelectedFromLists();
    } catch (error) {
      errorMessage.value = _messageForLoadError(error);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadDetail(String challengeId) async {
    final normalizedId = challengeId.trim();
    if (normalizedId.isEmpty) {
      detailErrorMessage.value = _messageForLoadError(
        StateError('Challenge id is missing'),
      );
      return;
    }
    if (isDetailLoading.value && _detailRequestId == normalizedId) return;

    _detailRequestId = normalizedId;
    detailErrorMessage.value = null;
    final existing = _findChallenge(normalizedId);
    if (existing != null) selectedChallenge.value = existing;
    isDetailLoading.value = true;

    try {
      // The backend has no separate detail endpoint. Both list endpoints
      // return the complete ChallengeResponse, including the user's status.
      final active = await _repository.getActiveChallenges();
      challenges.assignAll(_validChallenges(active));
      var found = _findById(active, normalizedId);
      if (found == null) {
        final mine = await _repository.getMyChallenges();
        myChallenges.assignAll(_validChallenges(mine));
        found = _findById(mine, normalizedId);
      }
      if (found == null) {
        throw StateError('Challenge not found');
      }
      _upsertSelected(found);
    } catch (error) {
      detailErrorMessage.value = _messageForLoadError(error);
    } finally {
      isDetailLoading.value = false;
    }
  }

  Future<void> joinChallenge(String challengeId) async {
    final normalizedId = challengeId.trim();
    if (normalizedId.isEmpty || joiningChallengeIds.contains(normalizedId)) {
      return;
    }
    final current = _findChallenge(normalizedId);
    if (current != null && current.status != ChallengeStatus.notStarted) {
      return;
    }

    joiningChallengeIds.add(normalizedId);
    actionErrorMessage.value = null;
    try {
      final updated = await _repository.joinChallenge(normalizedId);
      _upsertSelected(updated);
    } catch (error) {
      actionErrorMessage.value = _messageForActionError(error);
    } finally {
      joiningChallengeIds.remove(normalizedId);
    }
  }

  Future<void> completeChallenge(String challengeId) async {
    final normalizedId = challengeId.trim();
    if (normalizedId.isEmpty || completingChallengeIds.contains(normalizedId)) {
      return;
    }
    final current = _findChallenge(normalizedId);
    if (current == null || current.status != ChallengeStatus.inProgress) {
      return;
    }

    completingChallengeIds.add(normalizedId);
    actionErrorMessage.value = null;
    try {
      final updated = await _repository.completeChallenge(normalizedId);
      _upsertSelected(updated);
    } catch (error) {
      actionErrorMessage.value = _messageForActionError(error);
    } finally {
      completingChallengeIds.remove(normalizedId);
    }
  }

  Future<void> claimReward(String challengeId) async {
    final normalizedId = challengeId.trim();
    if (normalizedId.isEmpty || claimingChallengeIds.contains(normalizedId)) {
      return;
    }
    final current = _findChallenge(normalizedId);
    if (current == null || current.status != ChallengeStatus.completed) {
      return;
    }

    claimingChallengeIds.add(normalizedId);
    actionErrorMessage.value = null;
    try {
      final updated = await _repository.claimReward(normalizedId);
      _upsertSelected(updated);
      await authController?.refreshCurrentUser();
    } catch (error) {
      actionErrorMessage.value = _messageForActionError(error);
    } finally {
      claimingChallengeIds.remove(normalizedId);
    }
  }

  bool isJoining(String challengeId) =>
      joiningChallengeIds.contains(challengeId);

  bool isCompleting(String challengeId) =>
      completingChallengeIds.contains(challengeId);

  bool isClaiming(String challengeId) =>
      claimingChallengeIds.contains(challengeId);

  ChallengeModel? _findChallenge(String challengeId) {
    return _findById(challenges, challengeId) ??
        _findById(myChallenges, challengeId) ??
        (selectedChallenge.value?.challengeId == challengeId
            ? selectedChallenge.value
            : null);
  }

  static ChallengeModel? _findById(
    Iterable<ChallengeModel> source,
    String challengeId,
  ) {
    for (final challenge in source) {
      if (challenge.challengeId == challengeId) return challenge;
    }
    return null;
  }

  static List<ChallengeModel> _validChallenges(
    Iterable<ChallengeModel> source,
  ) {
    return source
        .where((challenge) => challenge.challengeId.isNotEmpty)
        .toList(growable: false);
  }

  void _upsertSelected(ChallengeModel updated) {
    selectedChallenge.value = updated;
    _replaceInList(challenges, updated);
    _replaceInList(myChallenges, updated);
  }

  void _replaceInList(RxList<ChallengeModel> target, ChallengeModel updated) {
    final index = target.indexWhere(
      (challenge) => challenge.challengeId == updated.challengeId,
    );
    if (index == -1) return;
    target[index] = updated;
    target.refresh();
  }

  void _syncSelectedFromLists() {
    final selectedId = selectedChallenge.value?.challengeId;
    if (selectedId == null) return;
    final refreshed = _findChallenge(selectedId);
    if (refreshed != null) selectedChallenge.value = refreshed;
  }

  String _messageForLoadError(Object error) {
    if (error is AppError && error.message.trim().isNotEmpty) {
      return error.message;
    }
    final translated = 'challenge.loadFailed'.tr;
    return translated == 'challenge.loadFailed'
        ? 'Unable to load challenges right now.'
        : translated;
  }

  String _messageForActionError(Object error) {
    if (error is AppError && error.message.trim().isNotEmpty) {
      return error.message;
    }
    final translated = 'challenge.actionFailed'.tr;
    return translated == 'challenge.actionFailed'
        ? 'The challenge action could not be completed.'
        : translated;
  }
}
