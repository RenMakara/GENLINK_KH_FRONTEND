import 'package:flutter/material.dart';

import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';

class QuizGradientButton extends StatelessWidget {
  const QuizGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.height = 60,
    this.borderRadius = AppRadius.pill,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: isOutlined
          ? AppButtonVariant.secondary
          : AppButtonVariant.primary,
      loading: isLoading,
      icon: icon,
      height: height,
      radius: borderRadius,
    );
  }
}
