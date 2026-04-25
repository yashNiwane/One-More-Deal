import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../models/property_model.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';

class EditPropertyScreen extends StatefulWidget {
  final PropertyModel property;
  const EditPropertyScreen({super.key, required this.property});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late PropertyCategory _category;
  late ListingType _listingType;

  // Common
  final _cityCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _subareaCtrl = TextEditingController();
  final _societyCtrl = TextEditingController();

  // Non-builder property details
  final _generalAreaCtrl = TextEditingController();
  final _plotAreaCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();

  String _areaUnit = 'SqFt';
  String _selectedAreaType = 'Carpet Area';
  String? _selectedFlatBhk;
  int? _selectedFloor;
  String _selectedParking = 'Not available';
  String _selectedFurnishing = 'Unfurnished';
  String _selectedAvailableFor = 'Any';
  DateTime? _availabilityDate;

  // New/Builder possession date
  DateTime? _possessionDate;

  // Builder new-launch fields
  final _schemeCtrl = TextEditingController();
  final _reraCtrl = TextEditingController();
  final _landCtrl = TextEditingController();
  final _totalBuildingsCtrl = TextEditingController();
  final _amenitiesCtrl = TextEditingController();
  final _structureCtrl = TextEditingController();
  final _totalUnitsCtrl = TextEditingController();
  final _fosCtrl = TextEditingController();
  final _cpSlabPercentCtrl = TextEditingController();
  final List<_VariantData> _variants = [];

  static final RegExp _englishAsciiRegex = RegExp(r'^[\x00-\x7F]+$');

  bool get _isPlot => _listingType == ListingType.plot;
  bool get _isRent => _listingType == ListingType.rent;
  bool get _isNew =>
      _category == PropertyCategory.newProperty ||
      _listingType == ListingType.newLaunch;
  bool get _showAvailableFor =>
      _category == PropertyCategory.residential && _isRent;
  bool get _isBuilderUser =>
      AuthService.userType == 'Builder' || AuthService.userType == 'Developer';
  bool get _isBuilderNewLaunch =>
      _category == PropertyCategory.newProperty &&
      _listingType == ListingType.newLaunch;

