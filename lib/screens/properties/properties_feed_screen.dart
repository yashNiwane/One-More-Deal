import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/property_model.dart';
import '../../models/enquiry_model.dart';
import '../../services/property_service.dart';
import '../../services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'filter_bottom_sheet.dart';

class PropertiesFeedScreen extends StatefulWidget {
  const PropertiesFeedScreen({super.key});

  @override
  State<PropertiesFeedScreen> createState() => _PropertiesFeedScreenState();
}

class _PropertiesFeedScreenState extends State<PropertiesFeedScreen> {
  bool _isLoading = true;
  List<PropertyModel> _properties = [];
  PropertyFilter _currentFilter = PropertyFilter();

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
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

  // Accent color based on listing type
  Color _accentForType(PropertyModel p) {
    final isBuilder = p.userId != null && p.category == PropertyCategory.newProperty;
    if (isBuilder) return AppColors.accent;
    switch (p.listingType) {
      case ListingType.rent:   return AppColors.success;
      case ListingType.plot:   return AppColors.info;
      default:                 return AppColors.primary;
    }
  }

  Widget _buildPropertyCard(PropertyModel p) {
    final isBuilder = p.userId != null && p.category == PropertyCategory.newProperty;
    final accentColor = _accentForType(p);
    
    final areaStr = p.listingType == ListingType.plot 
        ? (p.areaValue != null ? '${p.areaValue} ${p.areaUnit}' : null)
        : (p.carpetArea != null ? '${p.carpetArea} SqFt' : (p.builtUpArea != null ? '${p.builtUpArea} SqFt' : null));

    // Collect metrics for the right column
    final metrics = <_MetricItem>[];
    if (p.flatType != null && p.flatType!.isNotEmpty) {
      metrics.add(_MetricItem(Icons.king_bed_outlined, p.flatType!));
    }
    if (areaStr != null) {
      metrics.add(_MetricItem(Icons.square_foot_outlined, areaStr));
    }
    if (p.furnishingStatus != null && p.furnishingStatus!.isNotEmpty) {
      metrics.add(_MetricItem(Icons.chair_outlined, p.furnishingStatus!));
    }
    if (p.parking != null && p.parking!.isNotEmpty && p.parking != 'Not available') {
      metrics.add(_MetricItem(Icons.directions_car_outlined, p.parking!));
    }
    if (p.floorCategory != null) {
      metrics.add(_MetricItem(Icons.layers_outlined, '${p.floorCategory!.value} Floor'));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: accentColor.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
        border: Border.all(
          color: isBuilder ? AppColors.accent.withOpacity(0.4) : AppColors.lightGray.withOpacity(0.5),
          width: isBuilder ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left accent strip ──
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accentColor, accentColor.withOpacity(0.4)],
                  ),
                ),
              ),

              // ── Card content ──
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [AppColors.white, AppColors.offWhite.withOpacity(0.5)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header: Badges left, Date right ──
                      Row(
                        children: [
                          // Badges
                          if (isBuilder) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [AppColors.accent, AppColors.accentLight]),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text('BUILDER', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.white, letterSpacing: 0.6)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              p.listingType.value.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: accentColor, letterSpacing: 0.6),
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.schedule_rounded, size: 12, color: AppColors.mediumGray.withOpacity(0.5)),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat("MMM d").format(p.refreshedAt ?? p.postedAt ?? DateTime.now()),
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.mediumGray, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Two-column body ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column: Price, Title, Location
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Price
                                if (p.price != null)
                                  Text(
                                    '₹${NumberFormat.decimalPattern('en_IN').format(p.price)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.charcoal,
                                      height: 1.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (p.price != null && p.listingType == ListingType.rent)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'per month',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                                    ),
                                  ),
                                if (p.price != null) const SizedBox(height: 8),

                                // Title
                                Text(
                                  p.societyName ?? p.category.value,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.charcoal),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 6),

                                // Location
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1),
                                      child: Icon(Icons.location_on_rounded, size: 13, color: accentColor.withOpacity(0.7)),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        p.subarea != null && p.subarea!.isNotEmpty ? '${p.subarea}, ${p.area}' : '${p.area}, ${p.city}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.mediumGray, fontWeight: FontWeight.w500, height: 1.3),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Vertical subtle divider
                          if (metrics.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [AppColors.lightGray.withOpacity(0.0), AppColors.lightGray, AppColors.lightGray.withOpacity(0.0)],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],

                          // Right column: Stacked metrics
                          if (metrics.isNotEmpty)
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (int i = 0; i < metrics.length; i++) ...[
                                    _buildMetricRow(metrics[i].icon, metrics[i].label, accentColor),
                                    if (i < metrics.length - 1) const SizedBox(height: 10),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Divider ──
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accentColor.withOpacity(0.15), AppColors.lightGray.withOpacity(0.4), Colors.transparent],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Footer: Poster & Actions ──
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accentColor.withOpacity(0.15), accentColor.withOpacity(0.05)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              p.posterName != null && p.posterName!.isNotEmpty ? p.posterName![0].toUpperCase() : 'U',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: accentColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.posterName ?? 'Unknown',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.charcoal),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildActionButton(Icons.phone_rounded, AppColors.success, () async {
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
                          _buildActionButton(FontAwesomeIcons.whatsapp, const Color(0xFF25D366), () async {
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, String value, Color accentColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 13, color: accentColor.withOpacity(0.8)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.charcoal.withOpacity(0.85)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap, {bool isFilled = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isFilled ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: isFilled ? null : Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, size: 17, color: isFilled ? Colors.white : color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('Discover Properties', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.white),
            onPressed: _openFilterBottomSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _properties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: AppColors.mediumGray),
                      const SizedBox(height: 16),
                      Text('No properties found', style: GoogleFonts.plusJakartaSans(fontSize: 18, color: AppColors.charcoal, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Try adjusting your filters', style: GoogleFonts.plusJakartaSans(color: AppColors.mediumGray)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProperties,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: _properties.length,
                    itemBuilder: (context, index) {
                      return _buildPropertyCard(_properties[index]);
                    },
                  ),
                ),
    );
  }
}

/// Lightweight data holder for property metric rows.
class _MetricItem {
  final IconData icon;
  final String label;
  const _MetricItem(this.icon, this.label);
}
