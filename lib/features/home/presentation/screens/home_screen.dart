import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../domain/entities/home_entity.dart';
import '../controllers/home_controller.dart';

/// Home Super Dashboard — one `GET /mobile/home` call renders the page.
///
/// Every card in the design that has backend data is here; the ones that
/// do not (streaks, unread counts, focus minutes) are deliberately absent
/// rather than filled with fake numbers. Null cards render empty states.
class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key, this.onNavigateTab});

  /// Lets quick actions switch the bottom-nav tab; Home cannot reach the
  /// shell's state directly.
  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final home = controller.home.value;

          if (controller.isLoading.value && home == null) {
            return const AppLoader();
          }
          if (home == null) {
            return AppEmptyState(
              message: controller.errorMessage.value ?? 'common.error'.tr,
              icon: Icons.cloud_off_outlined,
              action: AppButton.secondary(
                label: 'common.retry'.tr,
                expanded: false,
                onPressed: controller.reload,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                _Header(user: home.user),
                const SizedBox(height: AppSpacing.md),
                _LevelBar(user: home.user),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'home.headline'.tr,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                _TodayHub(home: home),
                const SizedBox(height: AppSpacing.lg),
                _QuickActions(onNavigateTab: onNavigateTab),
                const SizedBox(height: AppSpacing.lg),
                _StatGrid(home: home, onNavigateTab: onNavigateTab),
                if (home.dailyMotivation != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _MotivationTile(motivation: home.dailyMotivation!),
                ],
                if (home.feedPreview.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _RecentActivity(
                    items: home.feedPreview,
                    onSeeAll: () => onNavigateTab?.call(1),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final HomeUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(DateTime.now()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  style: theme.textTheme.titleLarge,
                  children: [
                    TextSpan(text: '${_greetingKey().tr}, '),
                    TextSpan(
                      text: user.firstName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none),
          tooltip: 'settings.notifications'.tr,
          onPressed: () {},
        ),
        AppAvatar(imageUrl: user.avatarUrl, name: user.fullName, size: 36),
      ],
    );
  }

  /// Greeting keys are time-of-day based, from the device clock.
  static String _greetingKey() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'home.goodMorning';
    if (hour < 18) return 'home.goodAfternoon';
    return 'home.goodEvening';
  }

  /// "Mon · 23 Jun 2026" using translated abbreviation tables, so no
  /// dependency on flutter_localizations for a date the design shows.
  static String _formatDate(DateTime now) {
    final weekdays = 'date.weekdays'.tr.split(',');
    final months = 'date.months'.tr.split(',');
    final weekday = weekdays[(now.weekday - 1) % 7];
    final month = months[(now.month - 1) % 12];
    return '$weekday · ${now.day} $month ${now.year}';
  }
}

// ── Level bar ───────────────────────────────────────────────────────────

class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.user});

  final HomeUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.5);

    return Row(
      children: [
        Container(
          height: 30,
          width: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
          ),
          child: Text(
            '${user.level}',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: scheme.onPrimary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Text(
          'home.levelLabel'.trParams({'level': '${user.level}'}),
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: user.levelProgress,
              minHeight: 5,
              backgroundColor: scheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.accentPremium,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          '${user.totalXp} / ${user.xpForNextLevel} XP',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}

// ── Today Hub ───────────────────────────────────────────────────────────

class _TodayHub extends StatelessWidget {
  const _TodayHub({required this.home});

  final HomeEntity home;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.5);
    final progress = home.todayProgress;

    final rows = _rows();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    height: 7,
                    width: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.growthAccent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'home.todayHub'.tr.toUpperCase(),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: muted, letterSpacing: 0.8),
                  ),
                ],
              ),
              Text(
                'home.doneOf'.trParams({
                  'done': '${progress.doneCount}',
                  'total': '${progress.totalCount}',
                }),
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'home.todayEmpty'.tr,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            )
          else
            for (final row in rows) ...[
              row,
              if (row != rows.last) const SizedBox(height: AppSpacing.sm + 2),
            ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'home.dailyProgress'.tr,
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
              const Spacer(),
              Text(
                '${progress.percent}%',
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress.progress,
              minHeight: 4,
              backgroundColor: scheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Rows come from whatever today actually contains — habits, tasks, the
  /// daily challenge, and the next RSVP'd event.
  List<Widget> _rows() {
    final progress = home.todayProgress;
    final rows = <Widget>[];

    if (progress.habitsTotal > 0) {
      rows.add(_HubRow(
        done: progress.habitsCompletedToday >= progress.habitsTotal,
        title: 'home.rowHabits'.tr,
        detail: 'home.rowHabitsDetail'.trParams({
          'done': '${progress.habitsCompletedToday}',
          'total': '${progress.habitsTotal}',
        }),
        accent: AppColors.productivityAccent,
      ));
    }
    if (progress.tasksTotal > 0) {
      rows.add(_HubRow(
        done: progress.tasksCompleted >= progress.tasksTotal,
        title: 'home.rowTasks'.tr,
        detail: 'home.rowTasksDetail'.trParams({
          'done': '${progress.tasksCompleted}',
          'total': '${progress.tasksTotal}',
        }),
        accent: AppColors.communityAccent,
      ));
    }
    final challenge = home.dailyChallenge;
    if (challenge != null) {
      rows.add(_HubRow(
        done: false,
        title: challenge.title,
        detail: challenge.xpReward == null
            ? 'home.rowChallenge'.tr
            : 'home.rowChallengeXp'
                .trParams({'xp': '${challenge.xpReward}'}),
        accent: AppColors.growthAccent,
      ));
    }
    final event = home.upcomingEvent;
    if (event != null) {
      rows.add(_HubRow(
        done: false,
        title: event.title,
        detail: [
          'home.rowEvent'.tr,
          if (event.locationName != null) event.locationName!,
        ].join(' · '),
        accent: AppColors.financeAccent,
      ));
    }
    return rows;
  }
}

class _HubRow extends StatelessWidget {
  const _HubRow({
    required this.done,
    required this.title,
    required this.detail,
    required this.accent,
  });

  final bool done;
  final String title;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          height: 20,
          width: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? scheme.primary : Colors.transparent,
            border: Border.all(
              color: done ? Colors.transparent : scheme.outlineVariant,
              width: 1.4,
            ),
          ),
          child: done
              ? Icon(Icons.check, size: 13, color: scheme.onPrimary)
              : null,
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 7,
          width: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
        ),
      ],
    );
  }
}