  @override
  void initState() {
    super.initState();

    _category = widget.property.category;
    _listingType = widget.property.listingType;

    _cityCtrl.text = widget.property.city;
    _areaCtrl.text = widget.property.area;
    _subareaCtrl.text = widget.property.subarea ?? '';
    _societyCtrl.text = widget.property.societyName ?? '';

    _selectedFlatBhk = widget.property.flatType;
    _selectedFloor = widget.property.floorNumber;
    _selectedParking = widget.property.parking ?? 'Not available';
    _selectedFurnishing = widget.property.furnishingStatus ?? 'Unfurnished';
    _selectedAvailableFor = widget.property.availableFor ?? 'Any';

    _areaUnit = widget.property.areaUnit;
    _plotAreaCtrl.text =
        widget.property.areaValue != null ? '${widget.property.areaValue}' : '';

    if (widget.property.builtUpArea != null) {
      _selectedAreaType = 'Built-up Area';
      _generalAreaCtrl.text = '${widget.property.builtUpArea}';
    } else {
      _selectedAreaType = 'Carpet Area';
      _generalAreaCtrl.text =
          widget.property.carpetArea != null ? '${widget.property.carpetArea}' : '';
    }

    _priceCtrl.text =
        widget.property.price != null ? '${widget.property.price}' : '';
    _depositCtrl.text =
        widget.property.deposit != null ? '${widget.property.deposit}' : '';

    _possessionDate = widget.property.possessionDate;

    if (!_isNew && widget.property.availability != null) {
      try {
        _availabilityDate =
            DateFormat('dd MMM yyyy').parse(widget.property.availability!);
      } catch (_) {
        _availabilityDate = DateTime.now();
      }
    }

    if (_isBuilderNewLaunch) {
      _schemeCtrl.text = widget.property.societyName ?? '';
      _reraCtrl.text = widget.property.reraNo ?? '';
      _landCtrl.text =
          widget.property.areaValue != null ? '${widget.property.areaValue}' : '';
      _totalBuildingsCtrl.text = widget.property.totalBuildings?.toString() ?? '';
      _amenitiesCtrl.text = widget.property.amenitiesCount?.toString() ?? '';
      _structureCtrl.text = widget.property.buildingStructure ?? '';
      _totalUnitsCtrl.text = widget.property.totalUnits?.toString() ?? '';

      final existing = widget.property.variants ?? const [];
      Map<String, dynamic>? meta;
      final unitVariants = <Map<String, dynamic>>[];
      for (final v in existing) {
        if ((v['type'] ?? '').toString().toLowerCase() == 'meta') {
          meta = v;
        } else {
          unitVariants.add(v);
        }
      }

      final fosVal = meta?['fos'];
      final cpVal = meta?['cp_slab_percent'];
      if (fosVal != null) _fosCtrl.text = fosVal.toString();
      if (cpVal != null) _cpSlabPercentCtrl.text = cpVal.toString();

      if (unitVariants.isEmpty) {
        _variants.add(_VariantData());
      } else {
        for (final v in unitVariants) {
          final d = _VariantData();
          d.flatType = (v['flat_type'] as String?)?.trim().isEmpty == true
              ? null
              : v['flat_type'] as String?;
          d.carpetCtrl.text = v['carpet']?.toString() ?? '';
          d.agreementCtrl.text = v['agreement_cost']?.toString() ?? '';
          d.totalCostCtrl.text = v['total_cost']?.toString() ?? '';
          _variants.add(d);
        }
      }
    }
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    _subareaCtrl.dispose();
    _societyCtrl.dispose();
    _generalAreaCtrl.dispose();
    _plotAreaCtrl.dispose();
    _priceCtrl.dispose();
    _depositCtrl.dispose();

    _schemeCtrl.dispose();
    _reraCtrl.dispose();
    _landCtrl.dispose();
    _totalBuildingsCtrl.dispose();
    _amenitiesCtrl.dispose();
    _structureCtrl.dispose();
    _totalUnitsCtrl.dispose();
    _fosCtrl.dispose();
    _cpSlabPercentCtrl.dispose();
    for (final v in _variants) {
      v.dispose();
    }

    super.dispose();
  }

