import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../models/property_model.dart';
import '../services/auth_service.dart';
import '../services/property_service.dart';
import 'properties/add_builder_property_screen.dart';
import 'properties/add_property_screen.dart';
import 'properties/filter_bottom_sheet.dart';
import 'subscription_screen.dart';

class HomePageScreen extends StatefulWidget {
  final void Function(int propertyId, UserTypeFilter? userTypeHint)?
  onOpenDiscoverProperty;
  final void Function(PropertyFilter filter)? onOpenDiscoverWithFilter;
  final void Function(int sortIndex)? onOpenDiscoverWithSort;

  const HomePageScreen({
    super.key,
    this.onOpenDiscoverProperty,
    this.onOpenDiscoverWithFilter,
    this.onOpenDiscoverWithSort,
  });

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

enum _HomeSortOption {
  newest('Newest First', 0),
  priceLow('Price Low-High', 2),
  priceHigh('Price High-Low', 3),
  area('Largest Area', 4);

  const _HomeSortOption(this.label, this.feedIndex);
  final String label;
  final int feedIndex;
}

class _HomePageScreenState extends State<HomePageScreen> {
  static const String _cityPrefKey = 'home_selected_city';
  static const String _areaPrefKey = 'home_selected_area';
  static const String _builderPlanPromptSeenKey = 'builder_plan_prompt_seen';

  bool _isLoading = true;
  bool _isAreaLoading = false;
  bool _isCityLoading = false;
  List<PropertyModel> _properties = [];
  List<String> _areaOptions = [];
  List<String> _cityOptions = [];
  final _HomeSortOption _sortOption = _HomeSortOption.newest;
  String _selectedCity = 'Pune';
  String? _selectedArea;
  TextEditingController? _cityCtrl;
  TextEditingController? _areaCtrl;

  void _syncControllers() {
    bool changed = false;
    if (_cityCtrl != null) {
      final cityText = _cityCtrl!.text.trim();
      if (cityText.isNotEmpty && cityText != _selectedCity) {
        _selectedCity = cityText;
        changed = true;
      }
    }
    if (_areaCtrl != null) {
      final newArea = _areaCtrl!.text.trim().isEmpty ? null : _areaCtrl!.text.trim();
      if (newArea != _selectedArea) {
        _selectedArea = newArea;
        changed = true;
      }
    }
    if (changed) {
      _saveLocationFilters();
    }
  }

  @override
  void initState() {
    super.initState();
    _bootstrapLocationFilters();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _bootstrapLocationFilters() async {
    await _loadSavedLocationFilters();
    await _loadCityOptions();
    await _loadAreaOptions();
    await _loadProperties();
  }

  Future<void> _loadCityOptions() async {
    setState(() => _isCityLoading = true);
    try {
      final cities = await PropertyService.getCities();
      if (!mounted) return;
      final unique = cities.toSet().toList()..sort();
      if (!unique.contains('Pune')) {
        unique.insert(0, 'Pune');
      }
      if (_selectedCity.isNotEmpty && unique.contains(_selectedCity)) {
        unique.remove(_selectedCity);
        unique.insert(0, _selectedCity);
      }
      setState(() {
        _cityOptions = unique;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cityOptions = ['Pune']);
    } finally {
      if (mounted) setState(() => _isCityLoading = false);
    }
  }

  Future<void> _loadSavedLocationFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString(_cityPrefKey);
    final area = prefs.getString(_areaPrefKey);
    if (!mounted) return;
    setState(() {
      _selectedCity = (city != null && city.trim().isNotEmpty) ? city : 'Pune';
      _selectedArea = (area != null && area.trim().isNotEmpty) ? area : null;
    });
  }

  Future<void> _saveLocationFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityPrefKey, _selectedCity);
    if (_selectedArea != null && _selectedArea!.trim().isNotEmpty) {
      await prefs.setString(_areaPrefKey, _selectedArea!);
    } else {
      await prefs.remove(_areaPrefKey);
    }
  }

