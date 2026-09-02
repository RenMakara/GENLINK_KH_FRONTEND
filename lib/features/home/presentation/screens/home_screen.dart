import 'package:flutter/material.dart';

import '../../../community/presentation/screens/community_screen.dart';

/// GenLink KH Mobile Home Screen.
///
/// Role: "Campus Life & Connections"
///
/// Answers:
/// 1. What is happening around me?
/// 2. What campus activity is relevant to me?
/// 3. Who is talking about what on campus?
/// 4. What events are upcoming?
///
/// Structure:
/// - Header: GenLink branding + Search + Messages/Chat + Notifications
/// - Content Navigation: Feed | Forum | Events
/// - Home Content:
///   - Feed: Stories + Campus Feed posts & discussions
///   - Forum: Categories & Trending discussions
///   - Events: Campus activities & RSVP
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onNavigateTab});

  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    return CommunityScreen(
      isHomeScreen: true,
      onNavigateTab: onNavigateTab,
    );
  }
}
