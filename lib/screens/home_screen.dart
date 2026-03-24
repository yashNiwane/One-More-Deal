import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../models/property_model.dart';
import '../services/auth_service.dart';
import 'landing_screen.dart';

import 'home_page_screen.dart';
import 'properties/my_properties_screen.dart';
import 'properties/properties_feed_screen.dart';
import 'profile_screen.dart';
import 'admin/admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  DateTime? _lastCheckedAt;
  int? _discoverFocusPropertyId;
  PropertyFilter? _discoverFocusFilter;
  int? _discoverFocusSortIndex;
  int _discoverFocusToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSession();
    // Set iOS-style light status bar for internal screens
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF9F9F9),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
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
          DateTime.now().difference(_lastCheckedAt!) <
              const Duration(minutes: 10)) {
        return;
      }
      _checkSession();
    }
  }

  Future<void> _checkSession() async {
    final isValid = await AuthService.isSessionValid();
    if (!isValid && mounted) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (_) => false,
      );
      if (!mounted) return;
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

  bool get _isAdmin => AuthService.isAdmin;

  void _openPropertyInDiscover(int propertyId, UserTypeFilter? userTypeHint) {
    setState(() {
      _discoverFocusPropertyId = propertyId;
      _discoverFocusFilter = userTypeHint != null 
          ? (PropertyFilter(city: 'Pune')..userTypeFilter = userTypeHint)
          : null;
      _discoverFocusSortIndex = null;
      _discoverFocusToken++;
      _currentIndex = 1;
    });
  }

  void _openDiscoverWithFilter(PropertyFilter filter) {
    setState(() {
      _discoverFocusPropertyId = null;
      _discoverFocusFilter = filter;
      _discoverFocusSortIndex = null;
      _discoverFocusToken++;
      _currentIndex = 1;
    });
  }

  void _openDiscoverWithSort(int sortIndex) {
    setState(() {
      _discoverFocusPropertyId = null;
      _discoverFocusFilter = null;
      _discoverFocusSortIndex = sortIndex;
      _discoverFocusToken++;
      _currentIndex = 1; // Discover tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePageScreen(
        onOpenDiscoverProperty: _openPropertyInDiscover,
        onOpenDiscoverWithFilter: _openDiscoverWithFilter,
        onOpenDiscoverWithSort: _openDiscoverWithSort,
      ),
      PropertiesFeedScreen(
        key: ValueKey('discover_focus_$_discoverFocusToken'),
        initialPropertyId: _discoverFocusPropertyId,
        initialFilter: _discoverFocusFilter,
        initialSortIndex: _discoverFocusSortIndex,
      ),
      const MyPropertiesScreen(),
      const ProfileScreen(),
      if (_isAdmin) const AdminScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.iosGroupedBg,
      body: pages[_currentIndex],
      extendBody: true,
      bottomNavigationBar: _buildFrostedBottomNav(),
    );
  }

  Widget _buildFrostedBottomNav() {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.7),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildNavItem(0, Icons.home_rounded, 'Home'),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        1,
                        Icons.explore_rounded,
                        'Discover',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        2,
                        Icons.business_center_rounded,
                        'Listings',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(3, Icons.person_rounded, 'Profile'),
                    ),
                    if (_isAdmin)
                      Expanded(
                        child: _buildNavItem(
                          4,
                          Icons.admin_panel_settings_rounded,
                          'Admin',
                        ),
                      ),
                  ],
                ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.white.withValues(alpha: 0.16)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.darkGray,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
