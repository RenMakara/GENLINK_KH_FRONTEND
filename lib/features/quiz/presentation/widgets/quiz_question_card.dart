import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/typography/app_typography.dart';

/// Modern iOS-style question card with category badge, large prominent
/// question text, and optional bilingual Khmer/English subtitle.
class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({
    super.key,
    required this.question,
    this.category,
  });

  final String question;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    // Split question if it contains an inline translation (separated by newline)
    final trimmed = question.trim();
    final parts = trimmed.split(RegExp(r'\r?\n+'));
    final primaryText = parts.isNotEmpty ? parts.first.trim() : trimmed;
    final secondaryText =
        parts.length > 1 ? parts.sublist(1).join(' ').trim() : null;

    final hasCategory = category != null && category!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: semantic.surface,
        borderRadius: BorderRadius.circular(AppRadius.squircle),
        border: Border.all(color: semantic.borderSubtle),
        boxShadow: semantic.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasCategory) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: semantic.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: semantic.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 13,
                    color: semantic.secondaryText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    category!.trim(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: semantic.secondaryText,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Primary Question Text (22-24px, strong contrast)
          Text(
            primaryText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: semantic.primaryText,
              height: 1.35,
              fontFamilyFallback: const [
                AppTypography.englishFontFamily,
                AppTypography.khmerFontFamily,
              ],
            ),
          ),

          // Secondary translation (e.g. Khmer translation below English)
          if (secondaryText != null && secondaryText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              secondaryText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: semantic.secondaryText,
                height: 1.4,
                fontFamily: AppTypography.khmerFontFamily,
                fontFamilyFallback: const [
                  AppTypography.khmerFontFamily,
                  AppTypography.englishFontFamily,
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