  Future<void> _loadAreaOptions() async {
    setState(() => _isAreaLoading = true);
    try {
      final areas = await PropertyService.getCityAreas();
      if (!mounted) return;
      final unique = areas.toSet().toList()..sort();
      unique.insert(0, 'All');
      if (_selectedArea != null && unique.contains(_selectedArea) && _selectedArea != 'All') {
        unique.remove(_selectedArea);
        unique.insert(1, _selectedArea!);
      }
      setState(() {
        _areaOptions = unique;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _areaOptions = ['All']);
    } finally {
      if (mounted) setState(() => _isAreaLoading = false);
    }
  }

  Future<void> _onCityChanged(String? city) async {
    if (city == null || city.trim().isEmpty) return;
    final trimmedCity = city.trim();
    if (trimmedCity == _selectedCity) return;
    setState(() {
      _selectedCity = trimmedCity;
      _selectedArea = null;
      if (_areaCtrl != null) {
        _areaCtrl!.text = '';
      }
    });
    await _saveLocationFilters();
    await _loadAreaOptions();
    await _loadProperties();
  }

  Future<void> _onAreaChanged(String? area) async {
    final newArea = (area == null || area.trim().isEmpty) ? null : area.trim();
    if (_selectedArea == newArea) return;
    setState(() => _selectedArea = newArea);
    await _saveLocationFilters();
    await _loadProperties();
  }

  Future<void> _loadProperties() async {
    _syncControllers();
    setState(() => _isLoading = true);
    try {
      final filter = PropertyFilter(city: _selectedCity);
      if (_selectedArea != null && _selectedArea!.trim().isNotEmpty && _selectedArea!.trim().toLowerCase() != 'all') {
        filter.area = _selectedArea!.trim();
      }
      final items = await PropertyService.getProperties(filter: filter);
      if (mounted) {
        setState(() => _properties = items);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load properties: $e'),
          backgroundColor: AppColors.iosDestructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openAddProperty() async {
    final isBuilder =
        AuthService.userType == 'Builder' ||
        AuthService.userType == 'Developer';
    if (isBuilder) {
      final shouldContinue = await _handleFirstBuilderPostClick();
      if (!shouldContinue || !mounted) return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isBuilder
            ? const AddBuilderPropertyScreen()
            : const AddPropertyScreen(),
      ),
    );
    if (result == true) {
      _loadProperties();
    }
  }

  Future<bool> _handleFirstBuilderPostClick() async {
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

  void _openFilterBottomSheet() {
    _syncControllers();
    final filter = PropertyFilter(city: _selectedCity);
    if (_selectedArea != null && _selectedArea!.trim().isNotEmpty && _selectedArea!.trim().toLowerCase() != 'all') {
      filter.area = _selectedArea!.trim();
    }
    _openPresetFilter(filter);
  }

  void _openPresetFilter(PropertyFilter filter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilter: filter,
        onApply: (newFilter) {
          widget.onOpenDiscoverWithFilter?.call(newFilter);
        },
      ),
    );
  }

  void _redirectWithPredefinedFilter({
    PropertyCategory? category,
    ListingType? listingType,
    UserTypeFilter? userTypeFilter,
  }) {
    _syncControllers();
    final filter = PropertyFilter(city: _selectedCity)
      ..category = category
      ..listingType = listingType
      ..userTypeFilter = userTypeFilter;
    if (_selectedArea != null && _selectedArea!.trim().isNotEmpty && _selectedArea!.trim().toLowerCase() != 'all') {
      filter.area = _selectedArea!.trim();
    }
    // Go directly to discover with the preset filter — no intermediate sheet
    widget.onOpenDiscoverWithFilter?.call(filter);
  }

  List<PropertyModel> get _visibleProperties {
    final filtered = List<PropertyModel>.from(_properties);

    switch (_sortOption) {
      case _HomeSortOption.newest:
        filtered.sort(
          (a, b) => (b.refreshedAt ?? b.postedAt ?? DateTime(0)).compareTo(
            a.refreshedAt ?? a.postedAt ?? DateTime(0),
          ),
        );
      case _HomeSortOption.priceLow:
        filtered.sort(
          (a, b) => (a.price ?? double.infinity).compareTo(
            b.price ?? double.infinity,
          ),
        );
      case _HomeSortOption.priceHigh:
        filtered.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
      case _HomeSortOption.area:
        filtered.sort((a, b) {
          final aArea = a.carpetArea ?? a.builtUpArea ?? a.areaValue ?? 0;
          final bArea = b.carpetArea ?? b.builtUpArea ?? b.areaValue ?? 0;
          return bArea.compareTo(aArea);
        });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleProperties;

    return Scaffold(
      backgroundColor: AppColors.iosGroupedBg,
      body: RefreshIndicator(
        onRefresh: _loadProperties,
        color: AppColors.accent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeroSection()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: _buildQuickActionRow(),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.10),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/appicons/TreadMarkLogo.png',
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'OMD Broker Associates',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.primaryLight,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  // City Search
                                  Row(
                                    children: [
                                      Text(
                                        'CITY',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.mediumGray,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Autocomplete<String>(
                                          key: ValueKey(_selectedCity),
                                          initialValue: TextEditingValue(
                                            text: _selectedCity,
                                          ),
                                          optionsBuilder: (
                                            TextEditingValue textEditingValue,
                                          ) {
                                            if (textEditingValue.text.isEmpty) {
                                              return _cityOptions;
                                            }
                                            return _cityOptions.where((
                                              String option,
                                            ) {
                                              return option
                                                  .toLowerCase()
                                                  .contains(
                                                    textEditingValue.text
                                                        .toLowerCase(),
                                                  );
                                            });
                                          },
                                          onSelected: (String selection) {
                                            _onCityChanged(selection);
                                            FocusManager
                                                .instance
                                                .primaryFocus
                                                ?.unfocus();
                                          },
                                          fieldViewBuilder: (
                                            context,
                                            controller,
                                            focusNode,
                                            onFieldSubmitted,
                                          ) {
                                            _cityCtrl = controller;
                                            return TextField(
                                              controller: controller,
                                              focusNode: focusNode,
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.charcoal,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: _isCityLoading ? 'Loading...' : 'Search city',
                                                hintStyle: GoogleFonts.inter(
                                                  color: AppColors.mediumGray,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 11,
                                                ),
                                              ),
                                              onSubmitted: (val) {
                                                final submitted = val.trim();
                                                if (submitted.isNotEmpty) {
                                                  _onCityChanged(submitted);
                                                }
                                                onFieldSubmitted();
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    height: 1,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    color: AppColors.lightGray.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  // Area Dropdown
                                  Row(
                                    children: [
                                      Text(
                                        'AREA',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.mediumGray,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Autocomplete<String>(
                                          key: ValueKey(_selectedArea ?? ''),
                                          initialValue: TextEditingValue(text: _selectedArea ?? ''),
                                          optionsBuilder: (TextEditingValue textEditingValue) {
                                            if (textEditingValue.text.isEmpty) {
                                              return _areaOptions;
                                            }
                                            return _areaOptions.where((String option) {
                                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                            });
                                          },
                                          onSelected: (String selection) {
                                            _onAreaChanged(selection);
                                            FocusManager.instance.primaryFocus?.unfocus();
                                          },
                                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                            _areaCtrl = controller;
                                            return TextField(
                                              controller: controller,
                                              focusNode: focusNode,
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.charcoal,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: _isAreaLoading ? 'Loading...' : 'Search locality',
                                                hintStyle: GoogleFonts.inter(
                                                  color: AppColors.mediumGray,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                                              ),
                                              onChanged: (val) {
                                                if (val.trim().isEmpty) {
                                                  _onAreaChanged(null);
                                                }
                                              },
                                              onSubmitted: (val) {
                                                if (val.trim().isNotEmpty) {
                                                  _onAreaChanged(val);
                                                }
                                                onFieldSubmitted();
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionRow() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActionHeader(),
          const SizedBox(height: 18),
          _buildPresetSelector(),
        ],
      ),
    );
  }

  Widget _buildQuickActionHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'One More Deal connects Brokers to Brokers and Builders with clarity.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 14.0;
            final cardWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildActionCard(
                    title: 'Resale',
                    subtitle: 'Residential',
                    icon: Icons.villa_rounded,
                    iconColor: AppColors.primaryLight,
                    onTap: () => _redirectWithPredefinedFilter(
                      category: PropertyCategory.residential,
                      listingType: ListingType.resale,
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildActionCard(
                    title: 'Rent',
                    subtitle: 'Residential',
                    icon: Icons.apartment_rounded,
                    iconColor: AppColors.info,
                    onTap: () => _redirectWithPredefinedFilter(
                      category: PropertyCategory.residential,
                      listingType: ListingType.rent,
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildActionCard(
                    title: 'Resale',
                    subtitle: 'Commercial',
                    icon: Icons.store_mall_directory_rounded,
                    iconColor: AppColors.accent,
                    onTap: () => _redirectWithPredefinedFilter(
                      category: PropertyCategory.commercial,
                      listingType: ListingType.resale,
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildActionCard(
                    title: 'Rent',
                    subtitle: 'Commercial',
                    icon: Icons.business_rounded,
                    iconColor: AppColors.warning,
                    onTap: () => _redirectWithPredefinedFilter(
                      category: PropertyCategory.commercial,
                      listingType: ListingType.rent,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Builder Projects',
          subtitle: 'New properties',
          icon: Icons.business_center_rounded,
          iconColor: AppColors.success,
          isFullWidth: true,
          onTap: () {
            final filter = PropertyFilter(city: _selectedCity)
              ..userTypeFilter = UserTypeFilter.builder;
            if (_selectedArea != null && _selectedArea!.trim().isNotEmpty) {
              filter.area = _selectedArea!.trim();
            }
            widget.onOpenDiscoverWithFilter?.call(filter);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    bool isFullWidth = false,
  }) {
    final iColor = iconColor ?? AppColors.primary;
    final subtitleColor = (subtitle.toLowerCase() == 'residential' || subtitle.toLowerCase() == 'commercial')
        ? Colors.black
        : AppColors.iosSecondaryLabel;

    final baseStyle = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: subtitleColor,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isFullWidth ? 22 : 18, 
          vertical: isFullWidth ? 24 : 20,
        ),
        decoration: BoxDecoration(
          color: iColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: iColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: isFullWidth
            ? Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(subtitle, style: baseStyle),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.mediumGray,
                    size: 18,
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iColor.withValues(alpha: 0.12),

                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(subtitle, style: baseStyle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
