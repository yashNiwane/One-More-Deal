import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import 'landing_screen.dart';

import 'properties/my_properties_screen.dart';
import 'properties/properties_feed_screen.dart';
import 'profile_screen.dart';
import 'admin/admin_approvals_screen.dart';

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
    // Set iOS-style light status bar for internal screens
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF9F9F9),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_lastCheckedAt != null &&
          DateTime.now().difference(_lastCheckedAt!) < const Duration(minutes: 10)) {
        return;
      }
      _checkSession();
    }
  }

  Future<void> _checkSession() async {
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
          backgroundColor: AppColors.iosDestructive,
        ),
      );
      return;
    }
    _lastCheckedAt = DateTime.now();
  }

  static const _adminPhone = '9356965876';
  bool get _isAdmin => AuthService.userPhone == _adminPhone;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const PropertiesFeedScreen(),
      const MyPropertiesScreen(),
      const ProfileScreen(),
      if (_isAdmin) const AdminApprovalsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.iosGroupedBg,
      body: pages[_currentIndex],
      extendBody: true,
      bottomNavigationBar: _buildFrostedBottomNav(),
    );
  }

  Widget _buildFrostedBottomNav() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.frostedNavBg,
            border: Border(
              top: BorderSide(color: AppColors.frostedNavBorder, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.explore_rounded, 'Discover'),
                  _buildNavItem(1, Icons.business_center_rounded, 'Listings'),
                  _buildNavItem(2, Icons.person_rounded, 'Profile'),
                  if (_isAdmin) _buildNavItem(3, Icons.admin_panel_settings_rounded, 'Admin'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.iosSystemBlue : AppColors.iosSecondaryLabel,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.iosSystemBlue : AppColors.iosSecondaryLabel,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
