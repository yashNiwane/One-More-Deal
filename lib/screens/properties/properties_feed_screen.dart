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
  final int? initialPropertyId;
  final PropertyFilter? initialFilter;
  final int? initialSortIndex;

  const PropertiesFeedScreen({
    super.key,
    this.initialPropertyId,
    this.initialFilter,
    this.initialSortIndex,
  });

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
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _propertyCardKeys = {};
  int? _highlightedPropertyId;
  bool _didFocusInitialProperty = false;
  bool _didRelaxInitialUserTypeFilter = false;

  List<PropertyModel> get _sorted {
    final list = List<PropertyModel>.from(_properties);
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
    _highlightedPropertyId = widget.initialPropertyId;
    if (widget.initialFilter != null) {
      _currentFilter = PropertyFilter.from(widget.initialFilter!);
    }
    if (widget.initialSortIndex != null && widget.initialSortIndex! >= 0 && widget.initialSortIndex! < _SortOption.values.length) {
      _sortOption = _SortOption.values[widget.initialSortIndex!];
    }
    _loadProperties();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final items = await PropertyService.getProperties(filter: _currentFilter);
      if (mounted) {
        setState(() => _properties = items);
        _maybeFocusInitialProperty();
      }
    } catch (e) {
      debugPrint('[FEED] Error loading properties: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _maybeFocusInitialProperty() {
    final targetId = widget.initialPropertyId;
    if (targetId == null || _didFocusInitialProperty) return;

    final targetExists = _sorted.any((p) => p.id == targetId);
    if (!targetExists &&
        !_didRelaxInitialUserTypeFilter &&
        widget.initialFilter?.userTypeFilter != null &&
        _currentFilter.userTypeFilter != null) {
      _didRelaxInitialUserTypeFilter = true;
      _currentFilter.userTypeFilter = null;
      _loadProperties();
      return;
    }

    if (!targetExists) return;

    _didFocusInitialProperty = true;
    _focusPropertyCard(targetId, attempt: 0);
  }

  void _focusPropertyCard(int propertyId, {required int attempt}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final key = _propertyCardKeys[propertyId];
      final targetContext = key?.currentContext;

      if (targetContext != null) {
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
        if (!mounted) return;
        setState(() => _highlightedPropertyId = propertyId);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && _highlightedPropertyId == propertyId) {
            setState(() => _highlightedPropertyId = null);
          }
        });
        return;
      }

      if (_scrollController.hasClients) {
        final index = _sorted.indexWhere((p) => p.id == propertyId);
        if (index >= 0) {
          final count = _sorted.length;
          final ratio = count <= 1 ? 0.0 : index / (count - 1);
          final estimatedOffset =
              (ratio * _scrollController.position.maxScrollExtent)
                  .clamp(0.0, _scrollController.position.maxScrollExtent)
                  .toDouble();
          final currentOffset = _scrollController.offset;
          if ((currentOffset - estimatedOffset).abs() > 24) {
            await _scrollController.animateTo(
              estimatedOffset,
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
            );
          }
        }
      }

      if (attempt >= 20) return;
      Future.delayed(const Duration(milliseconds: 110), () {
        if (mounted) {
          _focusPropertyCard(propertyId, attempt: attempt + 1);
        }
      });
    });
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
    const Color cInk = AppColors.charcoal;
    const Color cSub = AppColors.darkGray;
    const Color cMuted = AppColors.mediumGray;
    const Color cDivider = AppColors.lightGray;
    const Color cChip = AppColors.offWhite;
    const Color cChipTxt = AppColors.darkGray;
    const Color cCallBg = Color(0xFFEAF7F0);
    const Color cCallFg = AppColors.success;
    const Color cWaBg = Color(0xFF25D366);

    // Badge: Rent / Resale / Plot / New only
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

    // ── Derived values ──────────────────────────────
    final societyName = p.societyName?.trim().isNotEmpty == true
        ? p.societyName!.trim()
        : null;
    final locStr = [
      if (p.subarea?.trim().isNotEmpty == true) p.subarea!.trim(),
      if (p.area?.trim().isNotEmpty == true) p.area!.trim(),
      p.city,
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    final priceStr = p.price != null
        ? _formatPrice(p.price!)
        : 'Price on request';
    // final depositStr = (p.deposit != null && p.listingType == ListingType.rent)
    //     ? 'Deposit \u20b9${NumberFormat.compact().format(p.deposit)}' : null;

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
    final String? availStr = p.availability?.trim().isNotEmpty == true
        ? p.availability!.trim()
        : null;

    final companyOrName = (p.posterCompany?.trim().isNotEmpty == true)
        ? p.posterCompany!.trim()
        : (p.posterName ?? 'Unknown');
    final dateStr = DateFormat(
      'd MMM',
    ).format(p.refreshedAt ?? p.postedAt ?? DateTime.now());

    // ── Single chip: fills its Expanded slot ────────
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
    ];

    // ── 2-column chip grid aligned right ──────────────
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

    final isHighlighted = _highlightedPropertyId == p.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.iosCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFFFD54F)
              : const Color(0xFFEDF0F4),
          width: isHighlighted ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? const Color(0xFFFFD54F).withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isHighlighted ? 18 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Main Body: 2 Columns ─────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left Side: Badge, Price, Details ──
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badgeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Price
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
                    // if (depositStr != null) ...[
                    //   const SizedBox(height: 3),
                    //   Row(
                    //     crossAxisAlignment: CrossAxisAlignment.center,
                    //     children: [
                    //       Icon(Icons.account_balance_wallet_outlined, size: 10, color: cSub),
                    //       const SizedBox(width: 3),
                    //       Expanded(child: Text(depositStr, style: GoogleFonts.inter(fontSize: 11, color: cSub), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    //     ],
                    //   ),
                    // ],
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

                    // Society & Location
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

              // ── Right Side: Date & Chips ──
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date
                    Padding(
                      padding: const EdgeInsets.only(top: 3, bottom: 9),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 10,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 2-column grid of chips - right aligned
                    if (chips.isNotEmpty) chipGrid(),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(height: 0.75, color: cDivider),
          const SizedBox(height: 10),

          // ── Footer: company + buttons ───────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          p.posterCompany?.trim().isNotEmpty == true
                              ? Icons.storefront_outlined
                              : Icons.person_outline,
                          size: 13,
                          color: cSub,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            companyOrName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cSub,
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
              const SizedBox(width: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await PropertyService.logEnquiry(
                          propertyId: p.id!,
                          type: EnquiryType.call,
                        );
                        try {
                          final phone = await PropertyService.getPosterPhone(
                            p.userId,
                          );
                          if (phone != null) {
                            final uri = Uri.parse(
                              'tel:+91${phone.replaceAll(RegExp(r'\D'), '')}',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Phone not available'),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Call error: $e');
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: cCallBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.phone_rounded,
                          size: 16,
                          color: cCallFg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        await PropertyService.logEnquiry(
                          propertyId: p.id!,
                          type: EnquiryType.whatsApp,
                        );
                        try {
                          final phone = await PropertyService.getPosterPhone(
                            p.userId,
                          );
                          if (phone != null) {
                            String fp = phone;
                            if (!fp.startsWith('+')) {
                              fp = '+91${fp.replaceFirst(RegExp(r'^0+'), '')}';
                            }
                            final msg = Uri.encodeComponent(
                              'Hi,\nI saw your property listing\n${p.flatType ?? p.category.value} in ${p.societyName ?? p.area} on\nOne More Deal Broker App.\nPlease share details.',
                            );
                            final uri = Uri.parse(
                              'whatsapp://send?phone=$fp&text=$msg',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              final web = Uri.parse(
                                'https://wa.me/${fp.replaceAll('+', '')}?text=$msg',
                              );
                              if (await canLaunchUrl(web)) {
                                await launchUrl(
                                  web,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('WhatsApp not installed'),
                                  ),
                                );
                              }
                            }
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Phone not available'),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('WA error: $e');
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: cWaBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          FontAwesomeIcons.whatsapp,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Builder / New-Launch Card ────────────────────────────────────────
  Widget _buildBuilderCard(PropertyModel p) {
    // Soft, eye-friendly minimal palette
    const Color cInk = AppColors.charcoal;
    const Color cSub = AppColors.darkGray;
    const Color cMuted = AppColors.mediumGray;
    const Color cDivider = AppColors.lightGray;
    const Color cCallBg = Color(0xFFEAF7F0);
    const Color cCallFg = AppColors.success;
    const Color cWaBg = Color(0xFF25D366); // WhatsApp green
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
    final companyOrName = (p.posterCompany?.trim().isNotEmpty == true)
        ? p.posterCompany!.trim()
        : (p.posterName ?? 'Unknown');

    // Parse variants & meta
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

    final isHighlighted = _highlightedPropertyId == p.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.iosCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? const Color(0xFFFFD54F) : cDivider,
          width: isHighlighted ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? const Color(0xFFFFD54F).withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isHighlighted ? 20 : 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Minimal Header ──
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
                    color: cHeaderAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NEW LAUNCH',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: cHeaderAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MM/yyyy').format(p.refreshedAt ?? p.postedAt ?? DateTime.now()),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Project Name & Location ──
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

          // ── Info Chips ──
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

          // ── Variants Table ──
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

          // ── Divider ──
          Container(height: 1, color: cDivider),

          // ── Footer: Developer + Actions ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cTableHeader,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cDivider, width: 0.5),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.business_outlined,
                    size: 16,
                    color: cHeaderAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    companyOrName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cInk,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await PropertyService.logEnquiry(
                            propertyId: p.id!,
                            type: EnquiryType.call,
                          );
                          try {
                            final phone = await PropertyService.getPosterPhone(
                              p.userId,
                            );
                            if (phone != null) {
                              final uri = Uri.parse(
                                'tel:+91${phone.replaceAll(RegExp(r'\D'), '')}',
                              );
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            }
                          } catch (_) {}
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cCallBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cCallFg.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.phone_rounded,
                            size: 18,
                            color: cCallFg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          await PropertyService.logEnquiry(
                            propertyId: p.id!,
                            type: EnquiryType.whatsApp,
                          );
                          try {
                            final phone = await PropertyService.getPosterPhone(
                              p.userId,
                            );
                            if (phone != null) {
                              String fp = phone;
                              if (!fp.startsWith('+')) {
                                fp =
                                    '+91${fp.replaceFirst(RegExp(r'^0+'), '')}';
                              }
                              final msg = Uri.encodeComponent(
                                'Hi, I saw your project ${p.societyName ?? p.area} on One More Deal.',
                              );
                              final uri = Uri.parse(
                                'whatsapp://send?phone=$fp&text=$msg',
                              );
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                final web = Uri.parse(
                                  'https://wa.me/${fp.replaceAll('+', '')}?text=$msg',
                                );
                                if (await canLaunchUrl(web)) {
                                  await launchUrl(
                                    web,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              }
                            }
                          } catch (_) {}
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cWaBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            FontAwesomeIcons.whatsapp,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iosGroupedBg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.iosGroupedBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Discover',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                    letterSpacing: -0.3,
                  ),
                ),
                if (_currentFilter.area != null && _currentFilter.area!.trim().isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded, size: 11, color: AppColors.primaryLight),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          _currentFilter.area!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (_currentFilter.city != null && _currentFilter.city!.trim().isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_city_rounded, size: 11, color: AppColors.mediumGray),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          _currentFilter.city!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
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
              // Filter icon
              GestureDetector(
                onTap: _openFilterBottomSheet,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.iosCardBg,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.charcoal,
                    size: 19,
                  ),
                ),
              ),
            ],
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
                    Icon(
                      Icons.search_off_rounded,
                      size: 56,
                      color: AppColors.iosTertiaryLabel,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No properties found',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: AppColors.charcoal,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try adjusting your filters',
                      style: GoogleFonts.inter(
                        color: AppColors.iosSecondaryLabel,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final prop = _sorted[index];
                final cardKey = prop.id != null
                    ? (_propertyCardKeys[prop.id!] ??= GlobalKey())
                    : GlobalKey();
                // Show builder card for new launch properties OR properties with category newProperty
                final isBuilder =
                    prop.listingType == ListingType.newLaunch ||
                    prop.category == PropertyCategory.newProperty;
                return KeyedSubtree(
                  key: cardKey,
                  child: isBuilder
                      ? _buildBuilderCard(prop)
                      : _buildPropertyCard(prop),
                );
              }, childCount: _sorted.length),
            ),

          // Bottom padding for frosted nav bar
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
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
    final align = _lastValue == UserTypeFilter.broker
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final isBuilder = widget.value == UserTypeFilter.builder;
    final isBroker = widget.value == UserTypeFilter.broker;

    // Eye-friendly soft colors
    const builderColor = AppColors.accent;
    const brokerColor = AppColors.primaryLight;

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
                        color: (isBuilder ? builderColor : brokerColor)
                            .withValues(alpha: 0.35),
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
                  onTap: () => widget.onChanged(
                    isBuilder ? null : UserTypeFilter.builder,
                  ),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isBuilder
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isBuilder ? AppColors.white : AppColors.charcoal,
                        letterSpacing: -0.2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<Color?>(
                            duration: const Duration(milliseconds: 200),
                            tween: ColorTween(
                              end: isBuilder
                                  ? AppColors.white
                                  : AppColors.iosSecondaryLabel,
                            ),
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
                  onTap: () =>
                      widget.onChanged(isBroker ? null : UserTypeFilter.broker),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isBroker
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isBroker ? AppColors.white : AppColors.charcoal,
                        letterSpacing: -0.2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<Color?>(
                            duration: const Duration(milliseconds: 200),
                            tween: ColorTween(
                              end: isBroker
                                  ? AppColors.white
                                  : AppColors.iosSecondaryLabel,
                            ),
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
  final PropertyFilter currentFilter;
  final Function(PropertyFilter) onFilterChanged;

  const _QuickFilterBarDelegate({
    required this.userTypeFilter,
    required this.onUserTypeChanged,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  double get minExtent => 61;
  @override
  double get maxExtent => 61;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.iosGroupedBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 8,
            ),
            child: SizedBox(
              height: 40,
              child: _SegmentedFilter(
                value: userTypeFilter,
                onChanged: onUserTypeChanged,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 0.5,
            color: AppColors.iosSeparator.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_QuickFilterBarDelegate old) =>
      old.userTypeFilter != userTypeFilter ||
      old.currentFilter.category != currentFilter.category ||
      old.currentFilter.listingType != currentFilter.listingType;
}
