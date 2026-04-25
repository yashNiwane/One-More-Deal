import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';
import '../models/property_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/app_update_service.dart';
import 'landing_screen.dart';

import 'home_page_screen.dart';
import 'properties/add_builder_property_screen.dart';
import 'properties/add_property_screen.dart';
import 'properties/my_properties_screen.dart';
import 'properties/properties_feed_screen.dart';
import 'profile_screen.dart';
import 'contact_us_screen.dart';
import 'properties/filter_bottom_sheet.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const String _builderPlanPromptSeenKey = 'builder_plan_prompt_seen';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkAndRunImmediateUpdate();
    });
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
      const ContactUsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.iosGroupedBg,
      body: pages[_currentIndex],
      extendBody: true,
      bottomNavigationBar: _buildFrostedBottomNav(),
    );
  }

  Widget _buildFrostedBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_filled, 'Home'),
              _buildNavItem(2, Icons.list_alt_rounded, 'My List'),
              _buildAddPropertyNavAction(),
              _buildNavItem(3, Icons.person_outline_rounded, 'Profile'),
              _buildNavItem(4, Icons.support_agent_rounded, 'Contact Us'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPropertyNavAction() {
    return GestureDetector(
      onTap: _openAddProperty,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryLight, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.white, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              'Add Property',
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddProperty() async {
    final isBuilder =
        AuthService.userType == 'Builder' ||
        AuthService.userType == 'Developer';

    if (isBuilder) {
      final shouldContinue = await _handleFirstBuilderPostClick();
      if (!shouldContinue || !mounted) return;
    }

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

  Future<bool> _handleFirstBuilderPostClick() async {
    final paymentsEnabled = await DatabaseService.instance.isFeatureEnabled(
      'builder_payments_enabled',
      fallback: false,
    );
    if (!paymentsEnabled) return true;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_builderPlanPromptSeenKey) ?? false;
    if (seen) return true;

    if (!mounted) return false;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Builder Payment Plans',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose a plan to start posting builder properties.',
                style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 12),
            Text('1 Month: ₹3000',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('3 Months: ₹6000',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'later'),
            child: Text('Continue',
                style: GoogleFonts.inter(color: AppColors.iosSystemBlue)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'pay'),
            child: Text('Pay Now', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    await prefs.setBool(_builderPlanPromptSeenKey, true);
    if (action == 'pay') {
      if (!mounted) return false;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
      return false;
    }
    return true;
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool? selectedOverride,
  }) {
    // If we are currently on the Discover page (index 1), visually highlight the Home tab (0)
    final isSelected = selectedOverride ?? (_currentIndex == index || (index == 0 && _currentIndex == 1));
    return GestureDetector(
      onTap: onTap ?? () {
        setState(() {
          if (index == 0 && _currentIndex == 1) {
            _currentIndex = 0;
          } else {
            _currentIndex = index;
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? AppColors.primary : AppColors.mediumGray,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
