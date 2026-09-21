import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../profile/data/datasources/profile_remote_datasource.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/domain/entities/profile_entity.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../domain/models/leaderboard_models.dart';
import '../widgets/leaderboard_profile_widgets.dart';

class TopRankDetailScreen extends StatefulWidget {
  const TopRankDetailScreen({super.key});

  @override
  State<TopRankDetailScreen> createState() => _TopRankDetailScreenState();
}

class _TopRankDetailScreenState extends State<TopRankDetailScreen> {
  List<BadgeEntity> _badges = const [];
  bool _isLoadingBadges = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    // If ProfileController already loaded badges, reuse them instantly
    if (Get.isRegistered<ProfileController>()) {
      final profileCtrl = Get.find<ProfileController>();
      if (profileCtrl.badges.isNotEmpty) {
        if (mounted) {
          setState(() {
            _badges = profileCtrl.badges.toList();
            _isLoadingBadges = false;
          });
        }
        return;
      }
    }

    try {
      final repo = _resolveRepository();
      final loaded = await repo.getBadges();
      if (mounted) {
        setState(() {
          _badges = loaded;
          _isLoadingBadges = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingBadges = false;
        });
      }
    }
  }

  ProfileRepository _resolveRepository() {
    if (Get.isRegistered<ProfileRepository>()) {
      return Get.find<ProfileRepository>();
    }
    if (Get.isRegistered<ApiClient>()) {
      final repo = ProfileRepositoryImpl(
        ProfileRemoteDatasource(Get.find<ApiClient>()),
      );
      Get.put<ProfileRepository>(repo, permanent: true);
      return repo;
    }
    throw StateError('ApiClient is not registered');
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final entry = Get.arguments is LeaderboardEntry
        ? Get.arguments as LeaderboardEntry
        : null;

    return Scaffold(
      backgroundColor: semantic.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 72,
        leading: const Center(
          child: AppBackButton(),
        ),
        titleSpacing: 0,
        title: Text(
          'leaderboard.profile'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: semantic.primaryText,
          ),
        ),
      ),
      body: entry == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'leaderboard.profileUnavailable'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: semantic.secondaryText),
                ),
              ),
            )
          : SafeArea(
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                children: [
                  // 1. Profile Hero Card
                  LeaderboardProfileHero(entry: entry),
                  const SizedBox(height: AppSpacing.md),

                  // 2. Profile Statistics (Points, Global Rank, Level)
                  LeaderboardProfileStatsRow(entry: entry),
                  const SizedBox(height: AppSpacing.md),

                  // 3. Level & XP Progress Card
                  LeaderboardXpProgressCard(entry: entry),
                  const SizedBox(height: AppSpacing.lg),

                  // 4. Achievements Section
                  LeaderboardAchievementsSection(
                    badges: _badges,
                    isLoading: _isLoadingBadges,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 5. View Ranking Action Card
                  LeaderboardActionCard(entry: entry),
                  const SizedBox(height: AppSpacing.md),

                  // 6. Motivational Bottom Card
                  const LeaderboardMotivationalCard(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }
}
