import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import 'landing_screen.dart';

import 'properties/my_properties_screen.dart';
import 'properties/properties_feed_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  DateTime? _lastCheckedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Skip re-check if we verified within the last 10 minutes
      if (_lastCheckedAt != null &&
          DateTime.now().difference(_lastCheckedAt!) < const Duration(minutes: 10)) {
        return;
      }
      _checkSession();
    }
  }

  Future<void> _checkSession() async {
    // Only verify single-device session — NO subscription re-check here.
    // Subscription was already validated in SplashScreen before reaching HomeScreen.
    final isValid = await AuthService.isSessionValid();
    if (!isValid && mounted) {
      await AuthService.logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (_) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out: Account accessed from another device.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _lastCheckedAt = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const PropertiesFeedScreen(),
      const MyPropertiesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mediumGray,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.business_center_rounded), label: 'My Listings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
