import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'genlink_confirm_dialog.dart';

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

    final result = await GenLinkConfirmDialog.show(
      context: context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      type: destructive ? GenLinkDialogType.danger : GenLinkDialogType.confirm,
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
