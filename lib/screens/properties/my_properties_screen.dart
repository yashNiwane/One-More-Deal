import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../models/property_model.dart';
import 'package:intl/intl.dart';
import 'add_property_screen.dart';
import 'edit_property_screen.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  bool _isLoading = true;
  List<PropertyModel> _properties = [];

  @override
  void initState() {
    super.initState();
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
      await PropertyService.refreshProperty(p.id!, AuthService.currentUserId!, p.listingType);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing Refreshed!'), backgroundColor: AppColors.primary),
      );
      _loadProperties();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _deleteProperty(PropertyModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Property?'),
        content: const Text('Are you sure you want to delete this listing? It will no longer be visible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await PropertyService.deleteProperty(p.id!, AuthService.currentUserId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing Deleted'), backgroundColor: AppColors.primary),
      );
      _loadProperties();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildPropertyCard(PropertyModel p) {
    final areaStr = p.listingType == ListingType.plot 
        ? (p.areaValue != null ? '${p.areaValue} ${p.areaUnit}' : null)
        : (p.carpetArea != null ? '${p.carpetArea} SqFt' : (p.builtUpArea != null ? '${p.builtUpArea} SqFt' : null));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: p.isExpired ? AppColors.error.withOpacity(0.3) : AppColors.lightGray.withOpacity(0.6), width: 1),
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
                 
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(
                     color: p.isExpired ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(6),
                   ),
                   child: Text(
                     p.listingType.value,
                     style: GoogleFonts.plusJakartaSans(
                       fontSize: 10,
                       fontWeight: FontWeight.bold,
                       color: p.isExpired ? AppColors.error : AppColors.primary,
                     ),
                   ),
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
            const SizedBox(height: 6),
            
            // Footer: Expiry & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    p.isExpired ? 'Expired' : 'Expires in ${p.daysUntilDelete} days',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: p.isExpired ? AppColors.error : AppColors.mediumGray,
                      fontWeight: p.isExpired ? FontWeight.bold : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => _refreshProperty(p),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: Text('Refresh', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accent),
                      onPressed: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditPropertyScreen(property: p)));
                        if (result == true) _loadProperties();
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => _deleteProperty(p),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('My Properties', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: Text('Post Property', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w600)),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
          );
          if (result == true) {
            _loadProperties(); // Reload if new property added
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _properties.isEmpty
              ? Center(
                  child: Text(
                    'You have no properties listed.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppColors.mediumGray),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProperties,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 80), // padding for FAB
                    itemCount: _properties.length,
                    itemBuilder: (context, index) {
                      return _buildPropertyCard(_properties[index]);
                    },
                  ),
                ),
    );
  }
}
