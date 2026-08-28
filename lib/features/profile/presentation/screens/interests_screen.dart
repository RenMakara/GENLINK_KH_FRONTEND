import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../domain/entities/profile_entity.dart';
import '../controllers/profile_controller.dart';

/// Backend-backed expertise and interests editor.
///
/// The visual grouping follows the supplied design, while every selectable
/// value still comes from the server catalog. Arbitrary text is never sent as
/// a fabricated interest id.
class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  static const maxSelections = 10;

  ProfileController get _controller => Get.find<ProfileController>();

  final Set<String> _selected = {};
  bool _showAllSkills = false;

  @override
  void initState() {
    super.initState();
    _loadInitialSelection();
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

  Future<void> _save() async {
    final saved = await _controller.replaceInterests(_selected.toList());
    if (saved) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
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
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppBackButton(),
                      ),
                      Text(
                        'interests.title'.tr,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'interests.subtitle'.tr,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'interests.technicalSkills'.tr,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _CountPill(count: _selected.length),
                        ],
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
                      Text(
                        'interests.coreInterests'.tr,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md + 4),
                      _CoreInterestGrid(
                        catalog: _controller.interestCatalog,
                        selected: _selected,
                        onToggle: _toggle,
                      ),
                      const SizedBox(height: AppSpacing.xl + 4),
                      Text(
                        'interests.suggested'.tr,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final interest in _controller.interestCatalog
                                .where((i) => !_selected.contains(i.interestId))
                                .take(8)) ...[
                              ActionChip(
                                avatar: Icon(
                                  _categoryIcon(interest.category),
                                  size: 17,
                                ),
                                label: Text(interest.name),
                                onPressed: () => _toggle(interest),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                          ],
                        ),
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

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: scheme.outlineVariant,
        ),
      ),
      child: Text(
        'interests.selectedCount'.trParams({'count': '$count'}),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: scheme.onSurface,
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
    final theme = Theme.of(context);
    final selectedItems =
        catalog.where((item) => selected.contains(item.interestId)).toList();
    final unselectedItems =
        catalog.where((item) => !selected.contains(item.interestId)).toList();

    final visible = <InterestEntity>[
      ...selectedItems,
      ...unselectedItems,
    ];

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
            label: 'More...',
            selected: false,
            onTap: onShowMore,
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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bgColor = selected ? scheme.primary : scheme.surface;
    final textColor = selected ? scheme.onPrimary : scheme.onSurface;
    final borderColor = selected ? Colors.transparent : scheme.outlineVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.close : Icons.add,
              size: 16,
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemBuilder: (context, index) {
        final interest = cards[index];
        final active = selected.contains(interest.interestId);

        final cardColor = active ? scheme.primary : scheme.surface;
        final textColor = active ? scheme.onPrimary : scheme.onSurface;

        return Material(
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(
              color: active ? Colors.transparent : scheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onToggle(interest),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        _categoryIcon(interest.category),
                        color: textColor,
                      ),
                      if (active)
                        Icon(
                          Icons.verified,
                          size: 18,
                          color: scheme.onPrimary,
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
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'interests.selectionProgress'.trParams({
                        'count': '$count',
                        'max': '${_InterestsScreenState.maxSelections}',
                      }),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: count / _InterestsScreenState.maxSelections,
                        minHeight: 8,
                        backgroundColor: scheme.outlineVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                key: const ValueKey('expertise-save'),
                label: 'interests.saveContinue'.tr,
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
