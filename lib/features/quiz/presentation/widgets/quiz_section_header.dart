import 'package:flutter/material.dart';

import '../../../../design_system/widgets/buttons/app_button.dart';

/// Shared title/action row for Quiz sections.
class QuizSectionHeader extends StatelessWidget {
  const QuizSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: titleStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null && onAction != null)
          AppButton.text(label: actionLabel!, onPressed: onAction),
      ],
    );
  }
}
