import 'package:flutter/material.dart';

// WALLET ACTION
class WalletAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const WalletAction({
    super.key,
    required this.icon,
    required this.title,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),

        child: Container(
          height: 58,

          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(icon, size: 18, color: foreground.withValues(alpha: .85)),

              const SizedBox(height: 4),

              Text(
                title,
                style: TextStyle(
                  color: foreground.withValues(alpha: .80),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// WALLET INFO CARD
class WalletInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  final IconData icon;
  final Color iconColor;

  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  const WalletInfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,

                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(9),
                ),

                child: Icon(icon, color: iconColor, size: 16),
              ),

              const Spacer(),

              Text(
                title,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 2),

          Text(subtitle, style: TextStyle(color: textMuted, fontSize: 9)),
        ],
      ),
    );
  }
}

// TRANSACTION DATA
class WalletTransactionData {
  final String title;
  final String subtitle;
  final String amount;

  final IconData icon;
  final Color iconColor;
  final Color amountColor;

  const WalletTransactionData({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.amountColor,
  });
}

// WALLET TRANSACTION
class WalletTransaction extends StatelessWidget {
  final WalletTransactionData data;

  final Color background;
  final Color textPrimary;
  final Color textMuted;

  const WalletTransaction({
    super.key,
    required this.data,
    required this.background,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,

      child: Row(
        children: [
          // Icon
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(11),
            ),

            child: Icon(data.icon, size: 18, color: data.iconColor),
          ),

          const SizedBox(width: 11),

          // Text
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(color: textMuted, fontSize: 9),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Amount
          Text(
            data.amount,
            style: TextStyle(
              color: data.amountColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
