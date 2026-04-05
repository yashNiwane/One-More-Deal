import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';

class FilterBottomSheet extends StatefulWidget {
  final PropertyFilter currentFilter;
  final ValueChanged<PropertyFilter> onApply;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late PropertyFilter _filter;
  List<Map<String, dynamic>> _allBrokers = [];
  bool _isLoadingBrokers = true;
  String _brokerSearchQuery = '';

  final TextEditingController _areaCtrl = TextEditingController();
  final TextEditingController _societyCtrl = TextEditingController();
  final TextEditingController _minPriceCtrl = TextEditingController();
  final TextEditingController _maxPriceCtrl = TextEditingController();

  bool _isPropertyCategoryExpanded = false;
  bool _isSubcategoryExpanded = false;
  bool _isListingTypeExpanded = false;
  bool _isAdvancedFiltersExpanded = false;

  @override
  void initState() {
    super.initState();
    final baseCity = (widget.currentFilter.city?.trim().isNotEmpty ?? false)
        ? widget.currentFilter.city!.trim()
        : 'Pune';
    _filter = PropertyFilter(
      city: baseCity,
      area: widget.currentFilter.area,
      society: widget.currentFilter.society,
      category: widget.currentFilter.category,
      listingType: widget.currentFilter.listingType,
      floorCategory: widget.currentFilter.floorCategory,
      flatType: widget.currentFilter.flatType,
      furnishingStatus: widget.currentFilter.furnishingStatus,
      userTypeFilter: widget.currentFilter.userTypeFilter,
      minPrice: widget.currentFilter.minPrice,
      maxPrice: widget.currentFilter.maxPrice,
      brokerIds: widget.currentFilter.brokerIds != null
          ? List.from(widget.currentFilter.brokerIds!)
          : null,
    );
    _areaCtrl.text = _filter.area ?? '';
    _societyCtrl.text = _filter.society ?? '';
    _minPriceCtrl.text = _filter.minPrice?.toStringAsFixed(0) ?? '';
    _maxPriceCtrl.text = _filter.maxPrice?.toStringAsFixed(0) ?? '';
    _loadBrokers();
  }

  Future<void> _loadBrokers() async {
    try {
      final brokers = await PropertyService.getAllBrokers();
      if (mounted) {
        setState(() {
          _allBrokers = brokers;
          _isLoadingBrokers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBrokers = false);
    }
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _societyCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    _filter.city = (_filter.city?.trim().isNotEmpty ?? false)
        ? _filter.city!.trim()
        : 'Pune';
    _filter.area = _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text.trim();
    _filter.society = _societyCtrl.text.trim().isEmpty
        ? null
        : _societyCtrl.text.trim();
    _filter.minPrice = double.tryParse(_minPriceCtrl.text.trim());
    _filter.maxPrice = double.tryParse(_maxPriceCtrl.text.trim());
    widget.onApply(_filter);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _filter = PropertyFilter(
        city: (widget.currentFilter.city?.trim().isNotEmpty ?? false)
            ? widget.currentFilter.city!.trim()
            : 'Pune',
      );
      _areaCtrl.clear();
      _societyCtrl.clear();
      _minPriceCtrl.clear();
      _maxPriceCtrl.clear();
    });
  }

