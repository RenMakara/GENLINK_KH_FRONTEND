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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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

              const SizedBox(height: 12),

              // ==================================================
              // FOCUS MODES
              // ==================================================
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
                onSelected: (index) {
                  setState(() {
                    selectedMode = index;
                  });
                },
              ),

              const SizedBox(height: 10),

              // ==================================================
              // AMBIENT SOUNDS TITLE
              // ==================================================
              const FocusSectionTitle(title: 'Ambient Sounds'),

              const SizedBox(height: 7),

              // ==================================================
              // AMBIENT SOUNDS
              // ==================================================
              FocusAmbientSounds(
                selectedIndex: selectedSound,
                sounds: [
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
                onSelected: (index) {
                  setState(() {
                    selectedSound = index;
                  });
                },
              ),

              const SizedBox(height: 12),

              // ==================================================
              // RECENT SESSIONS
              // ==================================================
              const FocusSectionTitle(title: 'Recent Sessions'),

              const SizedBox(height: 7),

              FocusRecentSessions(
                sessions: [
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
                ],
              ),

              const SizedBox(height: 10),

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
                  // Navigate to Focus Timer screen
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
