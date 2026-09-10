import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_learning_controller.dart';
import 'investing_quiz.dart';

class InvestingBasicsScreen extends StatefulWidget {
  const InvestingBasicsScreen({
    super.key,
    required this.lessonId,
    this.initialLesson,
  });

  final String lessonId;
  final FinanceLearningLessonSummaryEntity? initialLesson;

  @override
  State<InvestingBasicsScreen> createState() => _InvestingBasicsScreenState();
}

class _InvestingBasicsScreenState extends State<InvestingBasicsScreen> {
  FinanceLearningController get controller =>
      Get.find<FinanceLearningController>();

  @override
  void initState() {
    super.initState();
    controller.loadLesson(widget.lessonId);
  }

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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Obx(() {
          final lesson = controller.selectedLesson.value;
          final error = controller.detailErrorMessage.value;

          if (controller.isDetailLoading.value && lesson == null) {
            return const AppLoader();
          }

          if (error != null && lesson == null) {
            return _DetailError(message: error, onRetry: _reload);
          }

          if (lesson == null) {
            return _DetailError(
              message: 'finance.learning.noLesson'.tr,
              onRetry: _reload,
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    AppBackButton(),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        lesson.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: text,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                    children: [
                      _MetaRow(lesson: lesson, muted: muted, primary: primary),

                      const SizedBox(height: 18),

                      Text(
                        lesson.title,
                        style: TextStyle(
                          color: text,
                          fontSize: 24,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: SelectableText(
                          lesson.content,
                          style: TextStyle(
                            color: text,
                            fontSize: 15,
                            height: 1.55,
                          ),
                        ),
                      ),

                      if (lesson.mediaUrl != null &&
                          lesson.mediaUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),

                        Text(
                          lesson.mediaUrl!,
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 20),

                      if (controller.mutationErrorMessage.value != null)
                        Text(
                          controller.mutationErrorMessage.value!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),

                      AppButton(
                        label: lesson.completed
                            ? 'finance.learning.completed'.tr
                            : 'finance.learning.markComplete'.tr,
                        icon: lesson.completed
                            ? Icons.check_circle_outline_rounded
                            : Icons.done_rounded,
                        loading: controller.isCompleteSubmitting.value,
                        onPressed: lesson.completed
                            ? null
                            : () async {
                                final success = await controller.completeLesson(
                                  widget.lessonId,
                                );

                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'finance.learning.completeSuccess'.tr,
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),

                      if (lesson.questionCount > 0) ...[
                        const SizedBox(height: 12),

                        AppButton.secondary(
                          label: 'finance.learning.startQuiz'.tr,
                          icon: Icons.quiz_outlined,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InvestingQuizScreen(
                                lessonId: widget.lessonId,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _reload() => controller.loadLesson(widget.lessonId);
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.lesson,
    required this.muted,
    required this.primary,
  });

  final FinanceLearningLessonDetailEntity lesson;
  final Color muted;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final values = <String>[
      lesson.topic,
      lesson.contentType,
      if (lesson.estimatedTime != null) '${lesson.estimatedTime} min',
      '${lesson.xpReward} XP',
      if (lesson.quizPassed) 'finance.learning.quizPassed'.tr,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => Chip(
              label: Text(value),
              avatar: value == lesson.topic
                  ? Icon(Icons.topic_outlined, color: primary, size: 16)
                  : null,
              labelStyle: TextStyle(color: muted, fontSize: 12),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: Text('common.retry'.tr)),
          ],
        ),
      ),
    );
  }
}
