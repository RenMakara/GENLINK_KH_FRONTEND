import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

class ChatFinanceCard extends StatelessWidget {
  final Map<String, dynamic>? transaction;
  final String? content;
  final bool isMine;
  final VoidCallback? onViewInFinance;
  final VoidCallback? onTapReceipt;

  const ChatFinanceCard({
    super.key,
    this.transaction,
    this.content,
    required this.isMine,
    this.onViewInFinance,
    this.onTapReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfacePrimary;
    final borderColor = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final rawText = content ?? '';
    final hasTxn = transaction != null;
    
    final bool isSend;
    final String formattedAmount;
    final bool isCompleted;
    final String note;

    if (hasTxn) {
      final type = (transaction!['type'] as String? ?? 'send').toLowerCase();
      isSend = type == 'send';
      final amountNum = transaction!['amount'] as num? ?? 0;
      final currency = (transaction!['currency'] as String? ?? 'USD').toUpperCase();
      formattedAmount = currency == 'KHR'
          ? '៛${amountNum.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'
          : '\$${amountNum.toStringAsFixed(2)}';
      final status = (transaction!['status'] as String? ?? 'completed').toLowerCase();
      isCompleted = status == 'completed';
      note = transaction!['note'] as String? ?? '';
    } else {
      isSend = !rawText.toLowerCase().contains('request');
      final amountMatch = RegExp(r'(\$|៛)[\d,]+(\.\d{2})?').firstMatch(rawText);
      formattedAmount = amountMatch?.group(0) ?? '\$5.00';
      isCompleted = true;
      final parts = rawText.split(RegExp(r'[-:]'));
      note = parts.length > 1 ? parts.sublist(1).join('-').trim() : '';
    }

    final headerText = isSend
        ? ('chat.sentMoney'.tr.isNotEmpty && 'chat.sentMoney'.tr != 'chat.sentMoney'
            ? 'chat.sentMoney'.tr
            : 'Sent Money')
        : ('chat.requestedMoney'.tr.isNotEmpty && 'chat.requestedMoney'.tr != 'chat.requestedMoney'
            ? 'chat.requestedMoney'.tr
            : 'Requested Money');

    final statusText = isCompleted
        ? ('chat.completed'.tr.isNotEmpty && 'chat.completed'.tr != 'chat.completed'
            ? 'chat.completed'.tr
            : 'Completed')
        : ('chat.pending'.tr.isNotEmpty && 'chat.pending'.tr != 'chat.pending'
            ? 'chat.pending'.tr
            : 'Pending');

    return Container(
      constraints: const BoxConstraints(maxWidth: 270),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMine
              ? AppColors.chatPrimary.withValues(alpha: 0.3)
              : borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.chatPrimary.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(
                  isSend ? Icons.arrow_outward_rounded : Icons.call_received_rounded,
                  size: 15,
                  color: AppColors.chatPrimary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    headerText,
                    style: const TextStyle(
                      color: AppColors.chatPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isCompleted ? AppColors.success : AppColors.warning)
                        .withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: isCompleted ? AppColors.success : AppColors.warning,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedAmount,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          InkWell(
            onTap: onViewInFinance ?? onTapReceipt,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 14,
                    color: AppColors.chatPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'chat.viewInFinance'.tr.isNotEmpty && 'chat.viewInFinance'.tr != 'chat.viewInFinance'
                        ? 'chat.viewInFinance'.tr
                        : 'View in Finance',
                    style: const TextStyle(
                      color: AppColors.chatPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