  void _showBrokerSelectionDialog() {
    // Fill search field with existing IDs
    if (_filter.brokerIds != null && _filter.brokerIds!.isNotEmpty) {
      final codes = _filter.brokerIds!.map((id) {
        final b = _allBrokers.cast<Map<String, dynamic>?>().firstWhere(
          (b) => b?['id'] == id,
          orElse: () => null,
        );
        return ((b?['code'] as String?)?.isNotEmpty == true) 
            ? b!['code'] as String 
            : id.toString();
      }).toList();
      _brokerSearchQuery = codes.join(' ');
    } else {
      _brokerSearchQuery = '';
    }

    final TextEditingController textCtrl = TextEditingController(text: _brokerSearchQuery);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Brokers',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textCtrl,
                      onChanged: (val) {
                        _brokerSearchQuery = val;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter IDs e.g. BA1 BA2 BA20...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You can enter multiple broker codes separated by space or comma.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.iosSecondaryLabel),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.iosSystemBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          final query = _brokerSearchQuery.trim().toLowerCase();
                          if (query.isNotEmpty) {
                            // Split by space or comma
                            final parts = query.split(RegExp(r'[\s,]+'));
                            
                            List<int> foundIds = [];
                            for (var part in parts) {
                              if (part.isEmpty) continue;
                              final normalizedPart = part.replaceAll('-', '');
                              
                              final exactMatch = _allBrokers.where((b) {
                                final name = ((b['name'] as String?) ?? '').toLowerCase();
                                final code = ((b['code'] as String?) ?? '').toLowerCase();
                                final normalizedCode = code.replaceAll('-', '');
                                return name == part || normalizedCode == normalizedPart;
                              }).toList();
                              
                              if (exactMatch.isNotEmpty) {
                                foundIds.addAll(exactMatch.map((m) => m['id'] as int));
                              } else {
                                final parsedId = int.tryParse(part);
                                if (parsedId != null) {
                                  foundIds.add(parsedId);
                                }
                              }
                            }
                            
                            _filter.brokerIds = foundIds.isNotEmpty ? foundIds.toSet().toList() : null;
                          } else {
                            _filter.brokerIds = null;
                          }
                          
                          _brokerSearchQuery = '';
                          Navigator.pop(context);
                          setState(() {}); // refresh the bottom sheet text
                        },
                        child: Text(
                          'Done',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _brokerSearchQuery = '';
    });
  }

  // ── helpers ──

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 2),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.iosSecondaryLabel,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    String? currentValue,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: title == 'ADVANCED FILTERS' ? AppColors.iosSystemBlue : AppColors.iosSecondaryLabel,
                    letterSpacing: 0.6,
                  ),
                ),
                Row(
                  children: [
                    if (currentValue != null && currentValue.isNotEmpty) ...[
                      Text(
                        currentValue,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.iosSystemBlue,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: title == 'ADVANCED FILTERS' ? AppColors.iosSystemBlue : AppColors.iosSecondaryLabel,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: child,
          ),
      ],
    );
  }

  Widget _chipGroup<T>({
    required List<T> items,
    required T? selected,
    required String Function(T) label,
    required void Function(T?) onTap,
    Color? activeColor,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final sel = selected == item;
        final color = activeColor ?? AppColors.iosSystemBlue;
        return GestureDetector(
          onTap: () => onTap(sel ? null : item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? color : AppColors.iosCardBg,
              borderRadius: BorderRadius.circular(20),
              border: sel
                  ? null
                  : Border.all(
                      color: AppColors.iosSeparator.withValues(alpha: 0.5),
                    ),
            ),
            child: Text(
              label(item),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                color: sel ? AppColors.white : AppColors.charcoal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.charcoal),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: AppColors.iosTertiaryLabel,
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppColors.iosCardBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.iosSystemBlue, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isBroker =
        _filter.userTypeFilter == null ||
        _filter.userTypeFilter == UserTypeFilter.broker;
    bool isBuilder = _filter.userTypeFilter == UserTypeFilter.builder;

    bool isResi =
        _filter.category == null ||
        _filter.category == PropertyCategory.residential;
    bool isComm = _filter.category == PropertyCategory.commercial;
    bool isPlot = _filter.category == PropertyCategory.plot;

    List<String> bhkOptions = [];
    if (isBuilder) {
      bhkOptions = [
        '1 BHK',
        '2 BHK',
        '3 BHK',
        '4 BHK',
        'Bungalow',
        'Office Spaces',
        'Retail & Shops',
        'Industrial & Warehousing',
        'Co-working Spaces',
      ];
    } else if (isResi) {
      bhkOptions = ['1 RK', '1 BHK', '2 BHK', '3 BHK', '4 BHK', 'Bungalow'];
    } else if (isComm) {
      bhkOptions = [
        'Office Spaces',
        'Retail & Shops',
        'Industrial & Warehousing',
        'Co-working Spaces',
      ];
    }

    if (_filter.flatType != null && !bhkOptions.contains(_filter.flatType)) {
      _filter.flatType = null;
    }

    bool showSociety = !isPlot;
    bool showBhk = !isPlot && !isBuilder;
    bool showFloor = !isPlot && !isBuilder;
    bool showFurnishing = _filter.listingType == ListingType.rent;
    bool showListingType = isBroker;
    bool showSubcategory = isBroker;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.iosGroupedBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.iosSeparator,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Filter',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _clearFilters,
                      child: Text(
                        'Reset All',
                        style: GoogleFonts.inter(
                          color: AppColors.iosSystemBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 0.5,
                color: AppColors.iosSeparator.withValues(alpha: 0.4),
              ),

              // Scrollable filters
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 4,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [


                      // Advanced Filters (Collapsible Category, Subcategory, Listing Type) - MOVED TO TOP
                      _buildCollapsibleSection(
                        title: 'ADVANCED FILTERS',
                        currentValue: null,
                        isExpanded: _isAdvancedFiltersExpanded,
                        onToggle: () => setState(() => _isAdvancedFiltersExpanded = !_isAdvancedFiltersExpanded),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader('PROPERTY CATEGORY'),
                            _chipGroup<UserTypeFilter>(
                              items: UserTypeFilter.values,
                              selected: _filter.userTypeFilter ?? UserTypeFilter.broker,
                              label: (u) => u == UserTypeFilter.builder ? '🏗 Builder' : '🤝 Broker',
                              activeColor: (_filter.userTypeFilter ?? UserTypeFilter.broker) == UserTypeFilter.builder
                                  ? const Color(0xFFE69A1A)
                                  : AppColors.iosSystemBlue,
                              onTap: (val) {
                                setState(() {
                                  _filter.userTypeFilter = val ?? UserTypeFilter.broker;
                                  if (_filter.userTypeFilter == UserTypeFilter.builder) {
                                    _filter.category = null;
                                    _filter.listingType = null;
                                    _filter.floorCategory = null;
                                    _filter.brokerIds = null;
                                  }
                                });
                              },
                            ),
                            
                            if (showSubcategory) ...[
                              _sectionHeader('SUBCATEGORY'),
                              _chipGroup<PropertyCategory>(
                                items: [
                                  PropertyCategory.residential,
                                  PropertyCategory.commercial,
                                  PropertyCategory.plot,
                                ],
                                selected: _filter.category ?? PropertyCategory.residential,
                                label: (c) => c.value,
                                onTap: (val) {
                                  setState(() {
                                    _filter.category = val ?? PropertyCategory.residential;
                                    if (_filter.category == PropertyCategory.plot) {
                                      _filter.flatType = null;
                                      _filter.society = null;
                                      _filter.floorCategory = null;
                                      _societyCtrl.clear();
                                    }
                                  });
                                },
                              ),
                            ],

                            if (showListingType) ...[
                              _sectionHeader('LISTING TYPE'),
                              _chipGroup<ListingType>(
                                items: [ListingType.resale, ListingType.rent],
                                selected: _filter.listingType,
                                label: (t) => t.value,
                                onTap: (val) {
                                  setState(() {
                                    _filter.listingType = val;
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      // 3. Society / Building
                      if (showSociety) ...[
                        _sectionHeader('SOCIETY / BUILDING'),
                        _textField(_societyCtrl, 'e.g. Amanora, Marvel Brisa…'),
                      ],



                      // 6. BHK Config
                      if (showBhk && bhkOptions.isNotEmpty) ...[
                        _sectionHeader('BHK / CONFIGURATION'),
                        _chipGroup<String>(
                          items: bhkOptions,
                          selected: _filter.flatType,
                          label: (t) => t,
                          onTap: (val) =>
                              setState(() => _filter.flatType = val),
                        ),
                      ],

                      // 7. Floor
                      if (showFloor) ...[
                        _sectionHeader('FLOOR'),
                        _chipGroup<FloorCategory>(
                          items: FloorCategory.values,
                          selected: _filter.floorCategory,
                          label: (f) => f.value,
                          onTap: (val) =>
                              setState(() => _filter.floorCategory = val),
                        ),
                      ],

                      // 8. Furnishing Status
                      if (showFurnishing) ...[
                        _sectionHeader('FURNISHING STATUS'),
                        _chipGroup<String>(
                          items: const ['Full', 'Semi', 'Unfurnished'],
                          selected: _filter.furnishingStatus,
                          label: (t) => t,
                          onTap: (val) =>
                              setState(() => _filter.furnishingStatus = val),
                        ),
                      ],



                      // 10. Specific Brokers (moved to bottom)
                      if (isBroker) ...[
                        _sectionHeader('SPECIFIC BROKERS'),
                        GestureDetector(
                          onTap: _showBrokerSelectionDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.iosCardBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_search_rounded,
                                  size: 18,
                                  color: AppColors.iosSystemBlue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    (_filter.brokerIds?.isNotEmpty ?? false)
                                        ? '${_filter.brokerIds!.length} Brokers Selected'
                                        : 'Select Brokers',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight:
                                          (_filter.brokerIds?.isNotEmpty ??
                                              false)
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color:
                                          (_filter.brokerIds?.isNotEmpty ??
                                              false)
                                          ? AppColors.iosSystemBlue
                                          : AppColors.charcoal,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: AppColors.iosTertiaryLabel,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],




                    ],
                  ),
                ),
              ),

              // Apply button
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.iosGroupedBg,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.iosSeparator.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: GestureDetector(
                    onTap: _applyFilters,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.iosSystemBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Apply',
                        style: GoogleFonts.inter(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAreaAutocomplete() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _areaCtrl.text),
      optionsBuilder: (TextEditingValue val) async {
        if (val.text.length < 2) return const Iterable<String>.empty();
        return await PropertyService.searchCityAreas(val.text);
      },
      onSelected: (s) => _areaCtrl.text = s,
      fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
        ctrl.text = _areaCtrl.text;
        ctrl.addListener(() => _areaCtrl.text = ctrl.text);
        return TextField(
          controller: ctrl,
          focusNode: focusNode,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.charcoal),
          decoration: InputDecoration(
            hintText: 'Search area (2+ letters)',
            hintStyle: GoogleFonts.inter(
              color: AppColors.iosTertiaryLabel,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.iosSecondaryLabel,
              size: 18,
            ),
            filled: true,
            fillColor: AppColors.iosCardBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.iosSystemBlue,
                width: 1.5,
              ),
            ),
          ),
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final opt = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.iosSystemBlue,
                    ),
                    title: Text(opt, style: GoogleFonts.inter(fontSize: 14)),
                    onTap: () => onSelected(opt),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
