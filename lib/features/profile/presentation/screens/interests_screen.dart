import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../domain/entities/profile_entity.dart';
import '../controllers/profile_controller.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  static const maxSelections = 10;

  ProfileController get _controller => Get.find<ProfileController>();

  final _search = TextEditingController();
  final Set<String> _selected = {};
  bool _showAllSkills = false;

  @override
  void initState() {
    super.initState();
    _loadInitialSelection();
    _search.addListener(_refresh);
  }

  Future<void> _loadInitialSelection() async {
    await _controller.loadInterestCatalog();
    if (!mounted) return;
    setState(() {
      _selected.addAll(
        _controller.interests.map((interest) => interest.interestId),
      );
    });
  }

  @override
  void dispose() {
    _search.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Iterable<InterestEntity> get _filtered {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _controller.interestCatalog;
    return _controller.interestCatalog.where(
      (interest) =>
          interest.name.toLowerCase().contains(query) ||
          interest.code.toLowerCase().contains(query),
    );
  }

  void _toggle(InterestEntity interest) {
    setState(() {
      if (_selected.remove(interest.interestId)) return;
      if (_selected.length >= maxSelections) {
        Get.showSnackbar(
          GetSnackBar(
            message: 'interests.limit'.trParams({'max': '$maxSelections'}),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      _selected.add(interest.interestId);
    });
  }

  void _addSearchResult() {
    final result = _filtered.firstOrNull;
    if (result == null) return;
    if (!_selected.contains(result.interestId)) _toggle(result);
    _search.clear();
  }

  Future<void> _save() async {
    final saved = await _controller.replaceInterests(_selected.toList());
    if (saved) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 96,
        titleSpacing: 0,
        leading: const Center(child: AppBackButton()),
        leadingWidth: 74,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'interests.title'.tr,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'interests.subtitle'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (_controller.interestCatalog.isEmpty &&
            _controller.isLoading.value) {
          return const AppLoader();
        }
        return Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SelectionSummary(count: _selected.length),
                      const SizedBox(height: AppSpacing.lg),
                      _SearchBar(
                        controller: _search,
                        enabled: _filtered.isNotEmpty,
                        onAdd: _addSearchResult,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionHeader(
                        title: 'interests.technicalSkills'.tr,
                        icon: Icons.bar_chart_rounded,
                        accent: AppColors.brandPrimary,
                        trailing: _CountPill(count: _selected.length),
                      ),
                      const SizedBox(height: AppSpacing.md + 4),
                      _SkillChips(
                        catalog: _controller.interestCatalog,
                        selected: _selected,
                        onToggle: _toggle,
                        showAll: _showAllSkills,
                        onShowMore: () => setState(() => _showAllSkills = true),
                      ),
                      const SizedBox(height: AppSpacing.xl + 4),
                      _SectionHeader(
                        title: 'interests.coreInterests'.tr,
                        icon: Icons.category_outlined,
                        accent: AppColors.productivityAccent,
                      ),
                      const SizedBox(height: AppSpacing.md + 4),
                      _CoreInterestGrid(
                        catalog: _controller.interestCatalog,
                        selected: _selected,
                        onToggle: _toggle,
                      ),
                      const SizedBox(height: AppSpacing.xl + 4),
                      _SectionHeader(
                        title: 'interests.suggested'.tr,
                        icon: Icons.auto_awesome_rounded,
                        accent: AppColors.growthAccent,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_filtered.isEmpty)
                        Text('interests.noResults'.tr)
                      else
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final interest
                                in _filtered
                                    .where(
                                      (i) => !_selected.contains(i.interestId),
                                    )
                                    .take(8))
                              _SuggestionChip(
                                interest: interest,
                                onTap: () => _toggle(interest),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            _SaveFooter(
              count: _selected.length,
              saving: _controller.isSaving.value,
              onSave: _save,
            ),
          ],
        );
      }),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.15 : 0.06),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.34 : 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(
                alpha: isDark ? 0.22 : 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.brandPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'interests.selectionTitle'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'interests.limit'.trParams({
                    'max': '${_InterestsScreenState.maxSelections}',
                  }),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.66),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _CountPill(count: count),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.accent,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm + 4),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ] else
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurface.withValues(alpha: 0.42),
          ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.enabled,
    required this.onAdd,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.025),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(
                alpha: isDark ? 0.17 : 0.09,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_rounded,
              color: AppColors.brandPrimary,
              size: 21,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              key: const ValueKey('expertise-search'),
              controller: controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => enabled ? onAdd() : null,
              decoration: InputDecoration.collapsed(
                hintText: 'interests.searchHint'.tr,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            key: const ValueKey('expertise-add'),
            onPressed: enabled ? onAdd : null,
            tooltip: 'interests.add'.tr,
            style: IconButton.styleFrom(
              backgroundColor: enabled
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
              foregroundColor: enabled
                  ? scheme.onPrimary
                  : scheme.onSurface.withValues(alpha: 0.45),
              minimumSize: const Size(44, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.17 : 0.08,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.34
                : 0.16,
          ),
        ),
      ),
      child: Text(
        'interests.selectedCount'.trParams({'count': '$count'}),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.brandPrimary,
        ),
      ),
    );
  }
}

