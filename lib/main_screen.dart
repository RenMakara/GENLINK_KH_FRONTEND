import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/community/presentation/bindings/community_binding.dart';
import 'package:genlink_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/screens/finance_screen.dart';
import 'package:genlink_frontend/features/home/presentation/bindings/home_binding.dart';
import 'package:genlink_frontend/features/home/presentation/screens/home_screen.dart';
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
  int currentIndex = 1;

  /// Exactly one entry per nav item — [IndexedStack] asserts the index is
  /// in range, so a short list crashes the moment a later tab is tapped.
  late final List<Widget> pages = [
    // Home's quick actions switch tabs, which only this shell can do.
    HomeScreen(onNavigateTab: _onItemTapped),
    const CommunityScreen(),
    const FinanceScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Inline tabs are not pushed as routes, so their bindings register
    // here — GetView resolves each controller on first build.
    HomeBinding().dependencies();
    ProfileBinding().dependencies();
    CommunityBinding().dependencies();
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
