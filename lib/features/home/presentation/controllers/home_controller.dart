import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../data/home_repository.dart';
import '../../domain/entities/home_entity.dart';

/// Loads the Home Super Dashboard.
///
/// One aggregate call; cards that come back null render their own empty
/// state, so a partial failure never blanks the whole screen — only a
/// failure of the call itself shows the retry state.
class HomeController extends GetxController {
  HomeController({required HomeRepository repository})
      : _repository = repository;

  final HomeRepository _repository;

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final home = Rxn<HomeEntity>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      home.value = await _repository.getHome();
    } on AppError catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'common.error'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  /// Pull-to-refresh entry point (`refresh()` is taken by GetxController).
  Future<void> reload() => load();
}