class _SkillChips extends StatelessWidget {
  const _SkillChips({
    required this.catalog,
    required this.selected,
    required this.onToggle,
    required this.showAll,
    required this.onShowMore,
  });

  final List<InterestEntity> catalog;
  final Set<String> selected;
  final ValueChanged<InterestEntity> onToggle;
  final bool showAll;
  final VoidCallback onShowMore;

  @override
  Widget build(BuildContext context) {
    final selectedItems = catalog
        .where((item) => selected.contains(item.interestId))
        .toList();
    final unselectedItems = catalog
        .where((item) => !selected.contains(item.interestId))
        .toList();

    final visible = <InterestEntity>[...selectedItems, ...unselectedItems];

    final displayList = showAll ? visible : visible.take(12).toList();
    final hasMore = visible.length > 12 && !showAll;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final interest in displayList)
          _CustomChip(
            label: interest.name,
            selected: selected.contains(interest.interestId),
            onTap: () => onToggle(interest),
          ),
        if (hasMore)
          _CustomChip(
            label: 'interests.showMore'.tr,
            selected: false,
            onTap: onShowMore,
            icon: Icons.expand_more_rounded,
          ),
      ],
    );
  }
}

class _CustomChip extends StatelessWidget {
  const _CustomChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bgColor = selected ? AppColors.brandPrimary : scheme.surface;
    final textColor = selected ? Colors.white : scheme.onSurface;
    final borderColor = selected ? Colors.transparent : scheme.outlineVariant;

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon ?? (selected ? Icons.check_rounded : Icons.add_rounded),
                size: 17,
                color: textColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.interest, required this.onTap});

  final InterestEntity interest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _categoryAccent(interest.category);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: accent.withValues(alpha: isDark ? 0.14 : 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(color: accent.withValues(alpha: 0.28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_categoryIcon(interest.category), size: 17, color: accent),
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  interest.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.add_rounded, size: 17, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoreInterestGrid extends StatelessWidget {
  const _CoreInterestGrid({
    required this.catalog,
    required this.selected,
    required this.onToggle,
  });

  final List<InterestEntity> catalog;
  final Set<String> selected;
  final ValueChanged<InterestEntity> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final byCategory = <String, InterestEntity>{};
    for (final interest in catalog) {
      byCategory.putIfAbsent(interest.category ?? 'OTHER', () => interest);
    }
    final cards = byCategory.values.take(4).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 190,
            childAspectRatio: 1.15,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) {
            final interest = cards[index];
            final active = selected.contains(interest.interestId);
            final accent = _categoryAccent(interest.category);
            final cardColor = active
                ? accent
                : accent.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.12 : 0.06,
                  );
            final textColor = active ? Colors.white : scheme.onSurface;

            return Material(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                side: BorderSide(
                  color: active
                      ? Colors.transparent
                      : accent.withValues(alpha: 0.24),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onToggle(interest),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : accent.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _categoryIcon(interest.category),
                              color: active ? Colors.white : accent,
                              size: 20,
                            ),
                          ),
                          Icon(
                            active
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            size: 20,
                            color: active
                                ? Colors.white
                                : accent.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        interest.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _categoryLabel(interest.category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor.withValues(
                            alpha: active ? 0.74 : 0.64,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SaveFooter extends StatelessWidget {
  const _SaveFooter({
    required this.count,
    required this.saving,
    required this.onSave,
  });

  final int count;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.18 : 0.05,
            ),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(
                        alpha: theme.brightness == Brightness.dark ? 0.18 : 0.1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'interests.selectionProgress'.trParams({
                            'count': '$count',
                            'max': '${_InterestsScreenState.maxSelections}',
                          }),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'interests.limit'.trParams({
                            'max': '${_InterestsScreenState.maxSelections}',
                          }),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.58),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '$count/${_InterestsScreenState.maxSelections}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: count / _InterestsScreenState.maxSelections,
                  minHeight: 7,
                  backgroundColor: scheme.outlineVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.brandPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: const ValueKey('expertise-save'),
                label: 'interests.saveContinue'.tr,
                icon: Icons.check_rounded,
                loading: saving,
                radius: AppRadius.lg,
                onPressed: onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _categoryLabel(String? category) => (category ?? 'Interest')
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0]}${word.substring(1).toLowerCase()}',
    )
    .join(' ');

IconData _categoryIcon(String? category) => switch (category) {
  'CAREER' => Icons.rocket_launch_outlined,
  'FINANCE' => Icons.payments_outlined,
  'EDUCATION' => Icons.school_outlined,
  'LIFESTYLE' => Icons.eco_outlined,
  'ENTERTAINMENT' => Icons.auto_awesome_outlined,
  'COMMUNITY' => Icons.groups_outlined,
  _ => Icons.interests_outlined,
};

Color _categoryAccent(String? category) => switch (category) {
  'CAREER' => AppColors.brandPrimary,
  'FINANCE' => AppColors.financeAccent,
  'EDUCATION' => AppColors.productivityAccent,
  'LIFESTYLE' => AppColors.success,
  'ENTERTAINMENT' => AppColors.warning,
  'COMMUNITY' => AppColors.communityAccent,
  _ => AppColors.profileAccent,
};
