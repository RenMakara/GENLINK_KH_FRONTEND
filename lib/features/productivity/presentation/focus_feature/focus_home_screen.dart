import 'package:flutter/material.dart';

import 'package:genlink_frontend/features/productivity/presentation/focus_feature/widget/focus_home_widget.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  int selectedMode = 0;
  int selectedSound = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final horizontalPadding = width < 360
        ? 12.0
        : width < 400
        ? 14.0
        : 16.0;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF191919)
          : const Color(0xFFF7F7F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              10,
              horizontalPadding,
              24,
            ),
            children: [
              // ==================================================
              // HEADER
              // ==================================================
              FocusHeader(
                title: 'Focus',
                onBack: () {
                  Navigator.of(context).pop();
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // FOCUS MODES
              // ==================================================
              const FocusSectionTitle(title: 'Focus Mode'),

              const SizedBox(height: 10),

              FocusModes(
                modes: [
                  FocusModeData(
                    icon: Icons.timer_outlined,
                    title: 'Pomodoro',
                    subtitle: '25 min sessions',
                    selected: selectedMode == 0,
                  ),
                  FocusModeData(
                    icon: Icons.speed_rounded,
                    title: 'Stopwatch',
                    subtitle: 'Open timer',
                    selected: selectedMode == 1,
                  ),
                  FocusModeData(
                    icon: Icons.bolt_outlined,
                    title: 'Deep Focus',
                    subtitle: '90 min block',
                    selected: selectedMode == 2,
                  ),
                  FocusModeData(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Study Challenge',
                    subtitle: 'Timed quiz mode',
                    selected: selectedMode == 3,
                  ),
                ],
                onSelected: (index) {
                  setState(() {
                    selectedMode = index;
                  });
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // AMBIENT SOUNDS
              // ==================================================
              const FocusSectionTitle(title: 'Ambient Sounds'),

              const SizedBox(height: 10),

              FocusAmbientSounds(
                selectedIndex: selectedSound,
                sounds: const [
                  AmbientSoundData(
                    icon: Icons.nature_outlined,
                    title: 'Nature',
                  ),
                  AmbientSoundData(
                    icon: Icons.water_drop_outlined,
                    title: 'Rain',
                  ),
                  AmbientSoundData(icon: Icons.coffee_outlined, title: 'Café'),
                  AmbientSoundData(
                    icon: Icons.graphic_eq_rounded,
                    title: 'White Noise',
                  ),
                ],
                onSelected: (index) {
                  setState(() {
                    selectedSound = index;
                  });
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // RECENT SESSIONS
              // ==================================================
              const FocusSectionTitle(title: 'Recent Sessions'),

              const SizedBox(height: 10),

              const FocusRecentSessions(
                sessions: [
                  FocusSessionData(
                    icon: Icons.timer_outlined,
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
                    icon: Icons.timer_outlined,
                    title: 'Pomodoro',
                    date: 'Jul 1',
                    duration: '25 min',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==================================================
              // START BUTTON
              // ==================================================
              FocusStartButton(
                text: 'Start Focus Session',
                onTap: () async {
                  debugPrint('Start Focus Mode: $selectedMode');

                  await Future.delayed(const Duration(milliseconds: 500));

                  if (!mounted) return;

                  // TODO:
                  // Navigate to Focus Timer screen.
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
