import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/widgets/dialogs/genlink_confirm_dialog.dart';

class FocusLeaveDialog extends StatelessWidget {
  const FocusLeaveDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    return await GenLinkConfirmDialog.showDanger(
      context: context,
      title: 'focus.leaveTitle'.tr,
      message: 'focus.leaveMessage'.tr,
      confirmLabel: 'focus.leave'.tr,
      cancelLabel: 'common.cancel'.tr,
      icon: Icons.exit_to_app_rounded,
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GenLinkConfirmDialog(
      type: GenLinkDialogType.danger,
      title: 'focus.leaveTitle'.tr,
      message: 'focus.leaveMessage'.tr,
      confirmLabel: 'focus.leave'.tr,
      cancelLabel: 'common.cancel'.tr,
      icon: Icons.exit_to_app_rounded,
    );
  }
}
