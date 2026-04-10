import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';

import 'package:excel/excel.dart' as excel_pkg;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_colors.dart';
import '../../services/database_service.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  bool _loading = true;
  String? _error;

  Map<String, int> _overview = const {};
  List<Map<String, dynamic>> _suspensions7d = const [];
  List<Map<String, dynamic>> _suspensions30d = const [];
  List<Map<String, dynamic>> _payments7d = const [];
  List<Map<String, dynamic>> _payments30d = const [];

  String _suspension7Query = '';
  String _suspension30Query = '';
  String _payment7Query = '';
  String _payment30Query = '';

  int _suspension7Page = 0;
  int _suspension30Page = 0;
  int _payment7Page = 0;
  int _payment30Page = 0;

  int _suspension7RowsPerPage = 5;
  int _suspension30RowsPerPage = 5;
  int _payment7RowsPerPage = 5;
  int _payment30RowsPerPage = 5;

  int? _suspension7SortColumnIndex;
  bool _suspension7SortAscending = true;
  int? _suspension30SortColumnIndex;
  bool _suspension30SortAscending = true;
  int? _payment7SortColumnIndex;
  bool _payment7SortAscending = true;
  int? _payment30SortColumnIndex;
  bool _payment30SortAscending = true;

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
        DatabaseService.instance.getAdminCompactOverviewStats(
          suspensionDays: 7,
        ),
        DatabaseService.instance.getAdminUpcomingSuspensions(days: 7),
        DatabaseService.instance.getAdminUpcomingSuspensions(days: 30),
        DatabaseService.instance.getAdminRecentPayments(days: 7),
        DatabaseService.instance.getAdminRecentPayments(days: 30),
      ]);

      if (!mounted) return;
      setState(() {
        _overview = results[0] as Map<String, int>;
        _suspensions7d = results[1] as List<Map<String, dynamic>>;
        _suspensions30d = results[2] as List<Map<String, dynamic>>;
        _payments7d = results[3] as List<Map<String, dynamic>>;
        _payments30d = results[4] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildOverviewGrid(),
          if (_error != null) ...[
            const SizedBox(height: 10),
            _buildError(_error!),
          ],
          if (_loading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator.adaptive()),
          ] else ...[
            const SizedBox(height: 10),
            _buildSuspensionTable(
              title: 'Next 7 Days Suspension',
              rows: _suspensions7d,
              is7Days: true,
            ),
            const SizedBox(height: 10),
            _buildSuspensionTable(
              title: 'Next 30 Days Suspension',
              rows: _suspensions30d,
              is7Days: false,
            ),
            const SizedBox(height: 10),
            _buildPaymentTable(
              title: '7 Days Payment Details',
              rows: _payments7d,
            ),
            const SizedBox(height: 10),
            _buildPaymentTable(
              title: '30 Days Payment Details',
              rows: _payments30d,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'One More Deal™ - Admin Dashboard',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal,
              ),
            ),
          ),
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              foregroundColor: AppColors.primary,
              minimumSize: const Size(34, 34),
              padding: EdgeInsets.zero,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid() {
    final cards = <_OverviewCardData>[
      _OverviewCardData(
        title: 'Total Brokers',
        value: _overview['totalBrokers'] ?? 0,
        color: const Color(0xFF2A64D6),
      ),
      _OverviewCardData(
        title: 'Next 7 Days Suspension (Broker)',
        value: _overview['brokerNext7Suspension'] ?? 0,
        color: const Color(0xFFD97706),
      ),
      _OverviewCardData(
        title: 'Total Builders',
        value: _overview['totalBuilders'] ?? 0,
        color: const Color(0xFF1F8F63),
      ),
      _OverviewCardData(
        title: 'Next 7 Days Suspension (Builder)',
        value: _overview['builderNext7Suspension'] ?? 0,
        color: const Color(0xFFB45309),
      ),
      _OverviewCardData(
        title: 'Total Broker Listings',
        value: _overview['totalBrokerListings'] ?? 0,
        color: const Color(0xFF2D4A9B),
      ),
      _OverviewCardData(
        title: 'Total Builder Listings',
        value: _overview['totalBuilderListings'] ?? 0,
        color: const Color(0xFF2563EB),
      ),
      _OverviewCardData(
        title: '7 Days Payment Details',
        value: _overview['payments7d'] ?? 0,
        color: const Color(0xFFB38A00),
      ),
      _OverviewCardData(
        title: '30 Days Payment Details',
        value: _overview['payments30d'] ?? 0,
        color: const Color(0xFF8A6A00),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.35,
      ),
      itemBuilder: (context, index) {
        final item = cards[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color.withValues(alpha: 0.30)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        NumberFormat.decimalPattern('en_IN').format(item.value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: item.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuspensionTable({
    required String title,
    required List<Map<String, dynamic>> rows,
    required bool is7Days,
  }) {
    final query = is7Days ? _suspension7Query : _suspension30Query;
    final rowsPerPage = is7Days ? _suspension7RowsPerPage : _suspension30RowsPerPage;
    final page = is7Days ? _suspension7Page : _suspension30Page;
    final sortColumnIndex = is7Days ? _suspension7SortColumnIndex : _suspension30SortColumnIndex;
    final sortAscending = is7Days ? _suspension7SortAscending : _suspension30SortAscending;

    final filtered = _filteredSuspensions(rows, query);
    final sorted = _sortedSuspensions(filtered, sortColumnIndex, sortAscending);
    final safePage = _safePage(
      total: sorted.length,
      page: page,
      rowsPerPage: rowsPerPage,
    );
    final paged = _paginateRows(
      rows: sorted,
      page: safePage,
      rowsPerPage: rowsPerPage,
    );

    return _compactSection(
      title: title,
      child: Column(
        children: [
          _buildSearchAndPagingBar(
            hint: 'Search suspension rows',
            query: query,
            rowsPerPage: rowsPerPage,
            exportEnabled: sorted.isNotEmpty,
            onExportTap: () => _exportSuspensionsToExcel(title: title, rows: sorted),
            onQueryChanged: (v) => setState(() {
              if (is7Days) {
                _suspension7Query = v;
                _suspension7Page = 0;
              } else {
                _suspension30Query = v;
                _suspension30Page = 0;
              }
            }),
            onRowsPerPageChanged: (v) => setState(() {
              if (is7Days) {
                _suspension7RowsPerPage = v;
                _suspension7Page = 0;
              } else {
                _suspension30RowsPerPage = v;
                _suspension30Page = 0;
              }
            }),
          ),
          const SizedBox(height: 8),
          if (sorted.isEmpty)
            _emptyHint('No upcoming suspensions in next ${is7Days ? 7 : 30} days.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortColumnIndex: sortColumnIndex,
                sortAscending: sortAscending,
                headingRowHeight: 34,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 36,
                horizontalMargin: 10,
                columnSpacing: 14,
                columns: [
                  const DataColumn(label: Text('No')),
                  DataColumn(
                    label: const Text('Type'),
                    onSort: (i, asc) => setState(() {
                      if (is7Days) {
                        _suspension7SortColumnIndex = i;
                        _suspension7SortAscending = asc;
                      } else {
                        _suspension30SortColumnIndex = i;
                        _suspension30SortAscending = asc;
                      }
                    }),
                  ),
                  DataColumn(
                    label: const Text('Name'),
                    onSort: (i, asc) => setState(() {
                      if (is7Days) {
                        _suspension7SortColumnIndex = i;
                        _suspension7SortAscending = asc;
                      } else {
                        _suspension30SortColumnIndex = i;
                        _suspension30SortAscending = asc;
                      }
                    }),
                  ),
                  DataColumn(
                    label: const Text('Number'),
                    onSort: (i, asc) => setState(() {
                      if (is7Days) {
                        _suspension7SortColumnIndex = i;
                        _suspension7SortAscending = asc;
                      } else {
                        _suspension30SortColumnIndex = i;
                        _suspension30SortAscending = asc;
                      }
                    }),
                  ),
                  DataColumn(
                    label: const Text('Current Adds'),
                    numeric: true,
                    onSort: (i, asc) => setState(() {
                      if (is7Days) {
                        _suspension7SortColumnIndex = i;
                        _suspension7SortAscending = asc;
                      } else {
                        _suspension30SortColumnIndex = i;
                        _suspension30SortAscending = asc;
                      }
                    }),
                  ),
                  DataColumn(
                    label: const Text('Valid Till'),
                    onSort: (i, asc) => setState(() {
                      if (is7Days) {
                        _suspension7SortColumnIndex = i;
                        _suspension7SortAscending = asc;
                      } else {
                        _suspension30SortColumnIndex = i;
                        _suspension30SortAscending = asc;
                      }
                    }),
                  ),
                  DataColumn(
                    label: const Text('Days'),
                    numeric: true,
                    onSort: (i, asc) => setState(() {
                      if (is7Days) {
                        _suspension7SortColumnIndex = i;
                        _suspension7SortAscending = asc;
                      } else {
                        _suspension30SortColumnIndex = i;
                        _suspension30SortAscending = asc;
                      }
                    }),
                  ),
                ],
                rows: [
                  for (int i = 0; i < paged.length; i++)
                    DataRow(
                      cells: [
                        DataCell(
                          _tableText(
                            '${(safePage * rowsPerPage) + i + 1}',
                          ),
                        ),
                        DataCell(_tableText(_shortType(paged[i]['userType']))),
                        DataCell(
                          _tableText(paged[i]['name']?.toString() ?? '-'),
                        ),
                        DataCell(
                          _tableText(paged[i]['phone']?.toString() ?? '-'),
                        ),
                        DataCell(
                          _tableText(
                            (paged[i]['currentAdds'] ?? 0).toString(),
                            alignRight: true,
                          ),
                        ),
                        DataCell(
                          _tableText(
                            _formatDate(paged[i]['validTill'] as DateTime?),
                          ),
                        ),
                        DataCell(
                          _tableText(
                            (paged[i]['daysLeft'] ?? 0).toString(),
                            alignRight: true,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          _buildPager(
            total: sorted.length,
            page: safePage,
            rowsPerPage: rowsPerPage,
            onPrevious: () => setState(() {
              if (is7Days) {
                _suspension7Page--;
              } else {
                _suspension30Page--;
              }
            }),
            onNext: () => setState(() {
              if (is7Days) {
                _suspension7Page++;
              } else {
                _suspension30Page++;
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTable({
    required String title,
    required List<Map<String, dynamic>> rows,
  }) {
    final is7Days = title.startsWith('7 ');
    final query = is7Days ? _payment7Query : _payment30Query;
    final rowsPerPage = is7Days ? _payment7RowsPerPage : _payment30RowsPerPage;
    final page = is7Days ? _payment7Page : _payment30Page;
    final sortColumnIndex = is7Days
        ? _payment7SortColumnIndex
        : _payment30SortColumnIndex;
    final sortAscending = is7Days
        ? _payment7SortAscending
        : _payment30SortAscending;

    final filtered = _filteredPayments(rows, query);
    final sorted = _sortedPayments(filtered, sortColumnIndex, sortAscending);
    final safePage = _safePage(
      total: sorted.length,
      page: page,
      rowsPerPage: rowsPerPage,
    );
    final paged = _paginateRows(
      rows: sorted,
      page: safePage,
      rowsPerPage: rowsPerPage,
    );

    return _compactSection(
      title: title,
      child: Column(
        children: [
          _buildSearchAndPagingBar(
            hint: 'Search payment rows',
            query: query,
            rowsPerPage: rowsPerPage,
            exportEnabled: sorted.isNotEmpty,
            onExportTap: () => _exportPaymentsToExcel(title: title, rows: sorted),
            onQueryChanged: (v) => setState(() {
              if (is7Days) {
                _payment7Query = v;
                _payment7Page = 0;
              } else {
                _payment30Query = v;
                _payment30Page = 0;
              }
            }),
            onRowsPerPageChanged: (v) => setState(() {
              if (is7Days) {
                _payment7RowsPerPage = v;
                _payment7Page = 0;
              } else {
                _payment30RowsPerPage = v;
                _payment30Page = 0;
              }
            }),
          ),
          const SizedBox(height: 8),
          if (sorted.isEmpty)
            _emptyHint('No payment records found.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortColumnIndex: sortColumnIndex,
                sortAscending: sortAscending,
                headingRowHeight: 34,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 36,
                horizontalMargin: 10,
                columnSpacing: 14,
                columns: [
                  const DataColumn(label: Text('No')),
                  DataColumn(
                    label: const Text('Name'),
                    onSort: (i, asc) => setState(() {
                      if (is7Days) {
                        _payment7SortColumnIndex = i;
                        _payment7SortAscending = asc;
                      } else {
                        _payment30SortColumnIndex = i;
                        _payment30SortAscending = asc;
                      }
                    }),
                  ),
                  DataColumn(
                    label: const Text('Number'),
                    onSort: (i, asc) => setState(() {
                      if (is7Days) {
                        _payment7SortColumnIndex = i;
                        _payment7SortAscending = asc;
                      } else {
                        _payment30SortColumnIndex = i;
                        _payment30SortAscending = asc;
                      }
                    }),
                  ),
                  DataColumn(
                    label: const Text('Transaction No'),
                    onSort: (i, asc) => setState(() {
                      if (is7Days) {
                        _payment7SortColumnIndex = i;
                        _payment7SortAscending = asc;
                      } else {
                        _payment30SortColumnIndex = i;
                        _payment30SortAscending = asc;
                      }
                    }),
                  ),
                  DataColumn(
                    label: const Text('Payment Date'),
                    onSort: (i, asc) => setState(() {
                      if (is7Days) {
                        _payment7SortColumnIndex = i;
                        _payment7SortAscending = asc;
                      } else {
                        _payment30SortColumnIndex = i;
                        _payment30SortAscending = asc;
                      }
                    }),
                  ),
                  DataColumn(
                    label: const Text('Amount'),
                    numeric: true,
                    onSort: (i, asc) => setState(() {
                      if (is7Days) {
                        _payment7SortColumnIndex = i;
                        _payment7SortAscending = asc;
                      } else {
                        _payment30SortColumnIndex = i;
                        _payment30SortAscending = asc;
                      }
                    }),
                  ),
                  DataColumn(
                    label: const Text('Validity Days'),
                    numeric: true,
                    onSort: (i, asc) => setState(() {
                      if (is7Days) {
                        _payment7SortColumnIndex = i;
                        _payment7SortAscending = asc;
                      } else {
                        _payment30SortColumnIndex = i;
                        _payment30SortAscending = asc;
                      }
                    }),
                  ),
                  DataColumn(
                    label: const Text('Validity Till'),
                    onSort: (i, asc) => setState(() {
                      if (is7Days) {
                        _payment7SortColumnIndex = i;
                        _payment7SortAscending = asc;
                      } else {
                        _payment30SortColumnIndex = i;
                        _payment30SortAscending = asc;
                      }
                    }),
                  ),
                ],
                rows: [
                  for (int i = 0; i < paged.length; i++)
                    DataRow(
                      cells: [
                        DataCell(
                          _tableText('${(safePage * rowsPerPage) + i + 1}'),
                        ),
                        DataCell(
                          _tableText(paged[i]['name']?.toString() ?? '-'),
                        ),
                        DataCell(
                          _tableText(paged[i]['phone']?.toString() ?? '-'),
                        ),
                        DataCell(
                          _tableText(paged[i]['paymentRef']?.toString() ?? '-'),
                        ),
                        DataCell(
                          _tableText(
                            _formatDate(paged[i]['paymentDate'] as DateTime?),
                          ),
                        ),
                        DataCell(
                          _tableText(
                            _formatAmount(paged[i]['amount']),
                            alignRight: true,
                          ),
                        ),
                        DataCell(
                          _tableText(
                            (paged[i]['validityDays'] ?? 0).toString(),
                            alignRight: true,
                          ),
                        ),
                        DataCell(
                          _tableText(
                            _formatDate(paged[i]['endsAt'] as DateTime?),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          _buildPager(
            total: sorted.length,
            page: safePage,
            rowsPerPage: rowsPerPage,
            onPrevious: () => setState(() {
              if (is7Days) {
                _payment7Page--;
              } else {
                _payment30Page--;
              }
            }),
            onNext: () => setState(() {
              if (is7Days) {
                _payment7Page++;
              } else {
                _payment30Page++;
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _compactSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Future<void> _exportSuspensionsToExcel({
    required String title,
    required List<Map<String, dynamic>> rows,
  }) async {
    final excel = excel_pkg.Excel.createExcel();
    final sheetName = _safeSheetName(title);
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    sheet.appendRow([
      excel_pkg.TextCellValue('No'),
      excel_pkg.TextCellValue('Type'),
      excel_pkg.TextCellValue('Name'),
      excel_pkg.TextCellValue('Number'),
      excel_pkg.TextCellValue('Current Adds'),
      excel_pkg.TextCellValue('Valid Till'),
      excel_pkg.TextCellValue('Days'),
    ]);

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      sheet.appendRow([
        excel_pkg.IntCellValue(i + 1),
        excel_pkg.TextCellValue(_shortType(row['userType'])),
        excel_pkg.TextCellValue(row['name']?.toString() ?? '-'),
        excel_pkg.TextCellValue(row['phone']?.toString() ?? '-'),
        excel_pkg.IntCellValue((row['currentAdds'] as num?)?.toInt() ?? 0),
        excel_pkg.TextCellValue(_formatDate(row['validTill'] as DateTime?)),
        excel_pkg.IntCellValue((row['daysLeft'] as num?)?.toInt() ?? 0),
      ]);
    }

    await _shareExcelFile(
      excel: excel,
      fileName: _safeFileName(title),
      successMessage: '$title exported.',
    );
  }

  Future<void> _exportPaymentsToExcel({
    required String title,
    required List<Map<String, dynamic>> rows,
  }) async {
    final excel = excel_pkg.Excel.createExcel();
    final sheetName = _safeSheetName(title);
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    sheet.appendRow([
      excel_pkg.TextCellValue('No'),
      excel_pkg.TextCellValue('Name'),
      excel_pkg.TextCellValue('Number'),
      excel_pkg.TextCellValue('Transaction No'),
      excel_pkg.TextCellValue('Payment Date'),
      excel_pkg.TextCellValue('Amount'),
      excel_pkg.TextCellValue('Validity Days'),
      excel_pkg.TextCellValue('Validity Till'),
    ]);

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      sheet.appendRow([
        excel_pkg.IntCellValue(i + 1),
        excel_pkg.TextCellValue(row['name']?.toString() ?? '-'),
        excel_pkg.TextCellValue(row['phone']?.toString() ?? '-'),
        excel_pkg.TextCellValue(row['paymentRef']?.toString() ?? '-'),
        excel_pkg.TextCellValue(_formatDate(row['paymentDate'] as DateTime?)),
        excel_pkg.TextCellValue(_formatAmount(row['amount'])),
        excel_pkg.IntCellValue((row['validityDays'] as num?)?.toInt() ?? 0),
        excel_pkg.TextCellValue(_formatDate(row['endsAt'] as DateTime?)),
      ]);
    }

    await _shareExcelFile(
      excel: excel,
      fileName: _safeFileName(title),
      successMessage: '$title exported.',
    );
  }

  Future<void> _shareExcelFile({
    required excel_pkg.Excel excel,
    required String fileName,
    required String successMessage,
  }) async {
    try {
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to generate Excel file.');
      final fileBytes = Uint8List.fromList(bytes);
      final tempFile = File('${Directory.systemTemp.path}/$fileName.xlsx');
      await tempFile.writeAsBytes(fileBytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              tempFile.path,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel export failed: $e')),
      );
    }
  }

  String _safeSheetName(String title) {
    final cleaned = title.replaceAll(RegExp(r'[\\/*?:\[\]]'), '').trim();
    if (cleaned.isEmpty) return 'Sheet1';
    return cleaned.length > 31 ? cleaned.substring(0, 31) : cleaned;
  }

  String _safeFileName(String title) {
    String shortName = 'Report';
    if (title.contains('7 Days') && title.contains('Suspension')) {
      shortName = '7D_Suspensions';
    } else if (title.contains('30 Days') && title.contains('Suspension')) {
      shortName = '30D_Suspensions';
    } else if (title.contains('7 Days') && title.contains('Payment')) {
      shortName = '7D_Payments';
    } else if (title.contains('30 Days') && title.contains('Payment')) {
      shortName = '30D_Payments';
    } else {
      shortName = title
          .replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '')
          .trim()
          .replaceAll(' ', '_');
      if (shortName.isEmpty) shortName = 'Report';
    }

    return 'OMD_$shortName';
  }

  Widget _tableText(String value, {bool alignRight = false}) {
    return SizedBox(
      width: alignRight ? 70 : null,
      child: Text(
        value,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
        ),
      ),
    );
  }

  Widget _buildSearchAndPagingBar({
    required String hint,
    required String query,
    required int rowsPerPage,
    required bool exportEnabled,
    required VoidCallback onExportTap,
    required ValueChanged<String> onQueryChanged,
    required ValueChanged<int> onRowsPerPageChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 34,
            child: TextFormField(
              initialValue: query,
              onChanged: onQueryChanged,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.iosSecondaryLabel,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 16),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                filled: true,
                fillColor: AppColors.offWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.30),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: exportEnabled
                ? const Color(0xFFE8F5E9)
                : AppColors.offWhite,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: exportEnabled
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.25)
                  : AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: IconButton(
            onPressed: exportEnabled ? onExportTap : null,
            tooltip: 'Download Excel',
            padding: EdgeInsets.zero,
            icon: FaIcon(
              FontAwesomeIcons.fileExcel,
              size: 15,
              color: exportEnabled
                  ? const Color(0xFF1B5E20)
                  : AppColors.iosSecondaryLabel,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: rowsPerPage,
              iconSize: 16,
              borderRadius: BorderRadius.circular(10),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
              items: const [5, 10, 20, 50]
                  .map(
                    (e) => DropdownMenuItem<int>(
                      value: e,
                      child: Text('$e / page'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onRowsPerPageChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPager({
    required int total,
    required int page,
    required int rowsPerPage,
    required VoidCallback onPrevious,
    required VoidCallback onNext,
  }) {
    final pageCount = (total / rowsPerPage).ceil();
    final maxPage = pageCount == 0 ? 0 : pageCount - 1;
    final safePage = page.clamp(0, maxPage);
    final start = total == 0 ? 0 : (safePage * rowsPerPage) + 1;
    final end = total == 0
        ? 0
        : ((safePage * rowsPerPage) + rowsPerPage).clamp(0, total);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(
            '$start-$end of $total',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.darkGray,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: safePage > 0 ? onPrevious : null,
            icon: const Icon(Icons.chevron_left_rounded),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: 'Previous page',
          ),
          Text(
            '${safePage + 1}/${pageCount == 0 ? 1 : pageCount}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.darkGray,
            ),
          ),
          IconButton(
            onPressed: safePage < maxPage ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.iosSecondaryLabel,
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.error,
        ),
      ),
    );
  }

  String _shortType(dynamic type) {
    final value = (type?.toString() ?? '').toLowerCase();
    if (value == 'broker') return 'Broker';
    if (value == 'builder' || value == 'developer') return 'Builder';
    return '-';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd-MMM').format(date.toLocal());
  }

  String _formatAmount(dynamic amount) {
    final val = double.tryParse(amount?.toString() ?? '') ?? 0;
    if (val % 1 == 0) return val.toInt().toString();
    return val.toStringAsFixed(2);
  }

  List<Map<String, dynamic>> _filteredSuspensions(
    List<Map<String, dynamic>> rows,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<Map<String, dynamic>>.from(rows);
    return rows.where((row) {
      final haystack = [
        _shortType(row['userType']),
        row['name']?.toString() ?? '',
        row['phone']?.toString() ?? '',
        row['currentAdds']?.toString() ?? '',
        row['daysLeft']?.toString() ?? '',
        _formatDate(row['validTill'] as DateTime?),
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> _sortedSuspensions(
    List<Map<String, dynamic>> rows,
    int? sortColumnIndex,
    bool ascending,
  ) {
    final sorted = List<Map<String, dynamic>>.from(rows);
    final col = sortColumnIndex;
    if (col == null) return sorted;

    int compare(Map<String, dynamic> a, Map<String, dynamic> b) {
      switch (col) {
        case 1:
          return _shortType(a['userType']).compareTo(_shortType(b['userType']));
        case 2:
          return (a['name']?.toString() ?? '').compareTo(
            b['name']?.toString() ?? '',
          );
        case 3:
          return (a['phone']?.toString() ?? '').compareTo(
            b['phone']?.toString() ?? '',
          );
        case 4:
          return (a['currentAdds'] ?? 0).compareTo(b['currentAdds'] ?? 0);
        case 5:
          return (a['validTill'] as DateTime? ??
                  DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                b['validTill'] as DateTime? ??
                    DateTime.fromMillisecondsSinceEpoch(0),
              );
        case 6:
          return (a['daysLeft'] ?? 0).compareTo(b['daysLeft'] ?? 0);
        default:
          return 0;
      }
    }

    sorted.sort(compare);
    if (!ascending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  List<Map<String, dynamic>> _filteredPayments(
    List<Map<String, dynamic>> rows,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<Map<String, dynamic>>.from(rows);
    return rows.where((row) {
      final haystack = [
        row['name']?.toString() ?? '',
        row['phone']?.toString() ?? '',
        row['paymentRef']?.toString() ?? '',
        _formatDate(row['paymentDate'] as DateTime?),
        _formatDate(row['endsAt'] as DateTime?),
        _formatAmount(row['amount']),
        row['validityDays']?.toString() ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> _sortedPayments(
    List<Map<String, dynamic>> rows,
    int? sortColumnIndex,
    bool ascending,
  ) {
    final sorted = List<Map<String, dynamic>>.from(rows);
    if (sortColumnIndex == null) return sorted;

    int compare(Map<String, dynamic> a, Map<String, dynamic> b) {
      switch (sortColumnIndex) {
        case 1:
          return (a['name']?.toString() ?? '').compareTo(
            b['name']?.toString() ?? '',
          );
        case 2:
          return (a['phone']?.toString() ?? '').compareTo(
            b['phone']?.toString() ?? '',
          );
        case 3:
          return (a['paymentRef']?.toString() ?? '').compareTo(
            b['paymentRef']?.toString() ?? '',
          );
        case 4:
          return (a['paymentDate'] as DateTime? ??
                  DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                b['paymentDate'] as DateTime? ??
                    DateTime.fromMillisecondsSinceEpoch(0),
              );
        case 5:
          return (double.tryParse(a['amount']?.toString() ?? '') ?? 0)
              .compareTo(double.tryParse(b['amount']?.toString() ?? '') ?? 0);
        case 6:
          return (a['validityDays'] ?? 0).compareTo(b['validityDays'] ?? 0);
        case 7:
          return (a['endsAt'] as DateTime? ??
                  DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                b['endsAt'] as DateTime? ??
                    DateTime.fromMillisecondsSinceEpoch(0),
              );
        default:
          return 0;
      }
    }

    sorted.sort(compare);
    if (!ascending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  List<Map<String, dynamic>> _paginateRows({
    required List<Map<String, dynamic>> rows,
    required int page,
    required int rowsPerPage,
  }) {
    if (rows.isEmpty) return const [];
    final maxPage = (rows.length - 1) ~/ rowsPerPage;
    final safePage = page.clamp(0, maxPage);
    final start = safePage * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, rows.length);
    return rows.sublist(start, end);
  }

  int _safePage({
    required int total,
    required int page,
    required int rowsPerPage,
  }) {
    if (total == 0) return 0;
    final maxPage = (total - 1) ~/ rowsPerPage;
    return page.clamp(0, maxPage);
  }
}

class _OverviewCardData {
  final String title;
  final int value;
  final Color color;

  const _OverviewCardData({
    required this.title,
    required this.value,
    required this.color,
  });
}
