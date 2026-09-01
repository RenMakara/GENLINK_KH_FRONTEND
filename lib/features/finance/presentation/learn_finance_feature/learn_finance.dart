import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_learning_controller.dart';
import 'investing_basics.dart';

/// Finance Learning index backed by the financial-literacy API.
class LearnFinanceScreen extends GetView<FinanceLearningController> {
  const LearnFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final text = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inverse = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        title: Text('finance.learning.title'.tr),
      ),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _DashboardCard(
                dashboard: controller.dashboard.value,
                loading: controller.isDashboardLoading.value,
                error: controller.dashboardErrorMessage.value,
                surface: surface,
                border: border,
                text: text,
                muted: muted,
                primary: primary,
                onRetry: controller.loadDashboard,
              ),
              const SizedBox(height: 18),
              Text(
                'finance.learning.topics'.tr,
                style: TextStyle(
                  color: text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _TopicFilter(
                topics: controller.dashboard.value?.topics ?? const [],
                selectedTopic: controller.selectedTopic.value,
                surface: surface,
                border: border,
                text: text,
                muted: muted,
                primary: primary,
                inverse: inverse,
                onSelected: controller.selectTopic,
              ),
              const SizedBox(height: 18),
              Text(
                'finance.learning.lessons'.tr,
                style: TextStyle(
                  color: text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _LessonList(
                lessons: controller.lessons,
                loading: controller.isLessonsLoading.value,
                error: controller.lessonsErrorMessage.value,
                surface: surface,
                border: border,
                text: text,
                muted: muted,
                primary: primary,
                onRetry: () => controller.loadLessons(),
                onLessonTap: (lesson) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InvestingBasicsScreen(
                      lessonId: lesson.lessonId,
                      initialLesson: lesson,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.dashboard,
    required this.loading,
    required this.error,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.onRetry,
  });

  final FinanceLearningDashboardEntity? dashboard;
  final bool loading;
  final String? error;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading && dashboard == null) {
      return const SizedBox(height: 120, child: AppLoader());
    }
    if (error != null && dashboard == null) {
      return _ErrorCard(message: error!, onRetry: onRetry);
    }
    final value = dashboard;
    if (value == null) return const SizedBox.shrink();
    final total = value.totalLessons < 0 ? 0 : value.totalLessons;
    final completed = value.completedLessons.clamp(0, total);
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'finance.learning.progress'.tr,
                  style: TextStyle(
                    color: text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$completed/$total',
                style: TextStyle(color: text, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'finance.learning.lessonsCompleted'.trParams({
              'completed': '$completed',
              'total': '$total',
            }),
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: border,
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${'finance.learning.xp'.tr}: ${value.literacyXp}',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TopicFilter extends StatelessWidget {
  const _TopicFilter({
    required this.topics,
    required this.selectedTopic,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.inverse,
    required this.onSelected,
  });

  final List<FinanceLearningTopicProgressEntity> topics;
  final String? selectedTopic;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final Color inverse;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return Text(
        'finance.learning.noTopics'.tr,
        style: TextStyle(color: muted, fontSize: 13),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text('finance.learning.allTopics'.tr),
          selected: selectedTopic == null,
          onSelected: (_) => onSelected(null),
          selectedColor: primary,
          backgroundColor: surface,
          side: BorderSide(color: border),
          labelStyle: TextStyle(
            color: selectedTopic == null ? inverse : text,
            fontSize: 12,
          ),
        ),
        ...topics.map((topic) {
          final selected = selectedTopic == topic.topic;
          return ChoiceChip(
            label: Text(_topicLabel(topic.topic)),
            selected: selected,
            onSelected: (_) => onSelected(topic.topic),
            selectedColor: primary,
            backgroundColor: surface,
            side: BorderSide(color: border),
            labelStyle: TextStyle(
              color: selected ? inverse : text,
              fontSize: 12,
            ),
          );
        }),
      ],
    );
  }

  String _topicLabel(String topic) {
    final key = 'finance.learning.topic.$topic';
    final translated = key.tr;
    return translated == key ? topic : translated;
  }
}

class _LessonList extends StatelessWidget {
  const _LessonList({
    required this.lessons,
    required this.loading,
    required this.error,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.onRetry,
    required this.onLessonTap,
  });

  final List<FinanceLearningLessonSummaryEntity> lessons;
  final bool loading;
  final String? error;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final VoidCallback onRetry;
  final ValueChanged<FinanceLearningLessonSummaryEntity> onLessonTap;

  @override
  Widget build(BuildContext context) {
    if (loading && lessons.isEmpty) {
      return const SizedBox(height: 140, child: AppLoader());
    }
    if (error != null && lessons.isEmpty) {
      return _ErrorCard(message: error!, onRetry: onRetry);
    }
    if (lessons.isEmpty) {
      return AppEmptyState(
        message: 'finance.learning.noLessons'.tr,
        icon: Icons.menu_book_outlined,
      );
    }
    return Column(
      children: lessons
          .map(
            (lesson) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LessonCard(
                lesson: lesson,
                surface: surface,
                border: border,
                text: text,
                muted: muted,
                primary: primary,
                onTap: () => onLessonTap(lesson),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.onTap,
  });

  final FinanceLearningLessonSummaryEntity lesson;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(
                lesson.completed
                    ? Icons.check_circle_rounded
                    : Icons.menu_book_outlined,
                color: lesson.completed ? primary : muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lesson.contentType} · ${lesson.xpReward} XP',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      message: message,
      icon: Icons.error_outline_rounded,
      action: TextButton(onPressed: onRetry, child: Text('common.retry'.tr)),
    );
  }
}
