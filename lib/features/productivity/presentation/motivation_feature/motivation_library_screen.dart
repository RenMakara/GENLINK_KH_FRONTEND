import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../controllers/productivity_controller.dart';
import '../productivity_scope.dart';
import '../../domain/entities/productivity_entities.dart';

class MotivationLibraryScreen extends StatefulWidget {
  const MotivationLibraryScreen({super.key});

  @override
  State<MotivationLibraryScreen> createState() =>
      _MotivationLibraryScreenState();
}

class _MotivationLibraryScreenState extends State<MotivationLibraryScreen> {
  ProductivityController? _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = ensureProductivityController();
    _load();
  }

  Future<void> _load() async {
    final controller = _controller;
    if (controller == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      await Future.wait([
        controller.loadMotivation(),
        controller.loadSavedMotivation(),
      ]);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleSaved(ProductivityMotivation item) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      if (item.saved) {
        await controller.unsaveMotivation(item.motivationId);
      } else {
        await controller.saveMotivation(item.motivationId);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('motivation.libraryTitle'.tr),
          bottom: TabBar(
            tabs: [
              Tab(text: 'motivation.browse'.tr),
              Tab(text: 'motivation.saved'.tr),
            ],
          ),
        ),
        body: controller == null
            ? Center(child: Text('habits.signInToManage'.tr))
            : _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _motivationList(controller, savedOnly: false),
                  _motivationList(controller, savedOnly: true),
                ],
              ),
      ),
    );
  }

  Widget _motivationList(
    ProductivityController controller, {
    required bool savedOnly,
  }) {
    final colors = context.semanticColors;
    return Obx(() {
      final items = savedOnly
          ? controller.savedMotivations.toList(growable: false)
          : controller.motivations.toList(growable: false);
      if (items.isEmpty) {
        return Center(
          child: Text(
            savedOnly
                ? 'motivation.emptySaved'.tr
                : 'motivation.emptyLibrary'.tr,
            style: TextStyle(color: colors.textMuted),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.productivityAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.content,
                          style: TextStyle(color: colors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: item.saved
                        ? 'motivation.unsave'.tr
                        : 'motivation.save'.tr,
                    onPressed: () => _toggleSaved(item),
                    icon: Icon(
                      item.saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: item.saved
                          ? AppColors.productivityAccent
                          : colors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}
