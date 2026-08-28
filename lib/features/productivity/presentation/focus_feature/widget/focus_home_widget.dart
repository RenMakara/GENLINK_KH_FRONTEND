import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';

// ============================================================
// DATA MODELS
// ============================================================

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

// ============================================================
// COLORS
// ============================================================

class _FocusColors {
  final bool isDark;

  _FocusColors(this.isDark);

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

// ============================================================
// HEADER
// ============================================================

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
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: colors.textPrimary,
              ),
            ),
          ),

          const SizedBox(width: 10),
        ],

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

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
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ============================================================
// FOCUS MODES
// ============================================================

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
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        childAspectRatio: 1.65,
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
        setState(() => pressed = true);
      },
      onTapUp: (_) {
        setState(() => pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => pressed = false);
      },
      child: AnimatedScale(
        scale: pressed ? .96 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? colors.textPrimary : colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? colors.textPrimary : colors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: .10)
                      : colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  widget.mode.icon,
                  size: 16,
                  color: selected ? Colors.white : colors.textMuted,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mode.title,
                      style: TextStyle(
                        color: selected ? Colors.white : colors.textPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      widget.mode.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white.withValues(alpha: .65)
                            : colors.textMuted,
                        fontSize: 7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// AMBIENT SOUNDS
// ============================================================

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

          if (i != sounds.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

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
        setState(() => pressed = true);
      },
      onTapUp: (_) {
        setState(() => pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => pressed = false);
      },
      child: AnimatedScale(
        scale: pressed ? .93 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.productivityAccent.withValues(alpha: .10)
                : colors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: widget.selected
                  ? AppColors.productivityAccent.withValues(alpha: .35)
                  : colors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.data.icon,
                size: 14,
                color: widget.selected
                    ? AppColors.productivityAccent
                    : colors.textMuted,
              ),

              const SizedBox(height: 3),

              Text(
                widget.data.title,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 6,
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

// ============================================================
// RECENT SESSIONS
// ============================================================

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
        borderRadius: BorderRadius.circular(11),
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

class _RecentSessionItem extends StatelessWidget {
  final FocusSessionData data;

  const _RecentSessionItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = _FocusColors(
      Theme.of(context).brightness == Brightness.dark,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: AppColors.productivityAccent.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 12,
              color: AppColors.productivityAccent,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  data.date,
                  style: TextStyle(color: colors.textMuted, fontSize: 7),
                ),
              ],
            ),
          ),

          Text(
            data.duration,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// START BUTTON
// ============================================================

class FocusStartButton extends StatefulWidget {
  final String text;
  final Future<void> Function()? onTap;

  const FocusStartButton({super.key, required this.text, this.onTap});

  @override
  State<FocusStartButton> createState() => _FocusStartButtonState();
}

class _FocusStartButtonState extends State<FocusStartButton> {
  bool pressed = false;
  bool loading = false;

  Future<void> _handleTap() async {
    if (loading) return;

    setState(() {
      pressed = true;
      loading = true;
    });

    await Future.delayed(const Duration(milliseconds: 100));

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
      onTap: _handleTap,
      onTapDown: (_) {
        if (!loading) {
          setState(() => pressed = true);
        }
      },
      onTapUp: (_) {
        if (!loading) {
          setState(() => pressed = false);
        }
      },
      onTapCancel: () {
        if (!loading) {
          setState(() => pressed = false);
        }
      },
      child: AnimatedScale(
        scale: pressed ? .97 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.productivityAccent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: pressed
                ? [
                    BoxShadow(
                      color: AppColors.productivityAccent.withValues(
                        alpha: .25,
                      ),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
