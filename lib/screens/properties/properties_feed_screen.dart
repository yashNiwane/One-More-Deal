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

  Widget _buildPropertyCard(PropertyModel p) {
    final isBuilder = p.userId != null && p.category == PropertyCategory.newProperty;
    
    final areaStr = p.listingType == ListingType.plot 
        ? (p.areaValue != null ? '${p.areaValue} ${p.areaUnit}' : null)
        : (p.carpetArea != null ? '${p.carpetArea} SqFt' : (p.builtUpArea != null ? '${p.builtUpArea} SqFt' : null));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
        border: isBuilder ? Border.all(color: AppColors.accent, width: 1.5) : Border.all(color: AppColors.lightGray.withOpacity(0.6), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Header (Price + Badges)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (p.price != null)
                  Expanded(
                    child: Text(
                      '₹${NumberFormat.decimalPattern('en_IN').format(p.price)}${p.listingType == ListingType.rent ? ' / mo' : ''}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.charcoal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
                
                if (isBuilder)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('BUILDER', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(p.listingType.value, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Row 2: Title
            Text(
              p.societyName ?? p.category.value,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.charcoal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            
            // Row 3: Location
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.mediumGray),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    p.subarea != null && p.subarea!.isNotEmpty ? '${p.subarea}, ${p.area}, ${p.city}' : '${p.area}, ${p.city}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.mediumGray, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Row 4: Metrics Wrap
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (p.flatType != null && p.flatType!.isNotEmpty)
                  _buildMiniMetric(Icons.king_bed_outlined, p.flatType!),
                if (areaStr != null)
                  _buildMiniMetric(Icons.square_foot_outlined, areaStr),
                if (p.furnishingStatus != null && p.furnishingStatus!.isNotEmpty)
                  _buildMiniMetric(Icons.chair_outlined, p.furnishingStatus!),
                if (p.parking != null && p.parking!.isNotEmpty && p.parking != 'Not available')
                  _buildMiniMetric(Icons.directions_car_outlined, p.parking!),
                if (p.floorCategory != null)
                  _buildMiniMetric(Icons.layers_outlined, '${p.floorCategory!.value} Floor'),
              ],
            ),
            
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.lightGray),
            const SizedBox(height: 8),
            
            // Footer: Poster & Actions
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.lightGray,
                  child: Text(
                    p.posterName != null && p.posterName!.isNotEmpty ? p.posterName![0].toUpperCase() : 'U',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGray),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.posterName ?? 'Unknown',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.charcoal),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Posted ${DateFormat("MMM d").format(p.refreshedAt ?? p.postedAt ?? DateTime.now())}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.mediumGray),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(Icons.phone_outlined, AppColors.success, () async {
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
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGray.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap, {bool isFilled = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isFilled ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: isFilled ? null : Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 16, color: isFilled ? Colors.white : color),
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
