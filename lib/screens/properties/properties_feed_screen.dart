import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/property_model.dart';
import '../../models/enquiry_model.dart';
import '../../services/property_service.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'filter_bottom_sheet.dart';

class PropertiesFeedScreen extends StatefulWidget {
  const PropertiesFeedScreen({super.key});

  @override
  State<PropertiesFeedScreen> createState() => _PropertiesFeedScreenState();
}

enum _SortOption {
  newest('Newest First'),
  oldest('Oldest First'),
  priceLow('Price: Low to High'),
  priceHigh('Price: High to Low'),
  area('Area: Largest First');

  const _SortOption(this.label);
  final String label;
}

class _PropertiesFeedScreenState extends State<PropertiesFeedScreen> {
  bool _isLoading = false;
  List<PropertyModel> _properties = [];
  PropertyFilter _currentFilter = PropertyFilter();
  _SortOption _sortOption = _SortOption.priceLow;
  final GlobalKey _sortIconKey = GlobalKey();

  List<PropertyModel> get _sorted {
    final list = List<PropertyModel>.from(_properties);
    switch (_sortOption) {
      case _SortOption.newest:
        list.sort((a, b) => (b.refreshedAt ?? b.postedAt ?? DateTime(0))
            .compareTo(a.refreshedAt ?? a.postedAt ?? DateTime(0)));
      case _SortOption.oldest:
        list.sort((a, b) => (a.refreshedAt ?? a.postedAt ?? DateTime(0))
            .compareTo(b.refreshedAt ?? b.postedAt ?? DateTime(0)));
      case _SortOption.priceLow:
        list.sort((a, b) => (a.price ?? double.infinity)
            .compareTo(b.price ?? double.infinity));
      case _SortOption.priceHigh:
        list.sort((a, b) => (b.price ?? 0)
            .compareTo(a.price ?? 0));
      case _SortOption.area:
        list.sort((a, b) {
          final aArea = a.carpetArea ?? a.builtUpArea ?? a.areaValue ?? 0;
          final bArea = b.carpetArea ?? b.builtUpArea ?? b.areaValue ?? 0;
          return bArea.compareTo(aArea);
        });
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadProperties();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openFilterBottomSheet();
    });
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final items = await PropertyService.getProperties(filter: _currentFilter);
      if (mounted) setState(() => _properties = items);
    } catch (e) {
      debugPrint('[FEED] Error loading properties: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilter: _currentFilter,
        onApply: (newFilter) {
          setState(() => _currentFilter = newFilter);
          _loadProperties();
        },
      ),
    );
  }

  void _showSortMenu() {
    final RenderBox box = _sortIconKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    showMenu<_SortOption>(
      context: context,
      color: AppColors.iosCardBg,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height + 4,
        offset.dx + box.size.width,
        0,
      ),
      items: _SortOption.values.map((opt) {
        final isSelected = opt == _sortOption;
        return PopupMenuItem<_SortOption>(
          value: opt,
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  opt.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.iosSystemBlue : AppColors.charcoal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, size: 18, color: AppColors.iosSystemBlue),
            ],
          ),
        );
      }).toList(),
    ).then((selected) {
      if (selected != null) setState(() => _sortOption = selected);
    });
  }

  // Accent per listing type
  Color _accentForType(PropertyModel p) {
    switch (p.listingType) {
      case ListingType.rent:   return const Color(0xFF10B981); // Emerald Green
      case ListingType.plot:   return const Color(0xFFF59E0B); // Golden Amber
      case ListingType.resale: return const Color(0xFF3B82F6); // Bright Ocean Blue
      default:                 return const Color(0xFF8B5CF6); // Vibrant Purple
    }
  }

  Widget _buildPropertyCard(PropertyModel p) {
    final isBuilder = p.category == PropertyCategory.newProperty;
    final accentColor = _accentForType(p);
    
    final areaStr = p.listingType == ListingType.plot 
        ? (p.areaValue != null ? '${p.areaValue} ${p.areaUnit}' : null)
        : (p.carpetArea != null ? '${p.carpetArea} SqFt' : (p.builtUpArea != null ? '${p.builtUpArea} SqFt' : null));

    // Collect metrics
    final metrics = <_MetricItem>[];
    if (p.flatType != null && p.flatType!.isNotEmpty) {
      metrics.add(_MetricItem(Icons.king_bed_outlined, p.flatType!, tint: Colors.indigo));
    }
    if (areaStr != null) {
      metrics.add(_MetricItem(Icons.square_foot_outlined, areaStr, tint: Colors.orange));
    }
    if (p.furnishingStatus != null && p.furnishingStatus!.isNotEmpty) {
      metrics.add(_MetricItem(Icons.chair_outlined, p.furnishingStatus!, tint: AppColors.iosSystemBlue));
    }
    if (p.parking != null && p.parking!.isNotEmpty && p.parking != 'Not available') {
      metrics.add(_MetricItem(Icons.directions_car_outlined, p.parking!, tint: Colors.purple));
    }
    if (p.floorCategory != null) {
      metrics.add(_MetricItem(Icons.layers_outlined, '${p.floorCategory!.value} Floor', tint: Colors.teal));
    }
    if (p.availability != null && p.availability!.isNotEmpty) {
      final isImmediate = p.availability!.toLowerCase() == 'immediate';
      metrics.add(_MetricItem(Icons.event_available_outlined, isImmediate ? 'Immediate' : 'Avail: ${p.availability}', tint: AppColors.iosSystemGreen));
    }

    // Mathematically balance the layout:
    // The left column (Price, Title, Location) spans about 3-4 lines vertically.
    // If we have more than 4 metrics, cramming them on the right makes the card unbalanced and too tall.
    // Logic: Put up to 3 metrics on the right, and distribute the rest in a full-width row at the bottom.
    final int rightMetricCount = metrics.length > 4 ? 3 : metrics.length;
    final rightMetrics = metrics.take(rightMetricCount).toList();
    final bottomMetrics = metrics.skip(rightMetricCount).toList();


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.iosCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Badges + Date ──
            Row(
              children: [
                if (isBuilder) ...[
                  _buildBadge('BUILDER', AppColors.charcoal, filled: true),
                  const SizedBox(width: 6),
                ],
                _buildBadge(p.listingType.value.toUpperCase(), accentColor, filled: true),
                const Spacer(),
                Text(
                  DateFormat("MMM d").format(p.refreshedAt ?? p.postedAt ?? DateTime.now()),
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.iosSecondaryLabel, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Main Body: 2-Column Layout ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Price, Title, Location
                Expanded(
                  flex: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.price != null)
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            Text(
                              '₹${NumberFormat.decimalPattern('en_IN').format(p.price)}',
                              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.charcoal, height: 1.1, letterSpacing: -0.5),
                            ),
                            if (p.listingType == ListingType.rent)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text('/ mo', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.iosSystemGreen)),
                              ),
                          ],
                        ),
                      if (p.deposit != null && p.listingType == ListingType.rent)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Deposit: ₹${NumberFormat.compact().format(p.deposit)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.iosSecondaryLabel)),
                        ),
                      if (p.price != null) const SizedBox(height: 6),

                      Text(
                        p.societyName ?? p.category.value,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.charcoal, letterSpacing: -0.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(Icons.location_on_rounded, size: 13, color: AppColors.iosSecondaryLabel),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              p.subarea != null && p.subarea!.isNotEmpty ? '${p.subarea}, ${p.area}' : '${p.area}, ${p.city}',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.iosSecondaryLabel, fontWeight: FontWeight.w400, height: 1.3),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Right side: Metrics Wrap
                if (rightMetrics.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 9,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (int i = 0; i < rightMetrics.length; i++) ...[
                          _buildMetricChip(rightMetrics[i].icon, rightMetrics[i].label, rightMetrics[i].tint),
                          if (i < rightMetrics.length - 1) const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // ── Overflow Metrics (Full Width Bottom) ──
            if (bottomMetrics.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: bottomMetrics.map((m) => _buildMetricChip(m.icon, m.label, m.tint)).toList(),
              ),
            ],

            const SizedBox(height: 10),

            // ── Separator ──
            Container(height: 0.5, color: AppColors.iosSeparator.withOpacity(0.4)),

            const SizedBox(height: 10),

            // ── Footer ──
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.iosGroupedBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    p.posterName != null && p.posterName!.isNotEmpty ? p.posterName![0].toUpperCase() : 'U',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.charcoal),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.posterName ?? 'Unknown',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.charcoal),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildActionBtn(Icons.phone_rounded, AppColors.iosSystemGreen, () async {
                  await PropertyService.logEnquiry(propertyId: p.id!, type: EnquiryType.call);
                  try {
                    final phone = await PropertyService.getPosterPhone(p.userId!);
                    if (phone != null) {
                      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
                      final uri = Uri.parse('tel:+91$cleanPhone');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    } else {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number not available')));
                    }
                  } catch (e) { debugPrint('Error: $e'); }
                }),
                const SizedBox(width: 8),
                _buildActionBtn(FontAwesomeIcons.whatsapp, const Color(0xFF25D366), () async {
                  await PropertyService.logEnquiry(propertyId: p.id!, type: EnquiryType.whatsApp);
                  try {
                    final phone = await PropertyService.getPosterPhone(p.userId!);
                    if (phone != null) {
                      String finalPhone = phone;
                      if (!finalPhone.startsWith('+')) finalPhone = '+91${finalPhone.replaceFirst(RegExp("^0+"), "")}';
                      final message = Uri.encodeComponent('Hi, I saw your property listing for ${p.flatType ?? p.category.value} in ${p.societyName ?? p.area} on One More Deal app. Please share details');
                      final uri = Uri.parse('whatsapp://send?phone=$finalPhone&text=$message');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        final webUri = Uri.parse('https://wa.me/${finalPhone.replaceAll('+', '')}?text=$message');
                        if (await canLaunchUrl(webUri)) await launchUrl(webUri, mode: LaunchMode.externalApplication);
                        else if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp not installed')));
                      }
                    } else {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number not available')));
                    }
                  } catch (e) { debugPrint('Error: $e'); }
                }, isFilled: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: filled ? AppColors.white : color, letterSpacing: 0.4),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String value, Color tintColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: tintColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tintColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tintColor.withValues(alpha: 0.9)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: tintColor.withValues(alpha: 0.95)),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap, {bool isFilled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isFilled ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: isFilled ? Colors.white : color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iosGroupedBg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.iosGroupedBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Discover',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              // Sort icon
              GestureDetector(
                key: _sortIconKey,
                onTap: _showSortMenu,
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _sortOption != _SortOption.priceLow
                        ? AppColors.iosSystemBlue.withValues(alpha: 0.12)
                        : AppColors.iosCardBg,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Icon(
                    Icons.sort_rounded,
                    color: _sortOption != _SortOption.priceLow ? AppColors.iosSystemBlue : AppColors.charcoal,
                    size: 19,
                  ),
                ),
              ),
              // Filter icon
              GestureDetector(
                onTap: _openFilterBottomSheet,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.iosCardBg,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.charcoal, size: 19),
                ),
              ),
            ],
          ),

          // ── Sticky Builder/Broker Quick-Filter ──
          SliverPersistentHeader(
            pinned: true,
            delegate: _QuickFilterBarDelegate(
              userTypeFilter: _currentFilter.userTypeFilter,
              onUserTypeChanged: (ut) {
                setState(() {
                  _currentFilter.userTypeFilter = ut;
                });
                _loadProperties();
              },
            ),
          ),

          // ── Content ──
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          else if (_properties.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 56, color: AppColors.iosTertiaryLabel),
                    const SizedBox(height: 16),
                    Text('No properties found', style: GoogleFonts.inter(fontSize: 18, color: AppColors.charcoal, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                    const SizedBox(height: 6),
                    Text('Try adjusting your filters', style: GoogleFonts.inter(color: AppColors.iosSecondaryLabel, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildPropertyCard(_sorted[index]),
                childCount: _sorted.length,
              ),
            ),

          // Bottom padding for frosted nav bar
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}

class _MetricItem {
  final IconData icon;
  final String label;
  final Color tint;
  const _MetricItem(this.icon, this.label, {required this.tint});
}

// ── Sticky quick-filter + sort bar ───────────────────────────────────────────

class _SegmentedFilter extends StatefulWidget {
  final UserTypeFilter? value;
  final ValueChanged<UserTypeFilter?> onChanged;

  const _SegmentedFilter({required this.value, required this.onChanged});

  @override
  State<_SegmentedFilter> createState() => _SegmentedFilterState();
}

class _SegmentedFilterState extends State<_SegmentedFilter> {
  UserTypeFilter? _lastValue;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.value ?? UserTypeFilter.builder;
  }

  @override
  void didUpdateWidget(_SegmentedFilter old) {
    super.didUpdateWidget(old);
    if (widget.value != null) {
      _lastValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.value != null;
    final align = _lastValue == UserTypeFilter.broker ? Alignment.centerRight : Alignment.centerLeft;
    final isBuilder = widget.value == UserTypeFilter.builder;
    final isBroker = widget.value == UserTypeFilter.broker;
    
    // Premium theme colors
    const builderColor = AppColors.accent;
    const brokerColor = AppColors.iosSystemBlue;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.iosCardBg, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated Pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            alignment: align,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: hasSelection ? 1.0 : 0.0,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: isBuilder ? builderColor : brokerColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isBuilder ? builderColor : brokerColor).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Buttons Row
          Row(
            children: [
              // Builder
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onChanged(isBuilder ? null : UserTypeFilter.builder),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isBuilder ? FontWeight.w700 : FontWeight.w600,
                        color: isBuilder ? AppColors.white : AppColors.charcoal,
                        letterSpacing: -0.2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<Color?>(
                            duration: const Duration(milliseconds: 200),
                            tween: ColorTween(end: isBuilder ? AppColors.white : AppColors.iosSecondaryLabel),
                            builder: (context, color, child) => Icon(
                              Icons.domain_rounded,
                              size: 15,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text('Builder'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Broker
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onChanged(isBroker ? null : UserTypeFilter.broker),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isBroker ? FontWeight.w700 : FontWeight.w600,
                        color: isBroker ? AppColors.white : AppColors.charcoal,
                        letterSpacing: -0.2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<Color?>(
                            duration: const Duration(milliseconds: 200),
                            tween: ColorTween(end: isBroker ? AppColors.white : AppColors.iosSecondaryLabel),
                            builder: (context, color, child) => Icon(
                              Icons.people_alt_rounded,
                              size: 15,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text('Broker'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickFilterBarDelegate extends SliverPersistentHeaderDelegate {
  final UserTypeFilter? userTypeFilter;
  final ValueChanged<UserTypeFilter?> onUserTypeChanged;

  const _QuickFilterBarDelegate({
    required this.userTypeFilter,
    required this.onUserTypeChanged,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.iosGroupedBg,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 8),
              child: _SegmentedFilter(
                value: userTypeFilter,
                onChanged: onUserTypeChanged,
              ),
            ),
          ),
          Container(height: 0.5, color: AppColors.iosSeparator.withValues(alpha: 0.25)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_QuickFilterBarDelegate old) =>
      old.userTypeFilter != userTypeFilter;
}