  Future<void> _pickPossessionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _possessionDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _possessionDate = picked);
  }

  Future<void> _pickAvailabilityDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _availabilityDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _availabilityDate = picked);
  }

  void _addVariant() {
    if (_variants.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 8 variants allowed'),
          backgroundColor: AppColors.iosDestructive,
        ),
      );
      return;
    }
    setState(() => _variants.add(_VariantData()));
  }

  void _removeVariant(int index) {
    if (_variants.length <= 1) return;
    setState(() {
      _variants[index].dispose();
      _variants.removeAt(index);
    });
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isBuilderNewLaunch && _possessionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select RERA Possession Date'),
          backgroundColor: AppColors.iosDestructive,
        ),
      );
      return;
    }

    if (_isBuilderNewLaunch && _variants.any((v) => v.flatType == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Flat Type for all variants'),
          backgroundColor: AppColors.iosDestructive,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final floorCat = PropertyModel.floorCategoryFromNumber(_selectedFloor);

      PropertyModel updatedProp;
      if (_isBuilderNewLaunch) {
        final variantsList = _variants
            .map(
              (v) => {
                'flat_type': v.flatType ?? '',
                'carpet': double.tryParse(v.carpetCtrl.text.trim()) ?? 0,
                'agreement_cost':
                    double.tryParse(v.agreementCtrl.text.trim()) ?? 0,
                'total_cost': double.tryParse(v.totalCostCtrl.text.trim()) ?? 0,
              },
            )
            .toList();

        final fos = double.tryParse(_fosCtrl.text.trim());
        final cpSlabPercent = double.tryParse(_cpSlabPercentCtrl.text.trim());
        if (fos != null || cpSlabPercent != null) {
          variantsList.add({
            'type': 'meta',
            if (fos != null) 'fos': fos,
            if (cpSlabPercent != null) 'cp_slab_percent': cpSlabPercent,
          });
        }

        updatedProp = PropertyModel(
          id: widget.property.id,
          userId: widget.property.userId,
          category: PropertyCategory.newProperty,
          listingType: ListingType.newLaunch,
          city: _cityCtrl.text.trim(),
          area: _areaCtrl.text.trim(),
          subarea: null,
          societyName: _schemeCtrl.text.trim(),
          flatType: null,
          areaValue: double.tryParse(_landCtrl.text.trim()),
          builtUpArea: null,
          carpetArea: null,
          areaUnit: 'Acre',
          floorNumber: null,
          floorCategory: null,
          price: null,
          deposit: null,
          availability: null,
          possessionDate: _possessionDate,
          parking: null,
          furnishingStatus: null,
          availableFor: null,
          reraNo: _reraCtrl.text.trim(),
          totalBuildings: int.tryParse(_totalBuildingsCtrl.text.trim()),
          amenitiesCount: int.tryParse(_amenitiesCtrl.text.trim()),
          buildingStructure: _structureCtrl.text.trim(),
          totalUnits: int.tryParse(_totalUnitsCtrl.text.trim()),
          isApproved: widget.property.isApproved,
          variants: variantsList,
          isVisible: widget.property.isVisible,
          postedAt: widget.property.postedAt,
          refreshedAt: widget.property.refreshedAt,
          autoDeleteAt: widget.property.autoDeleteAt,
          createdAt: widget.property.createdAt,
          posterName: widget.property.posterName,
          posterCode: widget.property.posterCode,
          posterCompany: widget.property.posterCompany,
          posterPhone: widget.property.posterPhone,
        );
      } else {
        final generalArea = double.tryParse(_generalAreaCtrl.text.trim());
        final plotArea = double.tryParse(_plotAreaCtrl.text.trim());

        updatedProp = PropertyModel(
          id: widget.property.id,
          userId: widget.property.userId,
          category: _category,
          listingType: _listingType,
          city: _cityCtrl.text.trim(),
          area: _areaCtrl.text.trim(),
          subarea: _subareaCtrl.text.trim().isEmpty
              ? null
              : _subareaCtrl.text.trim(),
          societyName: _isPlot ? null : _societyCtrl.text.trim(),
          flatType: _isPlot ? null : _selectedFlatBhk,
          areaValue: _isPlot ? plotArea : null,
          builtUpArea: _isPlot
              ? null
              : (_selectedAreaType == 'Built-up Area' ? generalArea : null),
          carpetArea: _isPlot
              ? null
              : (_selectedAreaType == 'Carpet Area' ? generalArea : null),
          areaUnit: _isPlot ? _areaUnit : 'SqFt',
          floorNumber: _isPlot || _isNew ? null : _selectedFloor,
          floorCategory: _isPlot || _isNew ? null : floorCat,
          price: double.tryParse(_priceCtrl.text.trim()),
          deposit: _isRent ? double.tryParse(_depositCtrl.text.trim()) : null,
          availability: _isNew
              ? null
              : (_availabilityDate != null
                  ? DateFormat('dd MMM yyyy').format(_availabilityDate!)
                  : null),
          possessionDate: _isNew ? _possessionDate : null,
          parking: _isPlot || _isNew ? null : _selectedParking,
          furnishingStatus: _isPlot || _isNew ? null : _selectedFurnishing,
          availableFor: _showAvailableFor ? _selectedAvailableFor : null,
          reraNo: widget.property.reraNo,
          totalBuildings: widget.property.totalBuildings,
          amenitiesCount: widget.property.amenitiesCount,
          buildingStructure: widget.property.buildingStructure,
          totalUnits: widget.property.totalUnits,
          isApproved: widget.property.isApproved,
          variants: widget.property.variants,
          isVisible: widget.property.isVisible,
          postedAt: widget.property.postedAt,
          refreshedAt: widget.property.refreshedAt,
          autoDeleteAt: widget.property.autoDeleteAt,
          createdAt: widget.property.createdAt,
          posterName: widget.property.posterName,
          posterCode: widget.property.posterCode,
          posterCompany: widget.property.posterCompany,
          posterPhone: widget.property.posterPhone,
        );
      }

      await PropertyService.updateProperty(updatedProp);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property updated'),
          backgroundColor: AppColors.iosSystemGreen,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: AppColors.iosDestructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, bottom: 8, top: 26),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.iosSecondaryLabel,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(
          Container(
            height: 0.5,
            color: AppColors.iosSeparator.withOpacity(0.3),
            margin: const EdgeInsets.only(left: 16),
          ),
        );
      }
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.iosCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildDropdownField<T>(
    String label,
    T? value,
    List<T> items,
    String Function(T) labelBuilder,
    void Function(T?)? onChanged, {
    String? Function(T?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.iosSecondaryLabel,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        items: items
            .map((t) => DropdownMenuItem(value: t, child: Text(labelBuilder(t))))
            .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController ctrl, {
    bool isNumber = false,
    String? hint,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : [FilteringTextInputFormatter.allow(RegExp(r'[\x00-\x7F]'))],
      style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.iosSecondaryLabel,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.iosTertiaryLabel,
          fontWeight: FontWeight.w400,
        ),
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (val) {
        final text = val?.trim() ?? '';
        if (!isOptional && text.isEmpty) return '$label is required';
        if (text.isEmpty) return null;
        if (isNumber && double.tryParse(text) == null) return 'Use English digits only';
        if (!isNumber && !_englishAsciiRegex.hasMatch(text)) {
          return 'Only English characters are allowed';
        }
        return null;
      },
    );
  }

  Widget _builderSection() {
    final flatOptions = const [
      '1 BHK',
      '1.5 BHK',
      '2 BHK',
      '2.5 BHK',
      '3 BHK',
      '3.5 BHK',
      '4 BHK',
      '4.5 BHK',
      '5 BHK',
      '5.5 BHK',
      '6 BHK',
      '7 BHK',
      'Bungalow',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('LOCATION'),
        _buildGroupedCard([
          _buildFormField('City', _cityCtrl),
          _buildFormField('Area / Locality', _areaCtrl),
        ]),

        _buildSectionHeader('PROJECT'),
        _buildGroupedCard([
          _buildFormField('Scheme / Project Name', _schemeCtrl),
          _buildFormField('RERA No', _reraCtrl),
          _buildFormField('Land Area', _landCtrl, isNumber: true, hint: 'e.g., 2.5'),
        ]),

        _buildSectionHeader('STATS'),
        _buildGroupedCard([
          _buildFormField('Total Buildings', _totalBuildingsCtrl, isNumber: true, isOptional: true),
          _buildFormField('Amenities Count', _amenitiesCtrl, isNumber: true, isOptional: true),
          _buildFormField('Building Structure', _structureCtrl, isOptional: true),
          _buildFormField('Total Units', _totalUnitsCtrl, isNumber: true, isOptional: true),
        ]),

        _buildSectionHeader('POSSESSION'),
        _buildGroupedCard([
          GestureDetector(
            onTap: _pickPossessionDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text('RERA Possession Date',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.charcoal,
                      )),
                  const Spacer(),
                  Text(
                    _possessionDate != null
                        ? DateFormat('dd MMM yyyy').format(_possessionDate!)
                        : 'Select',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: _possessionDate != null
                          ? AppColors.iosSystemBlue
                          : AppColors.iosSecondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),

        _buildSectionHeader('VARIANTS'),
        for (int i = 0; i < _variants.length; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.iosCardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text('Variant ${i + 1}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          )),
                      const Spacer(),
                      if (_variants.length > 1)
                        IconButton(
                          onPressed: () => _removeVariant(i),
                          icon: const Icon(Icons.close_rounded),
                        ),
                    ],
                  ),
                ),
                Container(
                  height: 0.5,
                  color: AppColors.iosSeparator.withOpacity(0.3),
                  margin: const EdgeInsets.only(left: 16),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    value: _variants[i].flatType,
                    isExpanded: true,
                    style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal),
                    decoration: InputDecoration(
                      labelText: 'Flat Type',
                      labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.iosSecondaryLabel),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    items: flatOptions
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setState(() => _variants[i].flatType = val),
                    validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                  ),
                ),
                _buildFormField('Carpet (SqFt)', _variants[i].carpetCtrl, isNumber: true, hint: 'e.g., 700'),
                _buildFormField('Agreement Cost', _variants[i].agreementCtrl, isNumber: true, hint: 'e.g., 4000000'),
                _buildFormField('Total Cost', _variants[i].totalCostCtrl, isNumber: true, hint: 'e.g., 4500000'),
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton.icon(
            onPressed: _addVariant,
            icon: const Icon(Icons.add_rounded),
            label: Text('Add Variant', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ),

        _buildSectionHeader('META'),
        _buildGroupedCard([
          _buildFormField('FOS', _fosCtrl, isNumber: true, isOptional: true),
          _buildFormField('CP Slab %', _cpSlabPercentCtrl, isNumber: true, isOptional: true),
        ]),
      ],
    );
  }

  Widget _regularSection() {
    final flatOptions = _isBuilderUser
        ? const [
            '1 BHK',
            '1.5 BHK',
            '2 BHK',
            '2.5 BHK',
            '3 BHK',
            '3.5 BHK',
            '4 BHK',
            '4.5 BHK',
            '5 BHK',
            '5.5 BHK',
            '6 BHK',
            '7 BHK',
            'Bungalow',
          ]
        : const [
            '1 RK',
            '1 BHK',
            '1.5 BHK',
            '2 BHK',
            '2.5 BHK',
            '3 BHK',
            '3.5 BHK',
            '4 BHK',
            '4.5 BHK',
            '5 BHK',
            '5.5 BHK',
            'Bungalow',
            'Duplex',
            'Penthouse',
          ];

    final categoryItems = _isBuilderUser
        ? const [PropertyCategory.newProperty]
        : const [
            PropertyCategory.residential,
            PropertyCategory.commercial,
            PropertyCategory.plot,
          ];

    final listingItems = _category == PropertyCategory.newProperty
        ? const [ListingType.newLaunch]
        : (_category == PropertyCategory.plot
            ? const [ListingType.plot]
            : const [ListingType.resale, ListingType.rent]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('CLASSIFICATION'),
        _buildGroupedCard([
          _buildDropdownField<PropertyCategory>(
            'Category',
            _category,
            categoryItems,
            (c) => c.value,
            _isBuilderUser
                ? null
                : (val) {
                    if (val == null) return;
                    setState(() {
                      _category = val;
                      if (val == PropertyCategory.plot) {
                        _listingType = ListingType.plot;
                      } else if (_listingType == ListingType.plot) {
                        _listingType = ListingType.resale;
                      }
                      if (_listingType == ListingType.newLaunch &&
                          val != PropertyCategory.newProperty) {
                        _listingType = ListingType.resale;
                      }
                    });
                  },
          ),
          _buildDropdownField<ListingType>(
            'Listing Type',
            _listingType,
            listingItems,
            (t) => t.value,
            (val) {
              if (val == null) return;
              setState(() => _listingType = val);
            },
          ),
        ]),

        _buildSectionHeader('LOCATION'),
        _buildGroupedCard([
          _buildFormField('City', _cityCtrl),
          _buildFormField('Area / Locality', _areaCtrl),
          _buildFormField('Subarea', _subareaCtrl, isOptional: true, hint: 'e.g., Sector 4'),
          if (!_isPlot) _buildFormField('Society Name', _societyCtrl, hint: 'e.g., Green Heights'),
        ]),

        _buildSectionHeader('DETAILS'),
        _buildGroupedCard([
          if (!_isPlot && _category != PropertyCategory.commercial)
            _buildDropdownField<String>(
              'Flat / Bungalow',
              _selectedFlatBhk,
              flatOptions,
              (t) => t,
              (val) => setState(() => _selectedFlatBhk = val),
              validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
            ),
          if (_isPlot) ...[
            _buildFormField('Plot Area', _plotAreaCtrl, isNumber: true, hint: 'e.g., 1000'),
            _buildDropdownField<String>(
              'Unit',
              _areaUnit,
              const ['SqFt', 'Guntha', 'Acre'],
              (u) => u,
              (val) => setState(() => _areaUnit = val ?? _areaUnit),
            ),
          ] else ...[
            _buildDropdownField<String>(
              'Area Type',
              _selectedAreaType,
              const ['Carpet Area', 'Built-up Area'],
              (t) => t,
              (val) => setState(() => _selectedAreaType = val ?? _selectedAreaType),
            ),
            _buildFormField('Area (SqFt)', _generalAreaCtrl, isNumber: true, hint: 'e.g., 1000'),
            if (!_isNew)
              _buildDropdownField<int>(
                'Floor Number',
                _selectedFloor,
                List.generate(41, (i) => i),
                (f) => f == 0 ? '0 (Ground)' : f.toString(),
                (val) => setState(() => _selectedFloor = val),
                validator: (val) => val == null ? 'Required' : null,
              ),
          ],
        ]),

        _buildSectionHeader('PRICING'),
        _buildGroupedCard([
          _buildFormField(
            _isRent ? 'Rent (Monthly)' : 'Price',
            _priceCtrl,
            isNumber: true,
            hint: _isRent ? 'e.g., 15000' : 'e.g., 5000000',
          ),
          if (_isRent)
            _buildFormField(
              'Deposit',
              _depositCtrl,
              isNumber: true,
              hint: 'e.g., 50000',
            ),
        ]),

        if (!_isNew) ...[
          _buildSectionHeader('ADDITIONAL'),
          _buildGroupedCard([
            GestureDetector(
              onTap: _pickAvailabilityDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Text('Available From',
                        style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal)),
                    const Spacer(),
                    Text(
                      _availabilityDate != null
                          ? DateFormat('dd MMM yyyy').format(_availabilityDate!)
                          : 'Select',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: _availabilityDate != null
                            ? AppColors.iosSystemBlue
                            : AppColors.iosSecondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!_isPlot) ...[
              _buildDropdownField<String>(
                'Parking',
                _selectedParking,
                const ['Open', 'Covered', 'Not available'],
                (p) => p,
                (val) => setState(() => _selectedParking = val ?? _selectedParking),
              ),
              _buildDropdownField<String>(
                'Furnishing',
                _selectedFurnishing,
                const ['Full', 'Semi', 'Unfurnished'],
                (f) => f,
                (val) => setState(() => _selectedFurnishing = val ?? _selectedFurnishing),
              ),
              if (_showAvailableFor)
                _buildDropdownField<String>(
                  'Available For',
                  _selectedAvailableFor,
                  const ['Family', 'Bachelor', 'Any'],
                  (f) => f,
                  (val) => setState(
                    () => _selectedAvailableFor = val ?? _selectedAvailableFor,
                  ),
                ),
            ],
          ]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iosGroupedBg,
      appBar: AppBar(
        backgroundColor: AppColors.iosGroupedBg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Property',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              if (_isBuilderNewLaunch) _builderSection() else _regularSection(),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator.adaptive(),
                      )
                    : GestureDetector(
                        onTap: _submitEdit,
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.iosSystemBlue,
                            gradient: const LinearGradient(
                              colors: [AppColors.iosSystemBlue, Color(0xFF0A7EEA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.iosSystemBlue.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Save Changes',
                                style: GoogleFonts.inter(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariantData {
  String? flatType;
  final TextEditingController carpetCtrl = TextEditingController();
  final TextEditingController agreementCtrl = TextEditingController();
  final TextEditingController totalCostCtrl = TextEditingController();

  void dispose() {
    carpetCtrl.dispose();
    agreementCtrl.dispose();
    totalCostCtrl.dispose();
  }
}

