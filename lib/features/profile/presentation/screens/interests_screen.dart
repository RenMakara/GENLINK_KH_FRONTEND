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

  final _search = TextEditingController();
  final Set<String> _selected = {};

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
    final catalog = _controller.interestCatalog;
    if (query.isEmpty) return catalog;
    return catalog.where(
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
        titleSpacing: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: AppBackButton(),
        ),
        leadingWidth: 58 + AppSpacing.md * 2,
      ),
      body: Obx(() {
        if (_controller.interestCatalog.isEmpty &&
            _controller.isLoading.value) {
          return const AppLoader();
        }
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'interests.title'.tr,
                      style: theme.textTheme.displayMedium,
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
                    const SizedBox(height: AppSpacing.lg),
                    _SearchBar(
                      controller: _search,
                      enabled: _filtered.isNotEmpty,
                      onAdd: _addSearchResult,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'interests.technicalSkills'.tr,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        _CountPill(count: _selected.length),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SkillChips(
                      catalog: _controller.interestCatalog,
                      selected: _selected,
                      onToggle: _toggle,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'interests.coreInterests'.tr,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CoreInterestGrid(
                      catalog: _controller.interestCatalog,
                      selected: _selected,
                      onToggle: _toggle,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'interests.suggested'.tr,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_filtered.isEmpty)
                      Text('interests.noResults'.tr)
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final interest in _filtered.take(6)) ...[
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.xs,
      AppSpacing.xs,
      AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Row(
      children: [
        const Icon(Icons.search),
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
        AppButton(
          key: const ValueKey('expertise-add'),
          label: 'interests.add'.tr,
          expanded: false,
          height: 46,
          onPressed: enabled ? onAdd : null,
        ),
      ],
    ),
  );
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      'interests.selectedCount'.trParams({'count': '$count'}),
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}

class _SkillChips extends StatelessWidget {
  const _SkillChips({
    required this.catalog,
    required this.selected,
    required this.onToggle,
  });

  final List<InterestEntity> catalog;
  final Set<String> selected;
  final ValueChanged<InterestEntity> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = <InterestEntity>[
      ...catalog.where((item) => selected.contains(item.interestId)),
      ...catalog.where((item) => !selected.contains(item.interestId)),
    ].take(8);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final interest in visible)
          FilterChip(
            label: Text(
              interest.name,
              style: TextStyle(
                color: selected.contains(interest.interestId)
                    ? scheme.onPrimary
                    : scheme.onSurface,
              ),
            ),
            selected: selected.contains(interest.interestId),
            showCheckmark: false,
            selectedColor: scheme.primary,
            backgroundColor: scheme.surface,
            side: BorderSide(color: scheme.outlineVariant),
            avatar: selected.contains(interest.interestId)
                ? Icon(Icons.close, size: 16, color: scheme.onPrimary)
                : Icon(Icons.add, size: 16, color: scheme.onSurface),
            onSelected: (_) => onToggle(interest),
          ),
      ],
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
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemBuilder: (context, index) {
        final interest = cards[index];
        final active = selected.contains(interest.interestId);
        return Material(
          color: active
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(
              color: active
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.outlineVariant,
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
                      Icon(
                        _categoryIcon(interest.category),
                        color: active
                            ? Theme.of(context).colorScheme.onPrimary
                            : null,
                      ),
                      if (active)
                        Icon(
                          Icons.verified,
                          size: 18,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    interest.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: active
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _categoryLabel(interest.category),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: active
                          ? Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.7)
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.58),
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
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
                Expanded(
                  child: Text(
                    'interests.selectionProgress'.trParams({
                      'count': '$count',
                      'max': '${_InterestsScreenState.maxSelections}',
                    }),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: LinearProgressIndicator(
                    value: count / _InterestsScreenState.maxSelections,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const ValueKey('expertise-save'),
              label: 'interests.saveContinue'.tr,
              loading: saving,
              onPressed: onSave,
            ),
          ],
        ),
      ),
    ),
  );
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
