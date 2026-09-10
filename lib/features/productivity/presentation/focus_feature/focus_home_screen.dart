import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/productivity/domain/entities/productivity_entities.dart';
import 'package:genlink_frontend/features/productivity/presentation/controllers/productivity_controller.dart';
import 'package:genlink_frontend/features/productivity/presentation/productivity_scope.dart';
import 'package:genlink_frontend/features/productivity/presentation/focus_feature/widget/focus_home_widget.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  int selectedMode = 0;
  int selectedSound = 0;
  ProductivityController? _controller;

  static const _modeKeys = [
    'POMODORO',
    'STOPWATCH',
    'DEEP_FOCUS',
    'STUDY_CHALLENGE',
  ];
  static const _modeMinutes = [25, 25, 90, 45];
  static const _soundKeys = ['NATURE', 'RAIN', 'CAFE', 'WHITE_NOISE'];

  @override
  void initState() {
    super.initState();
    _controller = ensureProductivityController();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.loadFocusHistory();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _startSession() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      final session = await controller.startFocusSession(
        mode: _modeKeys[selectedMode],
        durationMinutes: _modeMinutes[selectedMode],
        ambientSound: _soundKeys[selectedSound],
      );
      if (!mounted) return;

      final complete = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ActiveFocusDialog(session: session),
      );
      if (complete != true) return;

      await controller.completeFocusSession(session.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Focus session completed.')),
        );
      }
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_errorText(error))));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FocusHeader(
                title: 'Focus',
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 12),
              if (controller != null) ...[
                _FocusStatsSummary(controller: controller),
                const SizedBox(height: 12),
              ],
              FocusModes(
                modes: [
                  FocusModeData(
                    icon: Icons.access_time_rounded,
                    title: 'Pomodoro',
                    subtitle: '25 min sessions',
                    selected: selectedMode == 0,
                  ),
                  FocusModeData(
                    icon: Icons.access_time_rounded,
                    title: 'Stopwatch',
                    subtitle: 'Open timer',
                    selected: selectedMode == 1,
                  ),
                  FocusModeData(
                    icon: Icons.flash_on_outlined,
                    title: 'Deep Focus',
                    subtitle: '90 min block',
                    selected: selectedMode == 2,
                  ),
                  FocusModeData(
                    icon: Icons.star_outline_rounded,
                    title: 'Study Challenge',
                    subtitle: 'Timed quiz mode',
                    selected: selectedMode == 3,
                  ),
                ],
                onSelected: (index) => setState(() => selectedMode = index),
              ),
              const SizedBox(height: 10),
              const FocusSectionTitle(title: 'Ambient Sounds'),
              const SizedBox(height: 7),
              FocusAmbientSounds(
                selectedIndex: selectedSound,
                sounds: const [
                  AmbientSoundData(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Nature',
                  ),
                  AmbientSoundData(
                    icon: Icons.water_drop_outlined,
                    title: 'Rain',
                  ),
                  AmbientSoundData(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Café',
                  ),
                  AmbientSoundData(
                    icon: Icons.bolt_outlined,
                    title: 'White Noise',
                  ),
                ],
                onSelected: (index) => setState(() => selectedSound = index),
              ),
              const SizedBox(height: 12),
              const FocusSectionTitle(title: 'Recent Sessions'),
              const SizedBox(height: 7),
              _recentSessions(controller),
              const SizedBox(height: 10),
              FocusStartButton(
                text: 'Start Focus Session',
                onTap: _startSession,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentSessions(ProductivityController? controller) {
    if (controller == null) {
      return const FocusRecentSessions(sessions: _fallbackSessions);
    }
    return Obx(() {
      final sessions = controller.focusHistory
          .map(_toSessionData)
          .toList(growable: false);
      if (sessions.isEmpty) {
        return const _EmptySessions();
      }
      return FocusRecentSessions(sessions: sessions);
    });
  }
}

class _FocusStatsSummary extends StatelessWidget {
  const _FocusStatsSummary({required this.controller});

  final ProductivityController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = controller.focusStats.value;
      if (stats == null) return const SizedBox.shrink();
      final colors = _FocusPageColors(context);
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            _Stat(value: '${stats.todaySessions}', label: 'Today'),
            _Stat(value: '${stats.todayMinutes}m', label: 'Minutes'),
            _Stat(value: '${stats.totalXp}', label: 'XP'),
          ],
        ),
      );
    });
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = _FocusPageColors(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: colors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();

  @override
  Widget build(BuildContext context) {
    final colors = _FocusPageColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        'No completed sessions yet.',
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.textMuted),
      ),
    );
  }
}

class _ActiveFocusDialog extends StatelessWidget {
  const _ActiveFocusDialog({required this.session});

  final ProductivityFocusSession session;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Focus session started'),
      content: Text(
        '${_modeTitle(session.mode)} · ${_formatMinutes(session.durationMinutes)}\n\n'
        'Stay focused, then complete the session when you are done.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep open'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Complete'),
        ),
      ],
    );
  }
}

FocusSessionData _toSessionData(ProductivityFocusSession session) {
  return FocusSessionData(
    icon: _modeIcon(session.mode),
    title: _modeTitle(session.mode),
    date: _sessionDate(session.endedAt ?? session.startedAt),
    duration: _formatMinutes(session.durationMinutes),
  );
}

IconData _modeIcon(String? mode) => switch (mode?.toUpperCase()) {
  'DEEP_FOCUS' => Icons.flash_on_outlined,
  'STUDY_CHALLENGE' => Icons.star_outline_rounded,
  _ => Icons.bolt_outlined,
};

String _modeTitle(String? mode) => switch (mode?.toUpperCase()) {
  'DEEP_FOCUS' => 'Deep Focus',
  'STUDY_CHALLENGE' => 'Study Challenge',
  'STOPWATCH' => 'Stopwatch',
  _ => 'Pomodoro',
};

String _sessionDate(DateTime? value) {
  if (value == null) return 'Recent';
  final now = DateTime.now();
  if (value.year == now.year &&
      value.month == now.month &&
      value.day == now.day) {
    return 'Today';
  }
  return '${value.month}/${value.day}/${value.year}';
}

String _formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  return remaining == 0 ? '${hours}h' : '${hours}h ${remaining}m';
}

String _errorText(Object error) =>
    error.toString().replaceFirst('Exception: ', '');

class _FocusPageColors {
  _FocusPageColors(BuildContext context)
    : isDark = Theme.of(context).brightness == Brightness.dark;

  final bool isDark;

  Color get surface =>
      isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textMuted =>
      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
  Color get border =>
      isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
}

const _fallbackSessions = [
  FocusSessionData(
    icon: Icons.bolt_outlined,
    title: 'Pomodoro',
    date: 'Today',
    duration: '52 min',
  ),
  FocusSessionData(
    icon: Icons.bolt_outlined,
    title: 'Deep Focus',
    date: 'Yesterday',
    duration: '1h 30m',
  ),
  FocusSessionData(
    icon: Icons.bolt_outlined,
    title: 'Pomodoro',
    date: 'Jul 1',
    duration: '25 min',
  ),
];
