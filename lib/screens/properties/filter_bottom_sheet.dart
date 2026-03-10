import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../widgets/gradient_button.dart';

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

  final TextEditingController _areaCtrl = TextEditingController();
  final TextEditingController _societyCtrl = TextEditingController();
  final TextEditingController _minPriceCtrl = TextEditingController();
  final TextEditingController _maxPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = PropertyFilter(
      city: 'Pune',
      area: widget.currentFilter.area,
      society: widget.currentFilter.society,
      category: widget.currentFilter.category,
      listingType: widget.currentFilter.listingType,
      floorCategory: widget.currentFilter.floorCategory,
      flatType: widget.currentFilter.flatType,
      parking: widget.currentFilter.parking,
      userTypeFilter: widget.currentFilter.userTypeFilter,
      minPrice: widget.currentFilter.minPrice,
      maxPrice: widget.currentFilter.maxPrice,
    );
    _areaCtrl.text = _filter.area ?? '';
    _societyCtrl.text = _filter.society ?? '';
    _minPriceCtrl.text = _filter.minPrice?.toStringAsFixed(0) ?? '';
    _maxPriceCtrl.text = _filter.maxPrice?.toStringAsFixed(0) ?? '';
  }

  void _applyFilters() {
    _filter.city = 'Pune';
    _filter.area = _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text.trim();
    _filter.society = _societyCtrl.text.trim().isEmpty ? null : _societyCtrl.text.trim();
    _filter.minPrice = double.tryParse(_minPriceCtrl.text.trim());
    _filter.maxPrice = double.tryParse(_maxPriceCtrl.text.trim());
    widget.onApply(_filter);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _filter = PropertyFilter(city: 'Pune');
      _areaCtrl.clear();
      _societyCtrl.clear();
      _minPriceCtrl.clear();
      _maxPriceCtrl.clear();
    });
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.charcoal),
      ),
    );
  }

  Widget _buildChipSelector<T>({
    required List<T> items,
    required T? selectedItem,
    required String Function(T) labelBuilder,
    required void Function(T?) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItem == item;
        return ChoiceChip(
          label: Text(labelBuilder(item)),
          selected: isSelected,
          onSelected: (selected) => onSelected(selected ? item : null),
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.lightGray,
          labelStyle: TextStyle(color: isSelected ? AppColors.white : AppColors.charcoal, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.lightGray, width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filters', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoal)),
                    TextButton(
                      onPressed: _clearFilters,
                      child: Text('Reset', style: GoogleFonts.plusJakartaSans(color: AppColors.error, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Location Filters
                    _buildSectionTitle('Location'),
                    // City is fixed to Pune
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.offWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_city, size: 18, color: AppColors.mediumGray),
                          const SizedBox(width: 8),
                          Text('Pune', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Area autocomplete search
                    _buildAreaAutocomplete(),
                    const SizedBox(height: 12),
                    _buildTextField(_societyCtrl, 'Building / Society Name'),

                    // Category
                    _buildSectionTitle('Property Category'),
                    _buildChipSelector<PropertyCategory>(
                      items: PropertyCategory.values.where((c) => c != PropertyCategory.plot).toList(),
                      selectedItem: _filter.category,
                      labelBuilder: (c) => c.value,
                      onSelected: (val) => setState(() => _filter.category = val),
                    ),

                    // Listing Type
                    _buildSectionTitle('Listing Type'),
                    _buildChipSelector<ListingType>(
                      items: ListingType.values,
                      selectedItem: _filter.listingType,
                      labelBuilder: (t) => t.value,
                      onSelected: (val) => setState(() => _filter.listingType = val),
                    ),

                    // BHK
                    _buildSectionTitle('BHK Configuration'),
                    _buildChipSelector<String>(
                      items: ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'Bungalow', 'Shop', 'Office'],
                      selectedItem: _filter.flatType,
                      labelBuilder: (t) => t,
                      onSelected: (val) => setState(() => _filter.flatType = val),
                    ),

                    // Floor
                    _buildSectionTitle('Floor Category'),
                    _buildChipSelector<FloorCategory>(
                      items: FloorCategory.values,
                      selectedItem: _filter.floorCategory,
                      labelBuilder: (t) => t.value,
                      onSelected: (val) => setState(() => _filter.floorCategory = val),
                    ),

                    // Parking
                    _buildSectionTitle('Parking'),
                    _buildChipSelector<String>(
                      items: ['Open', 'Covered', 'Not available'],
                      selectedItem: _filter.parking,
                      labelBuilder: (t) => t,
                      onSelected: (val) => setState(() => _filter.parking = val),
                    ),

                    // Price Range
                    _buildSectionTitle('Price Range'),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_minPriceCtrl, 'Min Price', isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_maxPriceCtrl, 'Max Price', isNumber: true)),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10),
                  ],
                ),
                child: GradientButton(
                  label: 'Apply Filters',
                  onPressed: _applyFilters,
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
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.length < 2) {
          return const Iterable<String>.empty();
        }
        final results = await PropertyService.searchCityAreas(textEditingValue.text);
        return results;
      },
      onSelected: (String selection) {
        _areaCtrl.text = selection;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        controller.addListener(() {
          _areaCtrl.text = controller.text;
        });
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Search Area (type 2+ letters)',
            prefixIcon: const Icon(Icons.search, color: AppColors.mediumGray),
            filled: true,
            fillColor: AppColors.offWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.accent),
                    title: Text(option, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.offWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
