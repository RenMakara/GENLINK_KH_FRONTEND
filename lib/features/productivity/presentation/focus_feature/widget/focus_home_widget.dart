import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';

class FocusModeData {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;

  const FocusModeData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.selected = false,
  });
}

class AmbientSoundData {
  final IconData icon;
  final String title;

  const AmbientSoundData({required this.icon, required this.title});
}

class FocusSessionData {
  final IconData icon;
  final String title;
  final String date;
  final String duration;

  const FocusSessionData({
    required this.icon,
    required this.title,
    required this.date,
    required this.duration,
  });
}

class _FocusColors {
  final bool isDark;

  const _FocusColors(this.isDark);

  Color get background =>
      isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

  Color get surface =>
      isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;

  Color get surfaceSecondary =>
      isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;

  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

  Color get textMuted =>
      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

  Color get border =>
      isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
}

class FocusHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const FocusHeader({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = _FocusColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Row(
      children: [
        if (onBack != null) ...[
          AppBackButton(onPressed: onBack),
          const SizedBox(width: 12),
        ],

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class FocusSectionTitle extends StatelessWidget {
  final String title;

  const FocusSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = _FocusColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Text(
      title,
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}

class FocusModes extends StatelessWidget {
  final List<FocusModeData> modes;
  final ValueChanged<int>? onSelected;

  const FocusModes({super.key, required this.modes, this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.50,
      ),
      itemBuilder: (context, index) {
        return _FocusModeCard(
          mode: modes[index],
          onTap: () => onSelected?.call(index),
        );
      },
    );
  }
}

// ============================================================
// FOCUS MODE CARD
// ============================================================

class _FocusModeCard extends StatefulWidget {
  final FocusModeData mode;
  final VoidCallback? onTap;

  const _FocusModeCard({required this.mode, this.onTap});

  @override
  State<_FocusModeCard> createState() => _FocusModeCardState();
}

class _FocusModeCardState extends State<_FocusModeCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = _FocusColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    final selected = widget.mode.selected;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          pressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          pressed = false;
        });

        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() {
          pressed = false;
        });
      },
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: selected ? colors.textPrimary : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.textPrimary : colors.border,
            ),
          ),
          child: Row(
            children: [
              // ------------------------------------------------
              // ICON
              // ------------------------------------------------
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.10)
                      : colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.mode.icon,
                  size: 18,
                  color: selected ? Colors.white : colors.textSecondary,
                ),
              ),

              const SizedBox(width: 10),

              // ------------------------------------------------
              // TEXT
              // ------------------------------------------------
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mode.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      widget.mode.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.65)
                            : colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              // ------------------------------------------------
              // CHECK
              // ------------------------------------------------
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.productivityAccent
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.productivityAccent
                        : colors.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FocusAmbientSounds extends StatelessWidget {
  final List<AmbientSoundData> sounds;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  const FocusAmbientSounds({
    super.key,
    required this.sounds,
    this.selectedIndex = 0,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < sounds.length; i++) ...[
          Expanded(
            child: _AmbientSoundItem(
              data: sounds[i],
              selected: i == selectedIndex,
              onTap: () => onSelected?.call(i),
            ),
          ),

          if (i != sounds.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

// ============================================================
// AMBIENT SOUND ITEM
// ============================================================

class _AmbientSoundItem extends StatefulWidget {
  final AmbientSoundData data;
  final bool selected;
  final VoidCallback? onTap;

  const _AmbientSoundItem({
    required this.data,
    required this.selected,
    this.onTap,
  });

  @override
  State<_AmbientSoundItem> createState() => _AmbientSoundItemState();
}

class _AmbientSoundItemState extends State<_AmbientSoundItem> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = _FocusColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          pressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          pressed = false;
        });

        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() {
          pressed = false;
        });
      },
      child: AnimatedScale(
        scale: pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 64,
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.productivityAccent.withValues(alpha: 0.10)
                : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.selected
                  ? AppColors.productivityAccent.withValues(alpha: 0.40)
                  : colors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ------------------------------------------------
              // ICON
              // ------------------------------------------------
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? AppColors.productivityAccent.withValues(alpha: 0.12)
                      : colors.surfaceSecondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.data.icon,
                  size: 15,
                  color: widget.selected
                      ? AppColors.productivityAccent
                      : colors.textMuted,
                ),
              ),

              const SizedBox(height: 5),

              // ------------------------------------------------
              // TITLE
              // ------------------------------------------------
              Text(
                widget.data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.selected
                      ? colors.textPrimary
                      : colors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FocusRecentSessions extends StatelessWidget {
  final List<FocusSessionData> sessions;

  const FocusRecentSessions({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final colors = _FocusColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < sessions.length; i++) ...[
            _RecentSessionItem(data: sessions[i]),

            if (i != sessions.length - 1)
              Divider(height: 1, color: colors.border),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// RECENT SESSION ITEM
// ============================================================

class _RecentSessionItem extends StatelessWidget {
  final FocusSessionData data;

  const _RecentSessionItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = _FocusColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          // ------------------------------------------------
          // ICON
          // ------------------------------------------------
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.productivityAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              data.icon,
              size: 16,
              color: AppColors.productivityAccent,
            ),
          ),

          const SizedBox(width: 11),

          // ------------------------------------------------
          // SESSION INFO
          // ------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  data.date,
                  style: TextStyle(color: colors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),

          // ------------------------------------------------
          // DURATION
          // ------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data.duration,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FocusStartButton extends StatefulWidget {
  final String text;
  final Future<void> Function()? onTap;
  final bool enabled;

  const FocusStartButton({
    super.key,
    required this.text,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<FocusStartButton> createState() => _FocusStartButtonState();
}

class _FocusStartButtonState extends State<FocusStartButton> {
  bool pressed = false;
  bool loading = false;

  Future<void> _handleTap() async {
    if (loading || !widget.enabled) return;

    setState(() {
      pressed = true;
      loading = true;
    });

    await Future.delayed(const Duration(milliseconds: 120));

    if (!mounted) return;

    setState(() {
      pressed = false;
    });

    try {
      await widget.onTap?.call();
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? _handleTap : null,

      onTapDown: (_) {
        if (!loading && widget.enabled) {
          setState(() {
            pressed = true;
          });
        }
      },

      onTapUp: (_) {
        if (!loading && widget.enabled) {
          setState(() {
            pressed = false;
          });
        }
      },

      onTapCancel: () {
        if (!loading && widget.enabled) {
          setState(() {
            pressed = false;
          });
        }
      },

      child: AnimatedScale(
        scale: pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            color: widget.enabled
                ? AppColors.productivityAccent
                : AppColors.productivityAccent.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            boxShadow: pressed
                ? [
                    BoxShadow(
                      color: AppColors.productivityAccent.withValues(
                        alpha: 0.25,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        size: 19,
                        color: Colors.white,
                      ),

                      const SizedBox(width: 7),

                      Text(
                        widget.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
