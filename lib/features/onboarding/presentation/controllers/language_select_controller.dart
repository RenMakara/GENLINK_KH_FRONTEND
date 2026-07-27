import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/localization/localization_service.dart';

/// Step 1 of the first-run flow: pick the app language.
///
/// Pre-selected from the device language (Khmer device → Khmer, otherwise
/// English). The choice is applied live as the user taps, so the rest of
/// the flow is already in their language before they press Continue.
/// Tapping is an explicit choice and sticks; merely continuing without
/// tapping leaves the app following the device language.
class LanguageSelectController extends GetxController {
  LanguageSelectController({required LocalizationService localization})
      : _localization = localization;

  final LocalizationService _localization;

  /// Position in the first-run flow, shown as "STEP 1 OF 6".
  static const step = 1;
  static const totalSteps = 6;

  late final selected = _localization.language.value.obs;

  Future<void> select(String language) async {
    if (selected.value == language) return;
    selected.value = language;
    // Applied immediately so the screen itself switches language.
    await _localization.setLanguage(language);
  }

  void continueToOnboarding() => Get.toNamed<void>(AppRoutes.onboarding);
}
