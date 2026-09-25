import 'package:flutter/material.dart';

import '../../../community/presentation/screens/community_screen.dart';

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
