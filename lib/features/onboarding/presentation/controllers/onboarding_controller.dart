import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../design_system/colors/app_colors.dart';

class OnboardingRow {
  const OnboardingRow({
    required this.icon,
    required this.titleKey,
    required this.detailKey,
    required this.accent,
    this.progress,
  });

  final IconData icon;
  final String titleKey;
  final String detailKey;
  final Color accent;
  final double? progress;
}

class OnboardingSlide {
  const OnboardingSlide({
    required this.titleKey,
    required this.bodyKey,
    required this.rows,
  });

  final String titleKey;
  final String bodyKey;
  final List<OnboardingRow> rows;
}

class OnboardingController extends GetxController {
  OnboardingController({required LocalStorage localStorage})
    : _storage = localStorage;

  final LocalStorage _storage;

  final pageController = PageController();
  final currentPage = 0.obs;

  static const slides = <OnboardingSlide>[
    OnboardingSlide(
      titleKey: 'onboarding.networkTitle',
      bodyKey: 'onboarding.networkBody',
      rows: [
        OnboardingRow(
          icon: Icons.groups_outlined,
          titleKey: 'onboarding.rowCommunity',
          detailKey: 'onboarding.rowCommunityDetail',
          accent: AppColors.communityAccent,
        ),
        OnboardingRow(
          icon: Icons.calendar_today_outlined,
          titleKey: 'onboarding.rowEvents',
          detailKey: 'onboarding.rowEventsDetail',
          accent: AppColors.growthAccent,
        ),
        OnboardingRow(
          icon: Icons.person_outline,
          titleKey: 'onboarding.rowMentors',
          detailKey: 'onboarding.rowMentorsDetail',
          accent: AppColors.accentPremium,
        ),
      ],
    ),
    OnboardingSlide(
      titleKey: 'onboarding.growTitle',
      bodyKey: 'onboarding.growBody',
      rows: [
        OnboardingRow(
          icon: Icons.attach_money,
          titleKey: 'onboarding.rowFinance',
          detailKey: 'onboarding.rowFinanceDetail',
          accent: AppColors.financeAccent,
          progress: 0.62,
        ),
        OnboardingRow(
          icon: Icons.bolt_outlined,
          titleKey: 'onboarding.rowFocus',
          detailKey: 'onboarding.rowFocusDetail',
          accent: AppColors.productivityAccent,
          progress: 0.78,
        ),
        OnboardingRow(
          icon: Icons.star_outline,
          titleKey: 'onboarding.rowXp',
          detailKey: 'onboarding.rowXpDetail',
          accent: AppColors.growthAccent,
          progress: 0.45,
        ),
      ],
    ),
  ];

  bool get isLastPage => currentPage.value == slides.length - 1;

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) => currentPage.value = index;

  void next() {
    if (isLastPage) {
      finish();
      return;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> finish() async {
    await _storage.markOnboardingSeen();
    Get.offAllNamed<void>(AppRoutes.authChoice);
  }
}
