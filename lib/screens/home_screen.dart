import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../models/property_model.dart';
import '../services/auth_service.dart';
import 'landing_screen.dart';

import 'home_page_screen.dart';
import 'properties/add_builder_property_screen.dart';
import 'properties/add_property_screen.dart';
import 'properties/my_properties_screen.dart';
import 'properties/properties_feed_screen.dart';
import 'profile_screen.dart';
import 'properties/filter_bottom_sheet.dart';

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
  int _homeRefreshToken = 0;

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

  void _openSearchFiltersFromNav() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilter: _discoverFocusFilter ?? PropertyFilter(city: 'Pune'),
        onApply: (newFilter) => _openDiscoverWithFilter(newFilter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePageScreen(
        key: ValueKey('home_page_$_homeRefreshToken'),
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
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            ClipPath(
              clipper: _DropNotchDockClipper(),
              child: Container(
                height: 90,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFFFF), Color(0xFFF6F8FC)],
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildNavItem(0, Icons.home_filled, 'Home'),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          1,
                          Icons.search_rounded,
                          'Search',
                          onTap: _openSearchFiltersFromNav,
                          selectedOverride: _currentIndex == 1,
                        ),
                      ),
                      const SizedBox(width: 84),
                      Expanded(
                        child: _buildNavItem(
                          2,
                          Icons.grid_view_rounded,
                          'Listings',
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          3,
                          Icons.person_outline_rounded,
                          'You',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(top: 6, child: _buildAddPropertyNavButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPropertyNavButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: _openAddProperty,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: 60,
          height: 60,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.16),
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                const Icon(Icons.add_rounded, color: AppColors.white, size: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAddProperty() async {
    final isBuilder =
        AuthService.userType == 'Builder' ||
        AuthService.userType == 'Developer';
    final result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (_) => isBuilder
            ? const AddBuilderPropertyScreen()
            : const AddPropertyScreen(),
      ),
    );
    if (result == true) {
      setState(() => _homeRefreshToken++);
    }
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool? selectedOverride,
  }) {
    final isSelected = selectedOverride ?? (_currentIndex == index);
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        offset: Offset(0, isSelected ? -0.045 : 0),
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                scale: isSelected ? 1 : 0.94,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  width: 40,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: Icon(
                      icon,
                      key: ValueKey('${label}_$isSelected'),
                      size: isSelected ? 19 : 18,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.mediumGray,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  height: 1,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.darkGray,
                  letterSpacing: -0.1,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                opacity: isSelected ? 1 : 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 18 : 10,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropNotchDockClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const corner = 28.0;
    const notchHalfWidth = 42.0;
    const notchDepth = 31.0;
    final centerX = size.width / 2;

    final path = Path()
      ..moveTo(corner, 0)
      ..quadraticBezierTo(0, 0, 0, corner)
      ..lineTo(0, size.height - corner)
      ..quadraticBezierTo(0, size.height, corner, size.height)
      ..lineTo(size.width - corner, size.height)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width,
        size.height - corner,
      )
      ..lineTo(size.width, corner)
      ..quadraticBezierTo(size.width, 0, size.width - corner, 0)
      ..lineTo(centerX + notchHalfWidth, 0)
      ..cubicTo(
        centerX + 30,
        0,
        centerX + 22,
        notchDepth * 0.52,
        centerX + 14,
        notchDepth,
      )
      ..quadraticBezierTo(centerX, notchDepth + 4, centerX - 14, notchDepth)
      ..cubicTo(
        centerX - 22,
        notchDepth * 0.52,
        centerX - 30,
        0,
        centerX - notchHalfWidth,
        0,
      )
      ..lineTo(corner, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
