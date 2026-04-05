import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../models/property_model.dart';
import '../../services/database_service.dart';

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  bool _isLoading = true;
  int? _activePropertyId;
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
      if (mounted) {
        setState(() => _pendingProperties = items);
      }
    } catch (e) {
      debugPrint('[ADMIN] Error loading pending: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approve(PropertyModel prop) async {
    if (prop.id == null) return;
    setState(() => _activePropertyId = prop.id);
    try {
      await DatabaseService.instance.approveProperty(prop.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${prop.societyName ?? 'Property'}" approved successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadPending();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.iosDestructive,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _activePropertyId = null);
      }
    }
  }

  Future<void> _reject(PropertyModel prop) async {
    if (prop.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Property?'),
        content: Text(
          'This will permanently hide "${prop.societyName ?? 'this property'}" from all listings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Reject',
              style: TextStyle(color: AppColors.iosDestructive),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _activePropertyId = prop.id);
    try {
      await DatabaseService.instance.rejectProperty(prop.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property rejected'),
          backgroundColor: AppColors.iosDestructive,
        ),
      );
      await _loadPending();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.iosDestructive,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _activePropertyId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.iosGroupedBg,
      appBar: AppBar(
        backgroundColor: AppColors.iosGroupedBg,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Admin Approvals',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.charcoal,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadPending,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return RefreshIndicator(
      onRefresh: _loadPending,
      color: AppColors.accent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          if (_pendingProperties.isEmpty)
            _buildEmptyState()
          else
            ..._pendingProperties.map(
              (prop) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildApprovalCard(prop),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No pending approvals',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All builder listings are reviewed and the queue is clear.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(PropertyModel prop) {
    final formatter = NumberFormat('#,##,###', 'en_IN');
    final rawVariants = prop.variants ?? const <Map<String, dynamic>>[];
    final isActing = _activePropertyId == prop.id;

    num? toNum(dynamic value) {
      if (value == null) return null;
      if (value is num) return value;
      if (value is String) return num.tryParse(value);
      return null;
    }

    Map<String, dynamic>? meta;
    final variantRows = <Map<String, dynamic>>[];
    for (final variant in rawVariants) {
      if ((variant['type']?.toString().toLowerCase() ?? '') == 'meta') {
        meta = variant;
        continue;
      }
      if (variant.containsKey('flat_type')) {
        variantRows.add(variant);
        continue;
      }
      if (variant.containsKey('fos') ||
          variant.containsKey('cp_slab_percent')) {
        meta = variant;
      }
    }

    final fos = toNum(meta?['fos']);
    final cpSlabPercent = toNum(meta?['cp_slab_percent']);

    return Container(
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
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF8E6), Color(0xFFFFF1CC)],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'PENDING',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFB45309),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prop.societyName ?? 'Unnamed Project',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.charcoal,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${prop.area}, ${prop.city}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _detailChip(
                      Icons.verified_outlined,
                      prop.reraNo?.isNotEmpty == true
                          ? 'RERA: ${prop.reraNo}'
                          : 'RERA not added',
                    ),
                    if (prop.possessionDate != null)
                      _detailChip(
                        Icons.calendar_today_outlined,
                        'Possession ${DateFormat('MM/yyyy').format(prop.possessionDate!)}',
                      ),
                    if (prop.areaValue != null)
                      _detailChip(
                        Icons.landscape_outlined,
                        '${prop.areaValue} Acres',
                      ),
                    if (prop.totalUnits != null)
                      _detailChip(
                        Icons.grid_view_rounded,
                        '${prop.totalUnits} Units',
                      ),
                    if (prop.totalBuildings != null)
                      _detailChip(
                        Icons.apartment_rounded,
                        '${prop.totalBuildings} Buildings',
                      ),
                    if (prop.amenitiesCount != null)
                      _detailChip(
                        Icons.pool_rounded,
                        '${prop.amenitiesCount}+ Amenities',
                      ),
                  ],
                ),
                if (prop.buildingStructure?.isNotEmpty == true ||
                    fos != null ||
                    cpSlabPercent != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        if (prop.buildingStructure?.isNotEmpty == true)
                          _infoRow(
                            Icons.account_tree_outlined,
                            'Structure',
                            prop.buildingStructure!,
                          ),
                        if (fos != null)
                          _infoRow(
                            Icons.request_quote_outlined,
                            'FOS',
                            'Rs ${formatter.format(fos)}',
                          ),
                        if (cpSlabPercent != null)
                          _infoRow(
                            Icons.percent_rounded,
                            'CP Slab',
                            '${cpSlabPercent.toDouble() % 1 == 0 ? cpSlabPercent.toDouble().toStringAsFixed(0) : cpSlabPercent.toDouble().toStringAsFixed(1)}%',
                          ),
                      ],
                    ),
                  ),
                ],
                if (variantRows.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Variants',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.lightGray),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(0.9),
                          2: FlexColumnWidth(1.3),
                          3: FlexColumnWidth(1.3),
                        },
                        border: TableBorder.symmetric(
                          inside: BorderSide(
                            color: AppColors.lightGray.withValues(alpha: 0.8),
                          ),
                        ),
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                            ),
                            children: [
                              _tableCell('Flat Type', isHeader: true),
                              _tableCell('Carpet', isHeader: true),
                              _tableCell('Agree.', isHeader: true),
                              _tableCell('Total', isHeader: true),
                            ],
                          ),
                          for (final variant in variantRows)
                            TableRow(
                              children: [
                                _tableCell(
                                  variant['flat_type']?.toString() ?? '-',
                                ),
                                _tableCell(
                                  '${toNum(variant['carpet'])?.toInt() ?? '-'}',
                                ),
                                _tableCell(
                                  formatter.format(
                                    toNum(variant['agreement_cost'])?.toInt() ??
                                        0,
                                  ),
                                ),
                                _tableCell(
                                  formatter.format(
                                    toNum(variant['total_cost'])?.toInt() ?? 0,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.business_center_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${prop.posterCompany ?? prop.posterName ?? 'Unknown'}${prop.posterPhone?.isNotEmpty == true ? '  •  ${prop.posterPhone}' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isActing ? null : () => _reject(prop),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: BorderSide(
                            color: AppColors.iosDestructive.withValues(
                              alpha: 0.25,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          foregroundColor: AppColors.iosDestructive,
                        ),
                        child: Text(
                          'Reject',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: isActing ? null : () => _approve(prop),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: isActing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_rounded,
                                      color: AppColors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Approve Listing',
                                      style: GoogleFonts.inter(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
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

  Widget _detailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryLight),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: isHeader ? 11 : 12,
          fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
          color: isHeader ? AppColors.primary : AppColors.charcoal,
        ),
      ),
    );
  }
}
