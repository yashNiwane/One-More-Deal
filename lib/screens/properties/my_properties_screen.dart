import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../models/property_model.dart';
import 'package:intl/intl.dart';
import 'add_property_screen.dart';
import 'add_builder_property_screen.dart';
import 'edit_property_screen.dart';
import '../subscription_screen.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

enum _SortOption {
  priceLow('Price: Low to High'),
  priceHigh('Price: High to Low'),
  newest('New first'),
  oldest('Old first'),
  area('Area: Largest first');

  const _SortOption(this.label);
  final String label;
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  static const String _builderPlanPromptSeenKey = 'builder_plan_prompt_seen';
  bool _isLoading = true;
  List<PropertyModel> _properties = [];
  PropertyCategory? _selectedCategory;
  ListingType? _selectedListingType;
  _SortOption _sortOption = _SortOption.priceLow;
  final GlobalKey _sortIconKey = GlobalKey();

  List<PropertyModel> get _filteredProperties {
    final list = _properties.where((p) {
      if (_selectedCategory != null && p.category != _selectedCategory) {
        return false;
      }
      if (_selectedListingType != null &&
          p.listingType != _selectedListingType) {
        return false;
      }
      return true;
    }).toList();

    switch (_sortOption) {
      case _SortOption.newest:
        list.sort(
          (a, b) => (b.refreshedAt ?? b.postedAt ?? DateTime(0)).compareTo(
            a.refreshedAt ?? a.postedAt ?? DateTime(0),
          ),
        );
      case _SortOption.oldest:
        list.sort(
          (a, b) => (a.refreshedAt ?? a.postedAt ?? DateTime(0)).compareTo(
            b.refreshedAt ?? b.postedAt ?? DateTime(0),
          ),
        );
      case _SortOption.priceLow:
        list.sort(
          (a, b) => (a.price ?? double.infinity).compareTo(
            b.price ?? double.infinity,
          ),
        );
      case _SortOption.priceHigh:
        list.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
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
    final isBuilder =
        AuthService.userType == 'Builder' ||
        AuthService.userType == 'Developer';
    _selectedCategory = isBuilder
        ? PropertyCategory.newProperty
        : PropertyCategory.residential;
    _selectedListingType = isBuilder
        ? ListingType.newLaunch
        : ListingType.resale;
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('Not logged in to view properties');
      final items = await PropertyService.getMyProperties(userId);
      if (mounted) setState(() => _properties = items);
    } catch (e) {
      debugPrint('[MY_PROPERTIES] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshProperty(PropertyModel p) async {
    try {
      await PropertyService.refreshProperty(
        p.id!,
        AuthService.currentUserId!,
        p.listingType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing Refreshed!'),
          backgroundColor: AppColors.iosSystemGreen,
        ),
      );
      _loadProperties();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.iosDestructive,
        ),
      );
    }
  }

  Future<void> _deleteProperty(PropertyModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete Property?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This listing will no longer be visible.',
          style: GoogleFonts.inter(color: AppColors.iosSecondaryLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.iosSystemBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: AppColors.iosDestructive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await PropertyService.deleteProperty(p.id!, AuthService.currentUserId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing Deleted'),
          backgroundColor: AppColors.iosSystemGreen,
        ),
      );
      _loadProperties();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.iosDestructive,
        ),
      );
    }
  }

  void _showSortMenu() {
    final RenderBox box =
        _sortIconKey.currentContext!.findRenderObject() as RenderBox;
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
                    color: isSelected
                        ? AppColors.iosSystemBlue
                        : AppColors.charcoal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.iosSystemBlue,
                ),
            ],
          ),
        );
      }).toList(),
    ).then((selected) {
      if (selected != null) setState(() => _sortOption = selected);
    });
  }

  // Helper to format price in Lakh/Crore
  String _formatPrice(double price) {
    if (price >= 10000000) {
      // Crore
      final crore = price / 10000000;
      return '₹${crore.toStringAsFixed(crore % 1 == 0 ? 0 : 2)}Cr';
    } else if (price >= 100000) {
      // Lakh
      final lakh = price / 100000;
      return '₹${lakh.toStringAsFixed(lakh % 1 == 0 ? 0 : 2)}L';
    } else {
      // Less than 1 lakh, show as is
      return '₹${NumberFormat.decimalPattern('en_IN').format(price.toInt())}';
    }
  }

  Widget _buildPropertyCard(PropertyModel p) {
    final isBuilder =
        p.listingType == ListingType.newLaunch ||
        p.category == PropertyCategory.newProperty;

    if (isBuilder) {
      return _buildBuilderCard(p);
    } else {
      return _buildBrokerCard(p);
    }
  }

  Widget _buildActiveBadge(PropertyModel p) {
    final isActive = p.isVisible && !p.isExpired;
    final Color bg = isActive
        ? AppColors.iosSystemGreen.withOpacity(0.15)
        : AppColors.iosDestructive.withOpacity(0.12);
    final Color fg = isActive ? AppColors.iosSystemGreen : AppColors.iosDestructive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 11,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Broker Card Design (same as feed) ──
  Widget _buildBrokerCard(PropertyModel p) {
    const Color cInk = AppColors.charcoal;
    const Color cSub = AppColors.darkGray;
    const Color cMuted = AppColors.mediumGray;
    const Color cDivider = AppColors.lightGray;
    const Color cChip = AppColors.offWhite;
    const Color cChipTxt = AppColors.darkGray;
    const Color cAccent = AppColors.accent;

    Color badgeColor;
    switch (p.listingType) {
      case ListingType.rent:
        badgeColor = AppColors.primaryLight;
        break;
      case ListingType.resale:
        badgeColor = AppColors.primary;
        break;
      case ListingType.plot:
        badgeColor = AppColors.accent;
        break;
      default:
        badgeColor = AppColors.success;
        break;
    }
    final badgeLabel = p.listingType == ListingType.newLaunch
        ? 'New'
        : p.listingType.value;

    final societyName = p.societyName?.trim().isNotEmpty == true
        ? p.societyName!.trim()
        : null;
    final locStr = [
      p.subarea?.trim().isNotEmpty == true ? p.subarea!.trim() : p.area,
      p.city,
    ].join(', ');

    final priceStr = p.price != null
        ? _formatPrice(p.price!)
        : 'Price on request';
    final depositStr = (p.deposit != null && p.listingType == ListingType.rent)
        ? 'Deposit \u20b9${NumberFormat.compact().format(p.deposit)}'
        : null;

    final String? areaStr = p.carpetArea != null
        ? '${p.carpetArea!.toStringAsFixed(0)} sqft'
        : (p.builtUpArea != null
              ? '${p.builtUpArea!.toStringAsFixed(0)} sqft'
              : (p.areaValue != null
                    ? '${p.areaValue!.toStringAsFixed(0)} ${p.areaUnit}'
                    : null));

    final floorCat =
        p.floorCategory ?? PropertyModel.floorCategoryFromNumber(p.floorNumber);
    final String? floorStr = floorCat != null
        ? '${floorCat.value} Floor'
        : null;
    final String? parkingStr =
        (p.parking?.trim().isNotEmpty == true && p.parking != 'Not available')
        ? p.parking!.trim()
        : null;
    final String? furnishStr = p.furnishingStatus?.trim().isNotEmpty == true
        ? p.furnishingStatus!.trim()
        : null;
    final String? availableForStr =
        p.category == PropertyCategory.residential &&
            p.listingType == ListingType.rent &&
            p.availableFor?.trim().isNotEmpty == true
        ? p.availableFor!.trim()
        : null;
    final String? availStr = p.availability?.trim().isNotEmpty == true
        ? p.availability!.trim()
        : null;

    Widget gChip(String label, IconData icon) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: cChip,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 11, color: cMuted),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cChipTxt,
              ),
            ),
          ),
        ],
      ),
    );

    final chips = <Widget>[
      if (p.flatType?.trim().isNotEmpty == true)
        gChip(p.flatType!.trim(), Icons.bed_outlined),
      if (areaStr != null) gChip(areaStr, Icons.square_foot_outlined),
      if (floorStr != null) gChip(floorStr, Icons.layers_outlined),
      if (parkingStr != null) gChip(parkingStr, Icons.directions_car_outlined),
      if (furnishStr != null) gChip(furnishStr, Icons.chair_outlined),
      if (availableForStr != null)
        gChip(availableForStr, Icons.family_restroom_outlined),
    ];

    Widget chipGrid() {
      final rows = <Widget>[];
      for (int i = 0; i < chips.length; i += 2) {
        rows.add(
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(child: chips[i]),
              const SizedBox(width: 5),
              if (i + 1 < chips.length)
                Expanded(child: chips[i + 1])
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        );
        if (i + 2 < chips.length) rows.add(const SizedBox(height: 5));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: rows,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.iosCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: p.isExpired
                                ? AppColors.iosDestructive.withValues(
                                    alpha: 0.08,
                                  )
                                : badgeColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            p.isExpired ? 'EXPIRED' : badgeLabel.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: p.isExpired
                                  ? AppColors.iosDestructive
                                  : badgeColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildActiveBadge(p),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            priceStr,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: cInk,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (depositStr != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 10,
                            color: cSub,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              depositStr,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: cSub,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (availStr != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available_outlined,
                            size: 10,
                            color: cSub,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              'Avail: $availStr',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (societyName != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1.5),
                            child: Icon(
                              Icons.apartment_outlined,
                              size: 12,
                              color: cMuted,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              societyName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cInk,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1.5),
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: cMuted,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            locStr,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.black,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chips.isNotEmpty) chipGrid(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 0.75, color: cDivider),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                p.isExpired
                    ? Icons.error_outline_rounded
                    : Icons.schedule_rounded,
                size: 14,
                color: p.isExpired ? AppColors.iosDestructive : cSub,
              ),
              const SizedBox(width: 4),
              Text(
                p.isExpired ? 'Expired' : 'Expires in ${p.daysUntilDelete}d',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: p.isExpired ? AppColors.iosDestructive : cSub,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _buildIconAction(
                Icons.refresh_rounded,
                AppColors.iosSystemBlue,
                () => _refreshProperty(p),
              ),
              const SizedBox(width: 6),
              _buildIconAction(Icons.edit_rounded, cAccent, () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditPropertyScreen(property: p),
                  ),
                );
                if (result == true) _loadProperties();
              }),
              const SizedBox(width: 6),
              _buildIconAction(
                Icons.delete_outline_rounded,
                AppColors.iosDestructive,
                () => _deleteProperty(p),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Builder Card Design (same as feed) ──
  Widget _buildBuilderCard(PropertyModel p) {
    const Color cInk = AppColors.charcoal;
    const Color cSub = AppColors.darkGray;
    const Color cMuted = AppColors.mediumGray;
    const Color cDivider = AppColors.lightGray;
    const Color cHeaderBg = AppColors.offWhite;
    const Color cHeaderAccent = AppColors.primaryLight;
    const Color cTableHeader = AppColors.offWhite;
    const Color cTableHeaderTxt = AppColors.darkGray;
    const Color cTableRowAlt = Color(0xFFFDF8EE);
    const Color cBadgeBg = Color(0xFFFEF3C7);
    const Color cBadgeTxt = AppColors.accent;

    final schemeName = p.societyName?.trim().isNotEmpty == true
        ? p.societyName!.trim()
        : 'Unnamed Project';

    final allVariants = p.variants ?? [];
    final unitVariants = allVariants.where((v) => v['type'] != 'meta').toList();
    final metaEntry = allVariants.firstWhere(
      (v) => v['type'] == 'meta',
      orElse: () => <String, dynamic>{},
    );
    final double? fos = (metaEntry['fos'] as num?)?.toDouble();
    final double? cpSlab = (metaEntry['cp_slab_percent'] as num?)?.toDouble();

    final nf = NumberFormat.decimalPattern('en_IN');

    Widget tableHeaderRow() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: const BoxDecoration(color: cTableHeader),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'Flat Type',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: cTableHeaderTxt,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Carpet',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: cTableHeaderTxt,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                'Agreement',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: cTableHeaderTxt,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                'Total Cost',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: cTableHeaderTxt,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
    }

    Widget variantRow(Map<String, dynamic> v, int idx) {
      final flatType = v['flat_type']?.toString() ?? '-';
      final carpet = (v['carpet'] as num?)?.toStringAsFixed(0) ?? '-';
      final agreement = (v['agreement_cost'] as num?) != null
          ? nf.format((v['agreement_cost'] as num).toInt())
          : '-';
      final totalCost = (v['total_cost'] as num?) != null
          ? nf.format((v['total_cost'] as num).toInt())
          : '-';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        color: idx.isOdd ? cTableRowAlt : AppColors.iosCardBg,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                flatType,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cInk,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                carpet,
                style: GoogleFonts.inter(fontSize: 11, color: cSub),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                agreement,
                style: GoogleFonts.inter(fontSize: 11, color: cSub),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                totalCost,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cInk,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
    }

    Widget infoChip(IconData icon, String label, String value) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: cTableHeader,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cDivider, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: cMuted),
            const SizedBox(width: 4),
            Text(
              '$label: ',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: cSub,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: cInk,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.iosCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cDivider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: const BoxDecoration(
              color: cHeaderBg,
              border: Border(bottom: BorderSide(color: cDivider, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cBadgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.apartment_rounded, size: 12, color: cBadgeTxt),
                      const SizedBox(width: 4),
                      Text(
                        'BUILDER',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: cBadgeTxt,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: p.isExpired
                        ? AppColors.iosDestructive.withValues(alpha: 0.1)
                        : cHeaderAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.isExpired ? 'EXPIRED' : 'NEW LAUNCH',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: p.isExpired
                          ? AppColors.iosDestructive
                          : cHeaderAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _buildActiveBadge(p),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schemeName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: cInk,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: cMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        [p.area, p.city].join(', '),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cSub,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (p.reraNo?.trim().isNotEmpty == true)
                  infoChip(Icons.verified_outlined, 'RERA', p.reraNo!.trim()),
                if (p.possessionDate != null)
                  infoChip(
                    Icons.event_outlined,
                    'Possession',
                    DateFormat('MM/yyyy').format(p.possessionDate!),
                  ),
                if (p.areaValue != null)
                  infoChip(
                    Icons.landscape_outlined,
                    'Land',
                    '${p.areaValue!.toStringAsFixed(p.areaValue! % 1 == 0 ? 0 : 1)} Acres',
                  ),
                if (p.totalBuildings != null)
                  infoChip(
                    Icons.apartment_outlined,
                    'Buildings',
                    p.totalBuildings.toString(),
                  ),
                if (p.totalUnits != null)
                  infoChip(
                    Icons.door_front_door_outlined,
                    'Units',
                    p.totalUnits.toString(),
                  ),
                if (p.amenitiesCount != null)
                  infoChip(
                    Icons.pool_outlined,
                    'Amenities',
                    '${p.amenitiesCount}+',
                  ),
                if (p.buildingStructure?.trim().isNotEmpty == true)
                  infoChip(
                    Icons.foundation_outlined,
                    'Structure',
                    p.buildingStructure!.trim(),
                  ),
                if (fos != null)
                  infoChip(
                    Icons.attach_money_outlined,
                    'FOS',
                    nf.format(fos.toInt()),
                  ),
                if (cpSlab != null)
                  infoChip(
                    Icons.percent_outlined,
                    'CP Slab',
                    '${cpSlab.toStringAsFixed(cpSlab % 1 == 0 ? 0 : 1)}%',
                  ),
              ],
            ),
          ),
          if (unitVariants.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: cDivider, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  tableHeaderRow(),
                  for (int i = 0; i < unitVariants.length; i++)
                    variantRow(unitVariants[i], i),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(height: 1, color: cDivider),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Icon(
                  p.isExpired
                      ? Icons.error_outline_rounded
                      : Icons.schedule_rounded,
                  size: 14,
                  color: p.isExpired ? AppColors.iosDestructive : cSub,
                ),
                const SizedBox(width: 4),
                Text(
                  p.isExpired ? 'Expired' : 'Expires in ${p.daysUntilDelete}d',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: p.isExpired ? AppColors.iosDestructive : cSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                _buildIconAction(
                  Icons.refresh_rounded,
                  AppColors.iosSystemBlue,
                  () => _refreshProperty(p),
                ),
                const SizedBox(width: 6),
                _buildIconAction(Icons.edit_rounded, cHeaderAccent, () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditPropertyScreen(property: p),
                    ),
                  );
                  if (result == true) _loadProperties();
                }),
                const SizedBox(width: 6),
                _buildIconAction(
                  Icons.delete_outline_rounded,
                  AppColors.iosDestructive,
                  () => _deleteProperty(p),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.16),
              color.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  int get _expiredCount => _properties.where((p) => p.isExpired).length;

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
    if (result == true) _loadProperties();
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

  Widget _buildFilterBar() {
    return Container(
      height: 34,
      color: const Color(0xFFF3F5F9),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(
            'Residential',
            _selectedCategory == PropertyCategory.residential,
            () => setState(() {
              final isSelected =
                  _selectedCategory == PropertyCategory.residential;
              _selectedCategory =
                  isSelected ? null : PropertyCategory.residential;
              if (!isSelected && _selectedListingType == ListingType.plot) {
                _selectedListingType = null;
              }
            }),
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Commercial',
            _selectedCategory == PropertyCategory.commercial,
            () => setState(() {
              final isSelected =
                  _selectedCategory == PropertyCategory.commercial;
              _selectedCategory =
                  isSelected ? null : PropertyCategory.commercial;
              if (!isSelected && _selectedListingType == ListingType.plot) {
                _selectedListingType = null;
              }
            }),
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Rent',
            _selectedListingType == ListingType.rent,
            () => setState(
              () {
                if (_selectedListingType == ListingType.rent) {
                  _selectedListingType = null;
                  return;
                }
                if (_selectedCategory == PropertyCategory.plot) {
                  _selectedCategory = null;
                }
                _selectedListingType = ListingType.rent;
              },
            ),
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Resale',
            _selectedListingType == ListingType.resale,
            () => setState(
              () {
                if (_selectedListingType == ListingType.resale) {
                  _selectedListingType = null;
                  return;
                }
                if (_selectedCategory == PropertyCategory.plot) {
                  _selectedCategory = null;
                }
                _selectedListingType = ListingType.resale;
              },
            ),
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Plot',
            _selectedCategory == PropertyCategory.plot,
            () => setState(() {
              final isSelected = _selectedCategory == PropertyCategory.plot;
              if (isSelected) {
                _selectedCategory = null;
                if (_selectedListingType == ListingType.plot) {
                  _selectedListingType = null;
                }
              } else {
                _selectedCategory = PropertyCategory.plot;
                _selectedListingType = ListingType.plot;
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightGray,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.darkGray,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalStat(String text, {bool live = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: live
              ? AppColors.iosSystemGreen.withValues(alpha: 0.3)
              : AppColors.mediumGray.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.iosSystemGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: live ? AppColors.iosSystemGreen : AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.home_work_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No listings yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start building your inventory and manage every property from this screen.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _openAddProperty,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: Text(
                'Add First Listing',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBuilder =
        AuthService.userType == 'Builder' ||
        AuthService.userType == 'Developer';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFFF3F5F9),
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: Text(
              'My Listings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              if (_properties.isNotEmpty)
                GestureDetector(
                  key: _sortIconKey,
                  onTap: _showSortMenu,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _sortOption != _SortOption.priceLow
                          ? AppColors.iosSystemBlue.withValues(alpha: 0.12)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.sort_rounded,
                      color: _sortOption != _SortOption.priceLow
                          ? AppColors.iosSystemBlue
                          : AppColors.charcoal,
                      size: 19,
                    ),
                  ),
                ),
              if (_properties.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      _buildMinimalStat('${_properties.length} Total'),
                      const SizedBox(width: 8),
                      _buildMinimalStat(
                        '${_properties.length - _expiredCount} Live',
                        live: true,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_properties.isNotEmpty && !isBuilder)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildFilterBar(),
              ),
            ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          else if (_properties.isEmpty)
            SliverFillRemaining(child: Center(child: _buildEmptyState()))
          else if (_filteredProperties.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No listings match the selected filters.',
                  style: GoogleFonts.inter(color: AppColors.darkGray),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildPropertyCard(_filteredProperties[index]),
                  childCount: _filteredProperties.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}
