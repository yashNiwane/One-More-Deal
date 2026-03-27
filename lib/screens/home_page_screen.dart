import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';
import '../models/property_model.dart';
import '../services/auth_service.dart';
import '../services/property_service.dart';
import 'properties/add_builder_property_screen.dart';
import 'properties/add_property_screen.dart';
import 'properties/filter_bottom_sheet.dart';

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
  final TextEditingController _searchCtrl = TextEditingController();
  final GlobalKey _sortKey = GlobalKey();

  bool _isLoading = true;
  List<PropertyModel> _properties = [];
  _HomeSortOption _sortOption = _HomeSortOption.newest;
  String _searchQuery = '';
  PropertyCategory? _selectedPresetCategory;
  UserTypeFilter? _selectedPresetUserType;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final items = await PropertyService.getProperties(
        filter: PropertyFilter(city: 'Pune'),
      );
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

  void _openFilterBottomSheet() {
    _openPresetFilter(PropertyFilter(city: 'Pune'));
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

  void _openPredefinedFilter({
    required PropertyCategory? category,
    required ListingType? listingType,
    UserTypeFilter? userTypeFilter,
  }) {
    final filter = PropertyFilter(city: 'Pune')
      ..category = category
      ..listingType = listingType
      ..userTypeFilter = userTypeFilter;
    _openPresetFilter(filter);
  }

  void _selectPrimaryPreset({
    PropertyCategory? category,
    UserTypeFilter? userTypeFilter,
  }) {
    setState(() {
      _selectedPresetCategory = category;
      _selectedPresetUserType = userTypeFilter;
      if (userTypeFilter == UserTypeFilter.builder) {
        _selectedPresetCategory = null;
      } else {
        _selectedPresetUserType = null;
      }
    });

    if (userTypeFilter == UserTypeFilter.builder) {
      _openPredefinedFilter(
        category: null,
        listingType: null,
        userTypeFilter: UserTypeFilter.builder,
      );
    }
  }

  void _showSortMenu() {
    final RenderBox box =
        _sortKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    showMenu<_HomeSortOption>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height + 8,
        offset.dx + box.size.width,
        0,
      ),
      color: AppColors.iosCardBg,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: _HomeSortOption.values.map((option) {
        final selected = option == _sortOption;
        return PopupMenuItem<_HomeSortOption>(
          value: option,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.iosSystemBlue
                        : AppColors.charcoal,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: AppColors.iosSystemBlue,
                  size: 18,
                ),
            ],
          ),
        );
      }).toList(),
    ).then((selected) {
      if (selected != null) {
        widget.onOpenDiscoverWithSort?.call(selected.feedIndex);
        setState(() => _sortOption = selected);
      }
    });
  }

  List<PropertyModel> get _visibleProperties {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _properties.where((property) {
      if (query.isEmpty) return true;
      final haystack = [
        property.societyName,
        property.area,
        property.subarea,
        property.city,
        property.flatType,
        property.posterCompany,
        property.posterName,
        property.category.value,
        property.listingType.value,
        property.furnishingStatus,
        property.availability,
        property.parking,
        property.price?.toString(),
        property.price != null ? _formatPrice(property.price!) : null,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

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

  String _formatPrice(double price) {
    if (price >= 10000000) {
      final crore = price / 10000000;
      return 'Rs ${crore.toStringAsFixed(crore % 1 == 0 ? 0 : 2)} Cr';
    }
    if (price >= 100000) {
      final lakh = price / 100000;
      return 'Rs ${lakh.toStringAsFixed(lakh % 1 == 0 ? 0 : 2)} Lac';
    }
    return 'Rs ${NumberFormat.decimalPattern('en_IN').format(price.toInt())}';
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
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else if (visible.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildEmptyState(),
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
                  Text(
                    'Find one more\ndeal with clarity.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 26),
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
                                Icons.search_rounded,
                                color: AppColors.primaryLight,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (value) =>
                                    setState(() => _searchQuery = value),
                                textInputAction: TextInputAction.search,
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    final filter = PropertyFilter(city: 'Pune');
                                    filter.searchQuery = value.trim();
                                    widget.onOpenDiscoverWithFilter?.call(
                                      filter,
                                    );
                                  }
                                },
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.charcoal,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText:
                                      'Search by locality, society, city, company',
                                  hintStyle: GoogleFonts.inter(
                                    color: AppColors.mediumGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  suffixIcon: _searchQuery.isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            color: AppColors.iosSecondaryLabel,
                                          ),
                                        ),
                                ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActionHeader(),
          const SizedBox(height: 8),
          Text(
            'Core tools for finding the right listing without leaving Home.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.darkGray,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _buildQuickActionButtons(),
          const SizedBox(height: 16),
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
            'Explore faster',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _sortOption.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildCTAButton(
            label: 'Filters',
            subtitle: 'Refine listings',
            icon: Icons.tune_rounded,
            accent: AppColors.primaryLight,
            onTap: _openFilterBottomSheet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCTAButton(
            key: _sortKey,
            label: 'Sort',
            subtitle: _sortOption.label,
            icon: Icons.swap_vert_rounded,
            accent: AppColors.accent,
            onTap: _showSortMenu,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start with a property type.',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _buildPresetChip(
                label: 'Residential',
                accent: AppColors.primaryLight,
                selected:
                    _selectedPresetCategory == PropertyCategory.residential,
                onTap: () => _selectPrimaryPreset(
                  category: PropertyCategory.residential,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildPresetChip(
                label: 'Commercial',
                accent: AppColors.accent,
                selected:
                    _selectedPresetCategory == PropertyCategory.commercial,
                onTap: () =>
                    _selectPrimaryPreset(category: PropertyCategory.commercial),
              ),
            ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: _selectedPresetCategory == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey(_selectedPresetCategory),
                  padding: const EdgeInsets.only(top: 22),
                  child: _buildListingTypeSelector(),
                ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: _buildPresetChip(
            label: 'Builder',
            accent: AppColors.primary,
            selected: _selectedPresetUserType == UserTypeFilter.builder,
            onTap: () =>
                _selectPrimaryPreset(userTypeFilter: UserTypeFilter.builder),
          ),
        ),
      ],
    );
  }

  Widget _buildListingTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'choose a listing type.',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _buildPresetChip(
                label: 'Rent',
                accent: AppColors.info,
                selected: false,
                onTap: () => _openPredefinedFilter(
                  category: _selectedPresetCategory,
                  listingType: ListingType.rent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildPresetChip(
                label: 'Resale',
                accent: AppColors.accent,
                selected: false,
                onTap: () => _openPredefinedFilter(
                  category: _selectedPresetCategory,
                  listingType: ListingType.resale,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetChip({
    required String label,
    required Color accent,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.14)
              : accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.38)
                : accent.withValues(alpha: 0.18),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? accent : AppColors.charcoal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTAButton({
    Key? key,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        height: 86,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withValues(alpha: 0.14), AppColors.white],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.iosSecondaryLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.iosCardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No properties matched right now',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a broader search, remove a few filters, or post a fresh listing from Home.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.iosSecondaryLabel,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _openFilterBottomSheet,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Adjust Filters'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _openAddProperty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Post Property'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
