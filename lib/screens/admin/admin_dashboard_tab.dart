import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../services/database_service.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  static const int _days = 14;

  bool _loading = true;
  String? _error;

  Map<String, int>? _stats;
  List<DailyCount> _newUsers = const [];
  List<DailyCount> _newListings = const [];
  Map<String, int> _categoryBreakdown = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        DatabaseService.instance.getAdminDashboardStats(),
        DatabaseService.instance.getAdminNewUsersByDay(days: _days),
        DatabaseService.instance.getAdminNewListingsByDay(days: _days),
        DatabaseService.instance.getAdminPropertyCategoryBreakdown(),
      ]);

      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, int>;
        _newUsers = results[1] as List<DailyCount>;
        _newListings = results[2] as List<DailyCount>;
        _categoryBreakdown = results[3] as Map<String, int>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats ?? const <String, int>{};
    final pending = stats['pendingApprovals'] ?? 0;
    final totalListings = stats['totalProperties'] ?? 0;
    final activeUsers = stats['activeUsers'] ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          _buildHeroSummary(
            pendingApprovals: pending,
            totalListings: totalListings,
            activeUsers: activeUsers,
          ),
          const SizedBox(height: 12),
          if (_error != null) _buildError(_error!),
          if (_loading) ...[
            const SizedBox(height: 40),
            const Center(child: CircularProgressIndicator.adaptive()),
          ] else ...[
            _buildStatGrid(stats),
            // _buildPieChartCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroSummary({
    required int pendingApprovals,
    required int totalListings,
    required int activeUsers,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF213A78), Color(0xFF345FC7)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Pulse',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'A quick executive snapshot for the last $_days days.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.white.withValues(alpha: 0.74),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.white.withValues(alpha: 0.12),
                  foregroundColor: AppColors.white,
                ),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _heroMetric(
                  label: 'Pending',
                  value: pendingApprovals,
                  icon: Icons.pending_actions_rounded,
                  tint: AppColors.accentLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _heroMetric(
                  label: 'Listings',
                  value: totalListings,
                  icon: Icons.home_work_rounded,
                  tint: const Color(0xFF93C5FD),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _heroMetric(
                  label: 'Active users',
                  value: activeUsers,
                  icon: Icons.groups_rounded,
                  tint: const Color(0xFF86EFAC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric({
    required String label,
    required int value,
    required IconData icon,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tint, size: 18),
          const SizedBox(height: 18),
          Text(
            NumberFormat.compact().format(value),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(Map<String, int> stats) {
    final items = <_StatTileData>[
      _StatTileData(
        icon: Icons.people_alt_rounded,
        label: 'Total users',
        value: stats['totalUsers'] ?? 0,
        tint: const Color(0xFF2563EB),
      ),
      _StatTileData(
        icon: Icons.verified_user_rounded,
        label: 'Active users',
        value: stats['activeUsers'] ?? 0,
        tint: const Color(0xFF16A34A),
      ),
      _StatTileData(
        icon: Icons.home_work_rounded,
        label: 'Total listings',
        value: stats['totalProperties'] ?? 0,
        tint: const Color(0xFF7C3AED),
      ),
      _StatTileData(
        icon: Icons.visibility_rounded,
        label: 'Visible listings',
        value: stats['visibleProperties'] ?? 0,
        tint: const Color(0xFF0891B2),
      ),
      _StatTileData(
        icon: Icons.pending_actions_rounded,
        label: 'Pending approvals',
        value: stats['pendingApprovals'] ?? 0,
        tint: const Color(0xFFD97706),
      ),
      _StatTileData(
        icon: Icons.apartment_rounded,
        label: 'Builder projects',
        value: stats['builderProjects'] ?? 0,
        tint: const Color(0xFFEA580C),
      ),
      _StatTileData(
        icon: Icons.workspace_premium_rounded,
        label: 'Active subs',
        value: stats['activeSubscriptions'] ?? 0,
        tint: AppColors.accent,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.34,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 22,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.tint, size: 20),
              ),
              const Spacer(),
              Text(
                NumberFormat.compact().format(item.value),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLineChartCard() {
    final users = _normalizedSeries(days: _days, raw: _newUsers);
    final listings = _normalizedSeries(days: _days, raw: _newListings);

    final maxY = math
        .max(
          1,
          math.max(
            users.map((e) => e.count).fold<int>(0, math.max),
            listings.map((e) => e.count).fold<int>(0, math.max),
          ),
        )
        .toDouble();

    final userSpots = <FlSpot>[
      for (int i = 0; i < users.length; i++)
        FlSpot(i.toDouble(), users[i].count.toDouble()),
    ];
    final listingSpots = <FlSpot>[
      for (int i = 0; i < listings.length; i++)
        FlSpot(i.toDouble(), listings[i].count.toDouble()),
    ];

    final startDay = DateTime.now().toLocal().subtract(
      const Duration(days: _days - 1),
    );
    final dayFmt = DateFormat('d MMM');

    return _sectionCard(
      title: 'Growth Curve',
      subtitle: 'New users vs new listings',
      child: SizedBox(
        height: 240,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (_days - 1).toDouble(),
            minY: 0,
            maxY: maxY + 1,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: math.max(1, (maxY / 4).roundToDouble()),
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.lightGray.withValues(alpha: 0.65),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: math.max(1, (maxY / 4).roundToDouble()),
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 3,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= _days) return const SizedBox.shrink();
                    final d = DateTime(
                      startDay.year,
                      startDay.month,
                      startDay.day,
                    ).add(Duration(days: i));
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        dayFmt.format(d),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) =>
                    AppColors.charcoal.withValues(alpha: 0.92),
                getTooltipItems: (items) {
                  return items.map((item) {
                    final label = item.barIndex == 0 ? 'Users' : 'Listings';
                    return LineTooltipItem(
                      '$label: ${item.y.toInt()}',
                      GoogleFonts.inter(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: userSpots,
                isCurved: true,
                barWidth: 4,
                color: AppColors.iosSystemBlue,
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.iosSystemBlue.withValues(alpha: 0.12),
                ),
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: listingSpots,
                isCurved: true,
                barWidth: 4,
                color: AppColors.accent,
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.accent.withValues(alpha: 0.12),
                ),
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
      footer: Row(
        children: [
          _legendDot(AppColors.iosSystemBlue),
          const SizedBox(width: 6),
          Text(
            'Users',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(width: 14),
          _legendDot(AppColors.accent),
          const SizedBox(width: 6),
          Text(
            'Listings',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard() {
    final entries =
        _categoryBreakdown.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final total = entries.fold<int>(0, (p, e) => p + e.value);
    final colors = <Color>[
      const Color(0xFF7C3AED),
      const Color(0xFF0891B2),
      const Color(0xFFEA580C),
      const Color(0xFF16A34A),
      const Color(0xFF64748B),
    ];

    return _sectionCard(
      title: 'Category Mix',
      subtitle: 'Distribution across listing inventory',
      child: total == 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No data available yet',
                style: GoogleFonts.inter(color: AppColors.iosSecondaryLabel),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 50,
                        sections: [
                          for (int i = 0; i < entries.length; i++)
                            PieChartSectionData(
                              value: entries[i].value.toDouble(),
                              color: colors[i % colors.length],
                              radius: 52,
                              title: '',
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < entries.length && i < 6; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              _legendDot(colors[i % colors.length]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entries[i].key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.charcoal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${((entries[i].value / total) * 100).round()}%',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkGray,
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

  Widget _legendDot(Color c) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
          if (footer != null) ...[const SizedBox(height: 14), footer],
        ],
      ),
    );
  }

  List<DailyCount> _normalizedSeries({
    required int days,
    required List<DailyCount> raw,
  }) {
    final now = DateTime.now().toLocal();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    final byKey = <String, int>{
      for (final row in raw)
        '${row.day.year}-${row.day.month}-${row.day.day}': row.count,
    };

    return [
      for (int i = 0; i < days; i++)
        (
          day: start.add(Duration(days: i)),
          count:
              byKey['${start.add(Duration(days: i)).year}-${start.add(Duration(days: i)).month}-${start.add(Duration(days: i)).day}'] ??
              0,
        ),
    ];
  }
}

class _StatTileData {
  final IconData icon;
  final String label;
  final int value;
  final Color tint;

  const _StatTileData({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });
}