// ── Quick actions ───────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({this.onNavigateTab});

  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    // Tab indices match MainScreen: 0 home, 1 community, 2 finance, 3 profile.
    final actions = [
      (Icons.add, 'home.actionCreate'.tr, 1),
      (Icons.attach_money, 'home.actionExpense'.tr, 2),
      (Icons.star_outline, 'home.actionGoal'.tr, 2),
      (Icons.calendar_today_outlined, 'home.actionEvent'.tr, 1),
    ];

    return Row(
      children: [
        for (final (icon, label, tab) in actions) ...[
          Expanded(
            child: _QuickAction(
              icon: icon,
              label: label,
              onTap: () => onNavigateTab?.call(tab),
            ),
          ),
          if (actions.last.$2 != label) const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Material(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Icon(icon, size: 20),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ── Stat grid ───────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.home, this.onNavigateTab});

  final HomeEntity home;
  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final finance = home.financeSnapshot;
    final progress = home.todayProgress;
    final user = home.user;

    final cards = <Widget>[
      _StatCard(
        icon: Icons.groups_outlined,
        iconColor: AppColors.communityAccent,
        value: '${home.recommendedCommunities.length}',
        title: 'home.statCommunity'.tr,
        caption: 'home.statCommunityCaption'.tr,
        onTap: () => onNavigateTab?.call(1),
      ),
      _StatCard(
        icon: Icons.attach_money,
        iconColor: AppColors.financeAccent,
        value: finance?.remainingAmount == null
            ? '—'
            : '\$${finance!.remainingAmount!.toStringAsFixed(0)}',
        title: 'home.statFinance'.tr,
        caption: finance == null
            ? 'home.statFinanceEmpty'.tr
            : 'home.statFinanceCaption'.tr,
        onTap: () => onNavigateTab?.call(2),
      ),
      _StatCard(
        icon: Icons.bolt_outlined,
        iconColor: AppColors.productivityAccent,
        value: '${progress.doneCount}/${progress.totalCount}',
        title: 'home.statProductivity'.tr,
        caption: 'home.statProductivityCaption'.tr,
        onTap: null,
      ),
      _StatCard(
        icon: Icons.star_outline,
        iconColor: AppColors.growthAccent,
        value: 'home.statGrowthValue'
            .trParams({'level': '${user.level}'}),
        title: 'home.statGrowth'.tr,
        caption: 'home.statGrowthCaption'
            .trParams({'percent': '${user.percentToNext}'}),
        onTap: () => onNavigateTab?.call(3),
      ),
    ];

    // IntrinsicHeight, not CrossAxisAlignment.stretch: inside a ListView the
    // cross axis is unbounded, so stretch resolves to an infinite height.
    Widget pair(Widget left, Widget right) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: right),
            ],
          ),
        );

    return Column(
      children: [
        pair(cards[0], cards[1]),
        const SizedBox(height: AppSpacing.md),
        pair(cards[2], cards[3]),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.title,
    required this.caption,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String title;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Motivation ──────────────────────────────────────────────────────────

class _MotivationTile extends StatelessWidget {
  const _MotivationTile({required this.motivation});

  final MotivationCard motivation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.accentPremium.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote,
              size: 18, color: AppColors.accentPremium),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (motivation.title != null)
                  Text(motivation.title!, style: theme.textTheme.titleSmall),
                if (motivation.content != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    motivation.content!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent activity ─────────────────────────────────────────────────────

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.items, this.onSeeAll});

  final List<FeedPreview> items;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('home.recentActivity'.tr,
                style: theme.textTheme.titleMedium),
            AppButton.text(
              label: 'home.seeAll'.tr,
              muted: true,
              onPressed: onSeeAll,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              for (final item in items) ...[
                _ActivityRow(item: item),
                if (item != items.last)
                  const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final FeedPreview item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: item.authorAvatarUrl,
            name: item.authorName,
            size: 30,
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: item.authorName ?? 'home.someone'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if ((item.contentText ?? '').isNotEmpty)
                    // User content — rendered as written.
                    TextSpan(text: '  ${item.contentText}'),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _timeAgo(item.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact relative time: "3m", "2h", "5d". Empty when unparseable.
  static String _timeAgo(String? iso) {
    if (iso == null) return '';
    final created = DateTime.tryParse(iso);
    if (created == null) return '';
    final diff = DateTime.now().difference(created.toLocal());
    if (diff.inMinutes < 1) return 'home.justNow'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
