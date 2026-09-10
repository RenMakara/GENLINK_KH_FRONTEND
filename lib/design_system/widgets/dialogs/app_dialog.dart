import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../radius/app_radius.dart';
import '../buttons/app_button.dart';

abstract final class AppDialog {
  static Future<bool> confirm({
    required String title,
    String? message,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    final context = Get.context;
    if (context == null) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(title, style: theme.textTheme.titleMedium),
          content: message == null
              ? null
              : Text(message, style: theme.textTheme.bodyMedium),
          actions: [
            AppButton.text(
              label: cancelLabel ?? 'common.cancel'.tr,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppButton(
              label: confirmLabel ?? 'common.continue'.tr,
              variant: destructive
                  ? AppButtonVariant.danger
                  : AppButtonVariant.primary,
              expanded: false,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

abstract final class AppSnackbar {
  static void show(String message) => _show(message, isError: false);

  static void error(String message) => _show(message, isError: true);

  static void _show(String message, {required bool isError}) {
    final context = Get.context;
    if (context == null) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final scheme = Theme.of(context).colorScheme;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? scheme.error : null,
          duration: Duration(seconds: isError ? 4 : 2),
        ),
      );
  }
}
