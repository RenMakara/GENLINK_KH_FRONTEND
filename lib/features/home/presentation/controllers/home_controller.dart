import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../data/home_repository.dart';
import '../../domain/entities/home_entity.dart';

class HomeController extends GetxController {
  HomeController({required this.repository});

  final HomeRepository repository;

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = RxnString();
  final home = Rxn<HomeEntity>();
  final habits = <HabitItemEntity>[].obs;
  final isCheckingInHabit = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final data = await repository.getHome();
      home.value = data;
      if (data.todayProgress.habitsTotal > 0) {
        final fetchedHabits = await repository.getHabits();
        habits.assignAll(fetchedHabits);
      } else {
        habits.clear();
      }
    } on AppError catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'home.unableToLoad'.tr.isNotEmpty &&
              'home.unableToLoad'.tr != 'home.unableToLoad'
          ? 'home.unableToLoad'.tr
          : 'Unable to load Home. Check your connection and try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() async {
    isRefreshing.value = true;
    try {
      final data = await repository.getHome();
      home.value = data;
      errorMessage.value = null;
      if (data.todayProgress.habitsTotal > 0) {
        final fetchedHabits = await repository.getHabits();
        habits.assignAll(fetchedHabits);
      } else {
        habits.clear();
      }
    } on AppError catch (e) {
      if (home.value == null) {
        errorMessage.value = e.message;
      } else {
        Get.rawSnackbar(message: e.message);
      }
    } catch (_) {
      if (home.value == null) {
        errorMessage.value = 'home.unableToLoad'.tr.isNotEmpty &&
                'home.unableToLoad'.tr != 'home.unableToLoad'
            ? 'home.unableToLoad'.tr
            : 'Unable to load Home. Check your connection and try again.';
      }
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> toggleHabitCheckIn({String? habitId, bool? targetState}) async {
    if (isCheckingInHabit.value) return;

    final currentHome = home.value;
    if (currentHome == null) return;

    HabitItemEntity? habit;
    int habitIndex = -1;
    if (habits.isNotEmpty) {
      if (habitId != null) {
        habitIndex = habits.indexWhere((h) => h.habitId == habitId);
        if (habitIndex != -1) habit = habits[habitIndex];
      } else {
        habitIndex = habits.indexWhere((h) => !h.checkedInToday);
        if (habitIndex == -1) habitIndex = 0;
        habit = habits[habitIndex];
      }
    }

    final newCheckedInState = targetState ??
        (habit != null
            ? !habit.checkedInToday
            : !(currentHome.todayProgress.habitsCompletedToday > 0));
    final effectiveHabitId = habit?.habitId ?? habitId;

    final previousHome = currentHome;
    final previousHabit = habit;
    final previousCompleted = currentHome.todayProgress.habitsCompletedToday;
    final habitsTotal = currentHome.todayProgress.habitsTotal;

    final newCompleted = newCheckedInState
        ? (previousCompleted + 1).clamp(0, habitsTotal > 0 ? habitsTotal : 1)
        : (previousCompleted - 1).clamp(0, habitsTotal > 0 ? habitsTotal : 1);

    final updatedProgress = currentHome.todayProgress.copyWith(
      habitsCompletedToday: newCompleted,
    );
    home.value = currentHome.copyWith(todayProgress: updatedProgress);

    if (habit != null && habitIndex != -1 && habitIndex < habits.length) {
      habits[habitIndex] = habit.copyWith(
        checkedInToday: newCheckedInState,
        streakCount: newCheckedInState
            ? habit.streakCount + 1
            : (habit.streakCount > 0 ? habit.streakCount - 1 : 0),
      );
    }

    if (effectiveHabitId == null || effectiveHabitId.isEmpty) {
      try {
        final refreshedHome = await repository.getHome();
        home.value = refreshedHome;
      } catch (_) {}
      return;
    }

    isCheckingInHabit.value = true;
    try {
      final result =
          await repository.checkInHabit(effectiveHabitId, newCheckedInState);
      if (habitIndex != -1 && habitIndex < habits.length) {
        habits[habitIndex] = result;
      }
    } catch (_) {
      home.value = previousHome;
      if (previousHabit != null &&
          habitIndex != -1 &&
          habitIndex < habits.length) {
        habits[habitIndex] = previousHabit;
      }
      final errorMsg = 'home.habitCheckInError'.tr.isNotEmpty &&
              'home.habitCheckInError'.tr != 'home.habitCheckInError'
          ? 'home.habitCheckInError'.tr
          : 'Unable to update habit check-in. Please try again.';
      Get.rawSnackbar(message: errorMsg);
    } finally {
      isCheckingInHabit.value = false;
    }
  }
}
