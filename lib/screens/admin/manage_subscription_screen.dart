import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../models/subscription_request_model.dart';
import '../../services/database_service.dart';

class ManageSubscriptionScreen extends StatefulWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  State<ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState extends State<ManageSubscriptionScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<int> _selectedIds = <int>{};

  bool _isLoading = true;
  String? _error;
  String _search = '';
  SubscriptionRequestStatus _statusFilter = SubscriptionRequestStatus.pending;
  _RequestSort _sort = _RequestSort.latest;
  List<SubscriptionRequestModel> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rows = await DatabaseService.instance.getSubscriptionRequests(
        status: _statusFilter,
      );
      if (!mounted) return;
      setState(() => _rows = rows);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<SubscriptionRequestModel> get _visibleRows {
    final query = _search.trim().toLowerCase();
    final list = _rows.where((row) {
      if (query.isEmpty) return true;
      return (row.requesterName ?? '').toLowerCase().contains(query) ||
          (row.requesterPhone ?? '').toLowerCase().contains(query) ||
          (row.rejectionReason ?? '').toLowerCase().contains(query);
    }).toList();

    switch (_sort) {
      case _RequestSort.latest:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _RequestSort.oldest:
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case _RequestSort.amountHigh:
        list.sort((a, b) => (b.amountPaid ?? 0).compareTo(a.amountPaid ?? 0));
      case _RequestSort.amountLow:
        list.sort((a, b) => (a.amountPaid ?? 0).compareTo(b.amountPaid ?? 0));
      case _RequestSort.name:
        list.sort((a, b) => (a.requesterName ?? '').compareTo(b.requesterName ?? ''));
    }

    return list;
  }

  Future<void> _approve(SubscriptionRequestModel row) async {
    await DatabaseService.instance.approveSubscriptionRequest(row.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${row.requesterName ?? 'User'} approved', style: const TextStyle(fontSize: 12)),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
    _selectedIds.remove(row.id);
    await _load();
  }

  Future<void> _reject(SubscriptionRequestModel row) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Reject subscription',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 2,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Enter rejection reason',
            hintStyle: const TextStyle(fontSize: 13),
            filled: true,
            fillColor: AppColors.iosGroupedBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) Navigator.pop(context, val);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Reject', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (reason == null || reason.trim().isEmpty) return;
    await DatabaseService.instance.rejectSubscriptionRequest(row.id, reason.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${row.requesterName ?? 'User'} rejected', style: const TextStyle(fontSize: 12)),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 2),
      ),
    );
    _selectedIds.remove(row.id);
    await _load();
  }

  Future<String?> _askReason({
    required String title,
    required String actionLabel,
    required String hint,
    Color actionColor = AppColors.primary,
  }) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          maxLines: 2,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13),
            filled: true,
            fillColor: AppColors.iosGroupedBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) Navigator.pop(context, val);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return reason;
  }

  Future<void> _revoke(SubscriptionRequestModel row) async {
    final reason = await _askReason(
      title: 'Block User',
      actionLabel: 'Block',
      hint: 'Why block?',
      actionColor: AppColors.error,
    );
    if (reason == null || reason.trim().isEmpty) return;

    await DatabaseService.instance.revokeSubscriptionRequest(row.id, reason.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${row.requesterName ?? 'User'} blocked', style: const TextStyle(fontSize: 12)),
        backgroundColor: AppColors.error,
      ),
    );
    _selectedIds.remove(row.id);
    await _load();
  }

  Future<void> _bulkRevoke() async {
    if (_selectedIds.isEmpty) return;
    final reason = await _askReason(
      title: 'Bulk Block',
      actionLabel: 'Block All',
      hint: 'Why block these?',
      actionColor: AppColors.error,
    );
    if (reason == null || reason.trim().isEmpty) return;

    final rows = _visibleRows.where((row) => _selectedIds.contains(row.id)).toList();
    for (final row in rows) {
      await DatabaseService.instance.revokeSubscriptionRequest(row.id, reason.trim());
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${rows.length} users blocked', style: const TextStyle(fontSize: 12)),
        backgroundColor: AppColors.error,
      ),
    );
    _selectedIds.clear();
    await _load();
  }

  Future<void> _bulkApprove() async {
    if (_selectedIds.isEmpty) return;
    final rows = _visibleRows.where((row) => _selectedIds.contains(row.id)).toList();
    for (final row in rows) {
      await DatabaseService.instance.approveSubscriptionRequest(row.id);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${rows.length} requests approved', style: const TextStyle(fontSize: 12)),
        backgroundColor: AppColors.success,
      ),
    );
    _selectedIds.clear();
    await _load();
  }

  Future<void> _assignManually() async {
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '500');
    int months = 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text('Assign manually', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(labelText: 'Phone', isDense: true),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: months,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 mo', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 3, child: Text('3 mo', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 6, child: Text('6 mo', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => months = value);
                },
                decoration: const InputDecoration(labelText: 'Plan', isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(labelText: 'Amount', isDense: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Assign', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      phoneCtrl.dispose();
      amountCtrl.dispose();
      return;
    }

    try {
      await DatabaseService.instance.manuallyAssignSubscription(
        phone: phoneCtrl.text.trim(),
        planMonths: months,
        amountPaid: double.tryParse(amountCtrl.text.trim()) ?? 0,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assigned successfully'), backgroundColor: AppColors.success),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
    } finally {
      phoneCtrl.dispose();
      amountCtrl.dispose();
    }
  }

  Future<void> _blockUserDirectly() async {
    final phoneCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text('Block user', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(labelText: 'Phone', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(labelText: 'Reason', isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () {
              if (phoneCtrl.text.trim().isEmpty || reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Block', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      phoneCtrl.dispose();
      reasonCtrl.dispose();
      return;
    }

    try {
      await DatabaseService.instance.blockUserByPhone(
        phone: phoneCtrl.text.trim(),
        reason: reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User blocked'), backgroundColor: AppColors.error),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
    } finally {
      phoneCtrl.dispose();
      reasonCtrl.dispose();
    }
  }

  void _previewScreenshot(SubscriptionRequestModel row) {
    if (!row.hasScreenshot) return;
    Uint8List? imageBytes;
    try {
      imageBytes = base64Decode(row.screenshotBase64 ?? '');
    } catch (_) {
      imageBytes = null;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageBytes == null || imageBytes.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.white,
                        child: const Text('No preview available', style: TextStyle(fontSize: 12)),
                      )
                    : InteractiveViewer(child: Image.memory(imageBytes, fit: BoxFit.contain)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_search.isNotEmpty)
          InkWell(
            onTap: () {
              _searchCtrl.clear();
              setState(() => _search = '');
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.clear, size: 16, color: AppColors.darkGray),
            ),
          ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _assignManually,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.add, size: 18, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _blockUserDirectly,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.block, size: 16, color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: AppColors.iosGroupedBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHeaderAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subscriptions',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.charcoal),
              ),
              _buildTopActions(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _search = val),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      hintText: 'Search...',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32),
                      prefixIcon: const Icon(Icons.search, size: 16),
                      filled: true,
                      fillColor: AppColors.iosGroupedBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 34,
                  child: _buildCompactDropdown<SubscriptionRequestStatus>(
                    value: _statusFilter,
                    items: SubscriptionRequestStatus.values
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.value, style: const TextStyle(fontSize: 11)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _statusFilter = val);
                        _load();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 34,
                  child: _buildCompactDropdown<_RequestSort>(
                    value: _sort,
                    items: _RequestSort.values
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.label, style: const TextStyle(fontSize: 11)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _sort = val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkBar() {
    if (_selectedIds.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text(
              '${_selectedIds.length} Selected',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const Spacer(),
            InkWell(
              onTap: _bulkApprove,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(4)),
                child: const Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _bulkRevoke,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(4)),
                child: const Text('Block', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactAction({
    required IconData icon,
    required String label,
    required Color color,
    bool isOutlined = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color,
          border: isOutlined ? Border.all(color: color.withValues(alpha: 0.4)) : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: isOutlined ? color : Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: isOutlined ? color : Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(SubscriptionRequestModel row) {
    final isSelected = _selectedIds.contains(row.id);
    final statusColor = switch (row.status) {
      SubscriptionRequestStatus.pending => const Color(0xFFD97706),
      SubscriptionRequestStatus.approved => AppColors.success,
      SubscriptionRequestStatus.rejected => AppColors.error,
      SubscriptionRequestStatus.revoked => const Color(0xFF6B7280),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.lightGray.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() => isSelected ? _selectedIds.remove(row.id) : _selectedIds.add(row.id));
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() => val == true ? _selectedIds.add(row.id) : _selectedIds.remove(row.id));
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      splashRadius: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${row.requesterName ?? 'Unknown'} • ${row.requesterPhone ?? '-'}',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      row.status.value.toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 12, color: AppColors.darkGray),
                    const SizedBox(width: 4),
                    Text(
                      '₹${(row.amountPaid ?? 0).toStringAsFixed(0)} / ${row.planMonths}mo',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.charcoal),
                    ),
                    const Spacer(),
                    Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.mediumGray),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM hh:mm a').format(row.createdAt),
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.mediumGray),
                    ),
                  ],
                ),
              ),
              if ((row.rejectionReason ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    'Reason: ${row.rejectionReason}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.error, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Row(
                  children: [
                    if (row.hasScreenshot) ...[
                      _compactAction(
                        icon: Icons.image_outlined,
                        label: 'SS',
                        color: AppColors.primary,
                        onTap: () => _previewScreenshot(row),
                        isOutlined: true,
                      ),
                      const SizedBox(width: 6),
                    ],
                    const Spacer(),
                    if (row.status != SubscriptionRequestStatus.approved) ...[
                      _compactAction(
                        icon: Icons.check,
                        label: 'Approve',
                        color: AppColors.success,
                        onTap: () => _approve(row),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (row.status != SubscriptionRequestStatus.rejected) ...[
                      _compactAction(
                        icon: Icons.close,
                        label: 'Reject',
                        color: AppColors.error,
                        isOutlined: true,
                        onTap: () => _reject(row),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (row.status != SubscriptionRequestStatus.revoked)
                      _compactAction(
                        icon: Icons.block,
                        label: 'Block',
                        color: AppColors.charcoal,
                        isOutlined: true,
                        onTap: () => _revoke(row),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _visibleRows;
    return Scaffold(
      backgroundColor: AppColors.iosGroupedBg.withValues(alpha: 0.5),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverToBoxAdapter(
                child: _buildHeaderAndFilters(),
              ),
            ),
            _buildBulkBar(),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: $_error',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
                  ),
                ),
              )
            else if (rows.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No ${_statusFilter.value} subscriptions.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.mediumGray),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) => _buildCompactCard(rows[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _RequestSort {
  latest('Latest'),
  oldest('Oldest'),
  amountHigh('Amount High'),
  amountLow('Amount Low'),
  name('Name');

  const _RequestSort(this.label);
  final String label;
}
