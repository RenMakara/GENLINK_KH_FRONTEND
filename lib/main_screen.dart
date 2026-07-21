import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/community/screens/community_screen.dart';
import 'package:genlink_frontend/features/finance/screens/finance_screen.dart';
import 'package:genlink_frontend/features/profile/presentation/bindings/profile_binding.dart';
import 'package:genlink_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:genlink_frontend/shared/widgets/bottom_nav_bar.dart';

/// Signed-in shell. The tab order here must match [BottomNavBar]:
/// Home, Community, Finance, Profile.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  /// Exactly one entry per nav item — [IndexedStack] asserts the index is
  /// in range, so a short list crashes the moment a later tab is tapped.
  final List<Widget> pages = const [
    _ComingSoon(label: 'Home'),
    CommunityScreen(),
    FinanceScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // The Profile tab is rendered inline rather than pushed as a route, so
    // its binding has to be registered here — GetView resolves the
    // controller on first build.
    ProfileBinding().dependencies();
  }

  void _onItemTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  void _onCenterTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),

      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: _onItemTapped,
        onCenterTap: _onCenterTap,
      ),
    );
  }
}

/// Placeholder for a tab whose screen is owned by another teammate.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: AppEmptyState(
        message: '$label is not built yet.',
        icon: Icons.construction_outlined,
      ),
    );
  }
}
