import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/community/screens/community_screen.dart';
import 'package:genlink_frontend/features/finance/screens/finance_screen.dart';
import 'package:genlink_frontend/shared/widgets/bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    // HomeScreen(),
    CommunityScreen(),
    FinanceScreen(),
    // ProfileScreen(),
  ];

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
