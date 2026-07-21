import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../domain/entities/profile_entity.dart';
import '../controllers/profile_controller.dart';

/// Portfolio management: list, add, edit, delete — the full CRUD the
/// backend exposes at `/profile/portfolio`.
class PortfolioScreen extends GetView<ProfileController> {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: AppBackButton(),
        ),
        leadingWidth: 58 + AppSpacing.md * 2,
        title: Text('profile.portfolio'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'portfolio.add'.tr,
            onPressed: () => _edit(context, null),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.portfolio.isEmpty) {
          return const AppLoader();
        }
        final items = controller.portfolio;
        if (items.isEmpty) {
          return AppEmptyState(
            message: 'profile.emptyPortfolio'.tr,
            icon: Icons.work_outline,
            action: AppButton.secondary(
              label: 'portfolio.add'.tr,
              expanded: false,
              onPressed: () => _edit(context, null),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) => _PortfolioCard(
            item: items[index],
            onEdit: () => _edit(context, items[index]),
            onDelete: () => _delete(items[index]),
          ),
        );
      }),
    );
  }

  Future<void> _delete(PortfolioItemEntity item) async {
    final confirmed = await AppDialog.confirm(
      title: 'portfolio.deleteConfirm'.trParams({'title': item.title}),
      confirmLabel: 'common.delete'.tr,
      destructive: true,
    );
    if (confirmed) await controller.deletePortfolioItem(item.portfolioId);
  }

  /// One dialog serves add and edit; [item] null means add.
  Future<void> _edit(BuildContext context, PortfolioItemEntity? item) async {
    final title = TextEditingController(text: item?.title ?? '');
    final description = TextEditingController(text: item?.description ?? '');
    final link = TextEditingController(text: item?.link ?? '');
    final imageUrl = TextEditingController(text: item?.imageUrl ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item == null ? 'portfolio.add'.tr : 'portfolio.edit'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    InputDecoration(hintText: 'profile.portfolioTitle'.tr),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: description,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                    hintText: 'profile.portfolioDescription'.tr),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: link,
                keyboardType: TextInputType.url,
                decoration:
                    InputDecoration(hintText: 'profile.portfolioLink'.tr),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: imageUrl,
                keyboardType: TextInputType.url,
                decoration:
                    InputDecoration(hintText: 'portfolio.imageUrl'.tr),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('common.cancel'.tr),
          ),
          FilledButton(
            // Title is the only backend-required field.
            onPressed: () =>
                Navigator.of(dialogContext).pop(title.text.trim().isNotEmpty),
            child: Text('common.save'.tr),
          ),
        ],
      ),
    );

    if (saved ?? false) {
      if (item == null) {
        await controller.addPortfolioItem(
          title: title.text.trim(),
          description: description.text.trim(),
          link: link.text.trim(),
          imageUrl: imageUrl.text.trim(),
        );
      } else {
        await controller.updatePortfolioItem(
          portfolioId: item.portfolioId,
          title: title.text.trim(),
          description: description.text.trim(),
          link: link.text.trim(),
          imageUrl: imageUrl.text.trim(),
        );
      }
    }

    title.dispose();
    description.dispose();
    link.dispose();
    imageUrl.dispose();
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final PortfolioItemEntity item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            AspectRatio(
              aspectRatio: 2.2,
              child: Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: Icon(Icons.broken_image_outlined, color: muted),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: theme.textTheme.titleMedium),
                      if ((item.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: muted),
                        ),
                      ],
                      if ((item.link ?? '').isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(Icons.link, size: 14, color: muted),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                item.link!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: muted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: muted),
                  onSelected: (action) =>
                      action == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('common.edit'.tr),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('common.delete'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
