import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../domain/entities/profile_entity.dart';
import '../controllers/profile_controller.dart';

class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  String? _filter;

  ProfileController get _controller => Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    unawaited(_controller.reloadSavedItems());
  }

  Future<void> _openItem(SavedItemEntity item) async {
    if (item.itemType != 'SHORT_CONTENT' || item.itemId.trim().isEmpty) {
      return;
    }
    await Get.toNamed(AppRoutes.shortContentDetail, arguments: item.itemId);
    if (mounted) unawaited(_controller.reloadSavedItems());
  }

  static const _typeIcons = <String, IconData>{
    'POST': Icons.article_outlined,
    'DISCUSSION': Icons.forum_outlined,
    'EVENT': Icons.calendar_today_outlined,
    'OPPORTUNITY': Icons.work_outline,
    'MOTIVATION': Icons.format_quote,
    'LESSON': Icons.school_outlined,
    'SHORT_CONTENT': Icons.play_circle_outline,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const Center(child: AppBackButton()),
        leadingWidth: 74,
        title: Text(
          'profile.saved'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.savedItems.isEmpty) {
          return const AppLoader();
        }

        final all = _controller.savedItems;
        if (all.isEmpty) {
          return AppEmptyState(
            message: 'profile.emptySaved'.tr,
            icon: Icons.bookmark_border,
          );
        }

        final types = all.map((item) => item.itemType).toSet().toList()..sort();
        final filtered = _filter == null
            ? all
            : all.where((item) => item.itemType == _filter).toList();

        return Column(
          children: [
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                children: [
                  _FilterChip(
                    label: 'saved.all'.tr,
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final type in types)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: _FilterChip(
                        label: 'savedType.$type'.tr,
                        selected: _filter == type,
                        onTap: () => setState(() => _filter = type),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _controller.reload,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _SavedRow(
                      item: item,
                      theme: theme,
                      onTap: item.available && item.itemType == 'SHORT_CONTENT'
                          ? () => unawaited(_openItem(item))
                          : null,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? Colors.transparent : scheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.item, required this.theme, this.onTap});

  final SavedItemEntity item;
  final ThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                ),
                child: Icon(
                  _SavedItemsScreenState._typeIcons[item.itemType] ??
                      Icons.bookmark_border,
                  size: 18,
                  color: item.available ? scheme.onSurface : muted,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.available
                          ? (item.title ?? '')
                          : 'profile.savedUnavailable'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: item.available ? null : muted,
                      ),
                    ),
                    Text(
                      item.available && (item.subtitle ?? '').isNotEmpty
                          ? item.subtitle!
                          : 'savedType.${item.itemType}'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
