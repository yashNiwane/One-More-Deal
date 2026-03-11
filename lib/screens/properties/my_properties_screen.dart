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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: p.isExpired ? AppColors.error.withOpacity(0.3) : AppColors.lightGray.withOpacity(0.6), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Redesigned Header: Date on Left, Badges on Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_filled, size: 14, color: AppColors.mediumGray.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      'Posted ${DateFormat("MMM d").format(p.refreshedAt ?? p.postedAt ?? DateTime.now())}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.mediumGray, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.isExpired ? AppColors.error.withOpacity(0.12) : AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.listingType.value.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: p.isExpired ? AppColors.error : AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Redesigned Price
            if (p.price != null)
              Text(
                '₹${NumberFormat.decimalPattern('en_IN').format(p.price)}${p.listingType == ListingType.rent ? ' / mo' : ''}',
                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.charcoal, height: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (p.price != null) const SizedBox(height: 6),

            // Redesigned Title
            Text(
              p.societyName ?? p.category.value,
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.charcoal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 6),
            
            // Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.mediumGray),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.subarea != null && p.subarea!.isNotEmpty ? '${p.subarea}, ${p.area}, ${p.city}' : '${p.area}, ${p.city}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.mediumGray, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 14),
            
            // Redesigned Metrics Wrap (Clean Icons + Text)
            Wrap(
              spacing: 16,
              runSpacing: 12,
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
                  _buildMiniMetric(Icons.layers_outlined, '${p.floorCategory!.value} Flr'),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.lightGray, thickness: 0.5),
            const SizedBox(height: 12),
            
            // Footer: Expiry & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  p.isExpired ? 'Expired' : 'Expires in ${p.daysUntilDelete}d',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: p.isExpired ? AppColors.error : AppColors.mediumGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => _refreshProperty(p),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text('Refresh', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.accent),
                      onPressed: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditPropertyScreen(property: p)));
                        if (result == true) _loadProperties();
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: AppColors.charcoal.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.charcoal.withOpacity(0.9))),
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
