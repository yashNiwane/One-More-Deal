import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../models/property_model.dart';
import '../../services/database_service.dart';

/// Admin screen showing unapproved builder properties.
/// Only accessible to admin phone: 9356965876.
class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  bool _isLoading = true;
  List<PropertyModel> _pendingProperties = [];

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => _isLoading = true);
    try {
      final items = await DatabaseService.instance.getPendingApprovals();
      if (mounted) setState(() => _pendingProperties = items);
    } catch (e) {
      debugPrint('[ADMIN] Error loading pending: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approve(PropertyModel prop) async {
    if (prop.id == null) return;
    try {
      await DatabaseService.instance.approveProperty(prop.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ "${prop.societyName ?? 'Property'}" approved!'),
          backgroundColor: AppColors.iosSystemGreen,
        ),
      );
      _loadPending();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.iosDestructive),
      );
    }
  }

  Future<void> _reject(PropertyModel prop) async {
    if (prop.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Property?'),
        content: Text('This will permanently hide "${prop.societyName ?? 'this property'}" from all listings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await DatabaseService.instance.rejectProperty(prop.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property rejected'), backgroundColor: AppColors.iosDestructive),
      );
      _loadPending();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.iosDestructive),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iosGroupedBg,
      appBar: AppBar(
        backgroundColor: AppColors.iosGroupedBg,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text('Admin Approvals', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
        actions: [
          IconButton(
            onPressed: _loadPending,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _pendingProperties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.iosSystemGreen.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No pending approvals', style: GoogleFonts.inter(fontSize: 16, color: AppColors.iosSecondaryLabel)),
                      const SizedBox(height: 8),
                      Text('All builder listings are reviewed!', style: GoogleFonts.inter(fontSize: 13, color: AppColors.iosTertiaryLabel)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPending,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _pendingProperties.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _buildApprovalCard(_pendingProperties[index]),
                  ),
                ),
    );
  }

  Widget _buildApprovalCard(PropertyModel prop) {
    final formatter = NumberFormat('#,##,###', 'en_IN');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.iosCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3)),
        ],
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('PENDING', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.amber.shade800, letterSpacing: 0.5)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    prop.societyName ?? 'Unnamed Project',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.charcoal),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info Grid ──
                _infoRow(Icons.location_on_outlined, '${prop.area}, ${prop.city}'),
                if (prop.reraNo != null && prop.reraNo!.isNotEmpty)
                  _infoRow(Icons.verified_outlined, 'RERA: ${prop.reraNo}'),
                if (prop.possessionDate != null)
                  _infoRow(Icons.calendar_today_outlined, 'Possession: ${DateFormat('dd/MM/yyyy').format(prop.possessionDate!)}'),
                if (prop.areaValue != null)
                  _infoRow(Icons.landscape_outlined, 'Land: ${prop.areaValue} Acres'),
                if (prop.totalBuildings != null)
                  _infoRow(Icons.apartment_rounded, 'Buildings: ${prop.totalBuildings}'),
                if (prop.amenitiesCount != null)
                  _infoRow(Icons.pool_rounded, 'Amenities: ${prop.amenitiesCount}+'),
                if (prop.buildingStructure != null && prop.buildingStructure!.isNotEmpty)
                  _infoRow(Icons.account_tree_outlined, 'Structure: ${prop.buildingStructure}'),
                if (prop.totalUnits != null)
                  _infoRow(Icons.grid_view_rounded, 'Total Units: ${prop.totalUnits}'),

                const SizedBox(height: 12),

                // ── Variants Table ──
                if (prop.variants != null && prop.variants!.isNotEmpty) ...[
                  Text('Variants', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.iosSeparator.withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1.4),
                          3: FlexColumnWidth(1.4),
                        },
                        border: TableBorder.symmetric(
                          inside: BorderSide(color: AppColors.iosSeparator.withOpacity(0.2)),
                        ),
                        children: [
                          // Header
                          TableRow(
                            decoration: BoxDecoration(color: AppColors.iosSystemBlue.withOpacity(0.06)),
                            children: [
                              _tableCell('Flat Type', isHeader: true),
                              _tableCell('Carpet', isHeader: true),
                              _tableCell('Agree. Cost', isHeader: true),
                              _tableCell('Total Cost', isHeader: true),
                            ],
                          ),
                          // Data rows
                          for (final v in prop.variants!)
                            TableRow(
                              children: [
                                _tableCell(v['flat_type']?.toString() ?? '-'),
                                _tableCell('${(v['carpet'] as num?)?.toInt() ?? '-'}'),
                                _tableCell(formatter.format((v['agreement_cost'] as num?)?.toInt() ?? 0)),
                                _tableCell(formatter.format((v['total_cost'] as num?)?.toInt() ?? 0)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // ── Posted By ──
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 14, color: AppColors.iosSecondaryLabel),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'By: ${prop.posterCompany ?? prop.posterName ?? 'Unknown'} (${prop.posterPhone ?? ''})',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.iosSecondaryLabel),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Action Buttons ──
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _reject(prop),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.iosDestructive.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.iosDestructive.withOpacity(0.3)),
                          ),
                          alignment: Alignment.center,
                          child: Text('Reject', style: GoogleFonts.inter(color: AppColors.iosDestructive, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => _approve(prop),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF34C759), Color(0xFF2AAF4F)]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: AppColors.iosSystemGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text('Approve', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                            ],
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
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.iosSecondaryLabel),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: AppColors.charcoal.withOpacity(0.8))),
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: isHeader ? 11 : 12,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          color: isHeader ? AppColors.iosSystemBlue : AppColors.charcoal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
