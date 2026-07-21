import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../controllers/profile_controller.dart';

/// Interests editor — the backed half of the design's "Skills & Interests"
/// screen. Skills have no backend and are not rendered.
///
/// Selection is staged locally and saved in one `PUT` (the backend replaces
/// the whole set), so backing out without saving changes nothing.
class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  ProfileController get _controller => Get.find<ProfileController>();

  late final Set<String> _selected = {
    for (final interest in _controller.interests) interest.interestId,
  };

  @override
  void initState() {
    super.initState();
    _controller.loadInterestCatalog();
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
        title: Text('profile.interests'.tr),
      ),
      body: Obx(() {
        if (_controller.interestCatalog.isEmpty) {
          return _controller.isLoading.value
              ? const AppLoader()
              : AppEmptyState(message: 'profile.emptyInterests'.tr);
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'interests.hint'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm + 2,
                      runSpacing: AppSpacing.sm + 2,
                      children: [
                        for (final interest in _controller.interestCatalog)
                          FilterChip(
                            label: Text(interest.name),
                            selected:
                                _selected.contains(interest.interestId),
                            onSelected: (_) => setState(() {
                              if (!_selected.remove(interest.interestId)) {
                                _selected.add(interest.interestId);
                              }
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Obx(
                  () => AppButton(
                    label: 'interests.saveCount'
                        .trParams({'count': '${_selected.length}'}),
                    loading: _controller.isSaving.value,
                    onPressed: _save,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
