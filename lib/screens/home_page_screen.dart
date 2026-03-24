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
  final void Function(int propertyId, UserTypeFilter? userTypeHint)? onOpenDiscoverProperty;
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
      final items = await PropertyService.getProperties(filter: PropertyFilter(city: 'Pune'));
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilter: PropertyFilter(city: 'Pune'),
        onApply: (newFilter) {
          widget.onOpenDiscoverWithFilter?.call(newFilter);
        },
      ),
    );
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

  List<PropertyModel> get _featuredProperties =>
      _visibleProperties.take(6).toList();


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

  String _cardLocation(PropertyModel property) {
    final parts = <String>[
      if ((property.subarea ?? '').trim().isNotEmpty) property.subarea!.trim(),
      property.area,
      property.city,
    ];
    return parts.join(', ');
  }

  Future<void> _openInDiscover(PropertyModel property) async {
    final propertyId = property.id;
    if (propertyId == null) return;
    final isBuilder =
        property.listingType == ListingType.newLaunch ||
        property.category == PropertyCategory.newProperty;
    widget.onOpenDiscoverProperty?.call(
      propertyId,
      isBuilder ? UserTypeFilter.builder : null,
    );
  }

  void _updateQuickFilter({
    UserTypeFilter? userTypeFilter,
    PropertyCategory? category,
    ListingType? listingType,
  }) {
    final next = PropertyFilter(city: 'Pune');
    if (userTypeFilter != null) next.userTypeFilter = userTypeFilter;
    if (category != null) next.category = category;
    if (listingType != null) next.listingType = listingType;
    widget.onOpenDiscoverWithFilter?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleProperties;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: RefreshIndicator(
        onRefresh: _loadProperties,
        color: AppColors.accent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeroSection(visible.length)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: _buildQuickActionRow(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildSectionHeader(
                  title: 'Fresh Matches',
                  subtitle: 'Sorted, searchable, and ready to close.',
                ),
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
              )
            else ...[
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 254,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, index) =>
                        _buildFeatureCard(_featuredProperties[index]),
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemCount: _featuredProperties.length,
                  ),
                ),
              ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(int resultCount) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF081126), Color(0xFF10224A), Color(0xFF1C3F86)],
        ),
      ),
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
                color: AppColors.accent.withValues(alpha: 0.12),
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
                color: AppColors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //     horizontal: 10,
                            //     vertical: 6,
                            //   ),
                            //   decoration: BoxDecoration(
                            //     color: AppColors.white.withValues(alpha: 0.08),
                            //     borderRadius: BorderRadius.circular(999),
                            //     border: Border.all(
                            //       color: AppColors.white.withValues(
                            //         alpha: 0.08,
                            //       ),
                            //     ),
                            //   ),
                            //   child: Text(
                            //     'Premium Home',
                            //     style: GoogleFonts.inter(
                            //       color: AppColors.accentLight,
                            //       fontSize: 11,
                            //       fontWeight: FontWeight.w700,
                            //       letterSpacing: 0.4,
                            //     ),
                            //   ),
                            // ),
                            // const SizedBox(height: 12),
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
                            const SizedBox(height: 10),
                            // Text(
                            //   'Search, filter, sort, and post from one polished command center.',
                            //   style: GoogleFonts.inter(
                            //     color: AppColors.white.withValues(alpha: 0.74),
                            //     fontSize: 13,
                            //     height: 1.5,
                            //     fontWeight: FontWeight.w500,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _openAddProperty,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.28),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_business_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Post',
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(18),
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
                        const SizedBox(height: 14),
                        Container(
                          height: 1,
                          color: AppColors.lightGray.withValues(alpha: 0.9),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildHeroMetricTile(
                                label: 'Market',
                                value: 'Pune',
                                icon: Icons.location_on_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildHeroMetricTile(
                                label: 'Filters',
                                value: 'Any',
                                icon: Icons.filter_alt_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildHeroMetricTile(
                                label: 'Matches',
                                value: '$resultCount',
                                icon: Icons.home_work_outlined,
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
          Row(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
          ),
          const SizedBox(height: 6),
          Text(
            'Core tools for finding the right listing without leaving Home.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.darkGray,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildActionCard(
                  title: 'Filters',
                  subtitle: 'Refine listings',
                  icon: Icons.tune_rounded,
                  accent: const Color(0xFF0EA5E9),
                  onTap: _openFilterBottomSheet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  key: _sortKey,
                  onTap: _showSortMenu,
                  child: _buildActionCard(
                    title: 'Sort',
                    subtitle: _sortOption.label,
                    icon: Icons.swap_vert_rounded,
                    accent: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickFilterChip(
                  label: 'Builder',
                  selected: false,
                  onTap: () => _updateQuickFilter(
                    userTypeFilter: UserTypeFilter.builder,
                  ),
                ),
                _buildQuickFilterChip(
                  label: 'Broker',
                  selected: false,
                  onTap: () =>
                      _updateQuickFilter(userTypeFilter: UserTypeFilter.broker),
                ),
                _buildQuickFilterChip(
                  label: 'Residential',
                  selected: false,
                  onTap: () => _updateQuickFilter(
                    category: PropertyCategory.residential,
                  ),
                ),
                _buildQuickFilterChip(
                  label: 'Commercial',
                  selected: false,
                  onTap: () =>
                      _updateQuickFilter(category: PropertyCategory.commercial),
                ),
                _buildQuickFilterChip(
                  label: 'Rent',
                  selected: false,
                  onTap: () =>
                      _updateQuickFilter(listingType: ListingType.rent),
                ),
                _buildQuickFilterChip(
                  label: 'Resale',
                  selected: false,
                  onTap: () =>
                      _updateQuickFilter(listingType: ListingType.resale),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withValues(alpha: 0.12), AppColors.white],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  )
                : null,
            color: selected ? null : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.lightGray,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.white : AppColors.charcoal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.darkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
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

  Widget _buildFeatureCard(PropertyModel property) {
    final isBuilder =
        property.listingType == ListingType.newLaunch ||
        property.category == PropertyCategory.newProperty;
    final displayTitle = property.societyName?.trim().isNotEmpty == true
        ? property.societyName!.trim()
        : isBuilder
        ? 'Untitled Project'
        : property.flatType ?? 'Property';
    final accent = isBuilder ? AppColors.accent : AppColors.iosSystemBlue;
    return GestureDetector(
      onTap: () => _openInDiscover(property),
      child: Container(
        width: 308,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isBuilder
                ? const [Color(0xFF1B1530), Color(0xFF3F2A17)]
                : const [Color(0xFF0E1C3D), Color(0xFF1B3D7A)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -18,
              right: -8,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isBuilder
                              ? 'Builder Project'
                              : property.listingType.value,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('d MMM').format(
                          property.refreshedAt ??
                              property.postedAt ??
                              DateTime.now(),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (property.price != null) ...[
                    Text(
                      _formatPrice(property.price!),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.accentLight,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _cardLocation(property),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white.withValues(alpha: 0.74),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((property.flatType ?? '').isNotEmpty)
                        _buildMiniStat(
                          property.flatType!,
                          Icons.king_bed_outlined,
                          dark: true,
                        ),
                      if (property.carpetArea != null)
                        _buildMiniStat(
                          '${property.carpetArea!.toStringAsFixed(0)} sqft',
                          Icons.square_foot_rounded,
                          dark: true,
                        ),
                      if (property.totalBuildings != null)
                        _buildMiniStat(
                          '${property.totalBuildings} towers',
                          Icons.apartment_rounded,
                          dark: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, IconData icon, {bool dark = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: dark ? AppColors.white.withValues(alpha: 0.12) : AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark
              ? AppColors.white.withValues(alpha: 0.14)
              : AppColors.iosSeparator.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: dark ? AppColors.accentLight : AppColors.iosSecondaryLabel,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: dark ? AppColors.white : AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetricTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryLight),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }
}
