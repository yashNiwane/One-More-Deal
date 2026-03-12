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
        const SnackBar(content: Text('Listing Refreshed!'), backgroundColor: AppColors.iosSystemGreen),
      );
      _loadProperties();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.iosDestructive),
      );
    }
  }

  Future<void> _deleteProperty(PropertyModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete Property?', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text('This listing will no longer be visible.', style: GoogleFonts.inter(color: AppColors.iosSecondaryLabel)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.iosSystemBlue, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter(color: AppColors.iosDestructive, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await PropertyService.deleteProperty(p.id!, AuthService.currentUserId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing Deleted'), backgroundColor: AppColors.iosSystemGreen),
      );
      _loadProperties();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.iosDestructive),
      );
    }
  }

  Widget _buildPropertyCard(PropertyModel p) {
    final areaStr = p.listingType == ListingType.plot 
        ? (p.areaValue != null ? '${p.areaValue} ${p.areaUnit}' : null)
        : (p.carpetArea != null ? '${p.carpetArea} SqFt' : (p.builtUpArea != null ? '${p.builtUpArea} SqFt' : null));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.iosCardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.isExpired ? AppColors.iosDestructive.withOpacity(0.1) : AppColors.iosSystemBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.listingType.value.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: p.isExpired ? AppColors.iosDestructive : AppColors.iosSystemBlue,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat("MMM d").format(p.refreshedAt ?? p.postedAt ?? DateTime.now()),
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.iosSecondaryLabel),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Price
            if (p.price != null)
              Text(
                '₹${NumberFormat.decimalPattern('en_IN').format(p.price)}${p.listingType == ListingType.rent ? ' / mo' : ''}',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.charcoal, letterSpacing: -0.5),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            if (p.price != null) const SizedBox(height: 6),

            // Title
            Text(
              p.societyName ?? p.category.value,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.charcoal, letterSpacing: -0.2),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Location
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 13, color: AppColors.iosSecondaryLabel),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    p.subarea != null && p.subarea!.isNotEmpty ? '${p.subarea}, ${p.area}, ${p.city}' : '${p.area}, ${p.city}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.iosSecondaryLabel),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Metrics
            Wrap(
              spacing: 12, runSpacing: 8,
              children: [
                if (p.flatType != null && p.flatType!.isNotEmpty) _buildChip(p.flatType!),
                if (areaStr != null) _buildChip(areaStr),
                if (p.furnishingStatus != null && p.furnishingStatus!.isNotEmpty) _buildChip(p.furnishingStatus!),
                if (p.parking != null && p.parking!.isNotEmpty && p.parking != 'Not available') _buildChip(p.parking!),
              ],
            ),

            const SizedBox(height: 14),
            Container(height: 0.5, color: AppColors.iosSeparator.withOpacity(0.4)),
            const SizedBox(height: 12),

            // Footer: Expiry + Actions
            Row(
              children: [
                Icon(
                  p.isExpired ? Icons.error_outline_rounded : Icons.schedule_rounded,
                  size: 14,
                  color: p.isExpired ? AppColors.iosDestructive : AppColors.iosSecondaryLabel,
                ),
                const SizedBox(width: 4),
                Text(
                  p.isExpired ? 'Expired' : 'Expires in ${p.daysUntilDelete}d',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: p.isExpired ? AppColors.iosDestructive : AppColors.iosSecondaryLabel,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                _buildIconAction(Icons.refresh_rounded, AppColors.iosSystemBlue, () => _refreshProperty(p)),
                const SizedBox(width: 6),
                _buildIconAction(Icons.edit_rounded, AppColors.accent, () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditPropertyScreen(property: p)));
                  if (result == true) _loadProperties();
                }),
                const SizedBox(width: 6),
                _buildIconAction(Icons.delete_outline_rounded, AppColors.iosDestructive, () => _deleteProperty(p)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.iosGroupedBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.darkGray)),
    );
  }

  Widget _buildIconAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iosGroupedBg,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 86, right: 4), // Added extra margin for bottom nav bar
        child: FloatingActionButton(
          backgroundColor: AppColors.iosSystemBlue,
          foregroundColor: AppColors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
            );
            if (result == true) _loadProperties();
          },
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── App Bar with Add button ──
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.iosGroupedBg,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: Text(
              'My Listings',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
                letterSpacing: -0.3,
              ),
            ),
            // Add button moved to FloatingActionButton
          ),

          // ── Body ──
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
                    Icon(Icons.home_work_outlined, size: 56, color: AppColors.iosTertiaryLabel),
                    const SizedBox(height: 16),
                    Text('No listings yet', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
                    const SizedBox(height: 6),
                    Text('Tap + to add your first property', style: GoogleFonts.inter(color: AppColors.iosSecondaryLabel, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildPropertyCard(_properties[index]),
                childCount: _properties.length,
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}
