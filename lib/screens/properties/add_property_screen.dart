import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../models/property_model.dart';
import 'package:intl/intl.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  late PropertyCategory _category;
  late ListingType _listingType;

  final _cityCtrl = TextEditingController(text: AuthService.userCity);
  final _areaCtrl = TextEditingController();
  final _subareaCtrl = TextEditingController();
  final _societyCtrl = TextEditingController();
  final _areaValueCtrl = TextEditingController();
  final _generalAreaCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();

  String _areaUnit = 'SqFt';
  String _selectedAreaType = 'Carpet Area';
  DateTime? _availabilityDate;
  String? _selectedFlatBhk;
  int? _selectedFloor;
  String _selectedParking = 'Not available';
  String _selectedFurnishing = 'Unfurnished';
  String _selectedAvailableFor = 'Any';
  DateTime? _possessionDate;
  static final RegExp _englishAsciiRegex = RegExp(r'^[\x00-\x7F]+$');

  @override
  void initState() {
    super.initState();
    if (AuthService.userType == 'Builder') {
      _category = PropertyCategory.newProperty;
      _listingType = ListingType.newLaunch;
    } else {
      _category = PropertyCategory.residential;
      _listingType = ListingType.resale;
    }
  }

  bool get _isPlot => _listingType == ListingType.plot;
  bool get _isNew =>
      _category == PropertyCategory.newProperty ||
      _listingType == ListingType.newLaunch;
  bool get _isRent => _listingType == ListingType.rent;
  bool get _showAvailableFor =>
      _category == PropertyCategory.residential && _isRent;
  bool get _isBuilderUser =>
      AuthService.userType == 'Builder' || AuthService.userType == 'Developer';

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isNew && _possessionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Possession Date'),
          backgroundColor: AppColors.iosDestructive,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User ID null');

      final floorNum = _selectedFloor;
      final floorCat = PropertyModel.floorCategoryFromNumber(floorNum);

      final newProp = PropertyModel(
        userId: userId,
        category: _category,
        listingType: _listingType,
        city: _cityCtrl.text.trim(),
        area: _areaCtrl.text.trim(),
        subarea: _subareaCtrl.text.trim().isEmpty
            ? null
            : _subareaCtrl.text.trim(),
        societyName: _isPlot ? null : _societyCtrl.text.trim(),
        flatType: _isPlot ? null : _selectedFlatBhk,
        areaValue: _isPlot ? double.tryParse(_areaValueCtrl.text.trim()) : null,
        builtUpArea: _isPlot
            ? null
            : (_selectedAreaType == 'Built-up Area'
                  ? double.tryParse(_generalAreaCtrl.text.trim())
                  : null),
        carpetArea: _isPlot
            ? null
            : (_selectedAreaType == 'Carpet Area'
                  ? double.tryParse(_generalAreaCtrl.text.trim())
                  : null),
        areaUnit: _isPlot ? _areaUnit : 'SqFt',
        floorNumber: _isPlot || _isNew ? null : floorNum,
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
      );

      final result = await PropertyService.addProperty(
        newProp,
        deactivatePrevious: _isBuilderUser,
      );

      if (!mounted) return;
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property added!'),
            backgroundColor: AppColors.iosSystemGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Insert returned null');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.iosDestructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── iOS-style helpers ──

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

  Widget _buildFormField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    String? hint,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: (val) {
        if (!isOptional && (val == null || val.trim().isEmpty))
          return '$label is required';
        if (isNumber &&
            val != null &&
            val.trim().isNotEmpty &&
            double.tryParse(val.trim()) == null) {
          return 'Use English digits only';
        }
        if (!isNumber &&
            val != null &&
            val.trim().isNotEmpty &&
            !_englishAsciiRegex.hasMatch(val.trim())) {
          return 'Only English characters are allowed';
        }
        return null;
      },
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

  Widget _buildInfoNotice(String message) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.iosFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.iosSeparator.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.iosSystemBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.charcoal,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
            .map(
              (t) => DropdownMenuItem(value: t, child: Text(labelBuilder(t))),
            )
            .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildAreaAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.length < 2)
          return const Iterable<String>.empty();
        return await PropertyService.searchCityAreas(textEditingValue.text);
      },
      onSelected: (String selection) => _areaCtrl.text = selection,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        controller.addListener(() => _areaCtrl.text = controller.text);
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\x00-\x7F]')),
          ],
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal),
          decoration: InputDecoration(
            labelText: 'Area / Locality',
            hintText: 'Search area (2+ letters)',
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Area is required';
            if (!_englishAsciiRegex.hasMatch(val.trim())) {
              return 'Only English characters are allowed';
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: MediaQuery.of(context).size.width - 56,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final option = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.iosSystemBlue,
                    ),
                    title: Text(option, style: GoogleFonts.inter(fontSize: 14)),
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

  @override
  Widget build(BuildContext context) {
    final isBuilder = AuthService.userType == 'Builder';
    final flatOptions = isBuilder
        ? [
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
        : [
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
          'Add Property',
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
              if (isBuilder)
                _buildInfoNotice(
                  'Builders can add only 1 property at a time. To add a new property, please delete the existing one first.',
                ),
              // ── Classification ──
              _buildSectionHeader('CLASSIFICATION'),
              _buildGroupedCard([
                _buildDropdownField<PropertyCategory>(
                  'Category',
                  _category,
                  isBuilder
                      ? [PropertyCategory.newProperty]
                      : [
                          PropertyCategory.residential,
                          PropertyCategory.commercial,
                        ],
                  (c) => c.value,
                  isBuilder
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() {
                              _category = val;
                              if (val != PropertyCategory.commercial &&
                                  _listingType == ListingType.plot) {
                                _listingType = ListingType.resale;
                              }
                              if (_listingType == ListingType.newLaunch &&
                                  val != PropertyCategory.newProperty) {
                                _listingType = ListingType.resale;
                              }
                            });
                          }
                        },
                ),
                if (!isBuilder)
                  _buildDropdownField<ListingType>(
                    'Listing Type',
                    _listingType,
                    _category == PropertyCategory.commercial
                        ? [
                            ListingType.resale,
                            ListingType.rent,
                            ListingType.plot,
                          ]
                        : [ListingType.resale, ListingType.rent],
                    (t) => t.value,
                    (val) {
                      if (val != null) setState(() => _listingType = val);
                    },
                  ),
              ]),

              // ── Location ──
              _buildSectionHeader('LOCATION'),
              _buildGroupedCard([
                _buildFormField('City', _cityCtrl),
                _buildAreaAutocomplete(),
                _buildFormField(
                  'Subarea',
                  _subareaCtrl,
                  hint: 'e.g., Sector 4',
                  isOptional: true,
                ),
              ]),

              // ── Property Details ──
              _buildSectionHeader('DETAILS'),
              _buildGroupedCard([
                if (!_isPlot)
                  _buildFormField(
                    _isNew ? 'Scheme / Society' : 'Society Name',
                    _societyCtrl,
                  ),
                if (!_isPlot && _category == PropertyCategory.commercial)
                  _buildDropdownField<String>(
                    'Property Type',
                    _selectedFlatBhk,
                    [
                      'Office Spaces',
                      'Retail & Shops',
                      'Industrial & Warehousing',
                      'Co-working Spaces',
                    ],
                    (t) => t,
                    (val) {
                      if (val != null) setState(() => _selectedFlatBhk = val);
                    },
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                if (!_isPlot && _category != PropertyCategory.commercial)
                  _buildDropdownField<String>(
                    'Flat / Bungalow',
                    _selectedFlatBhk,
                    flatOptions,
                    (t) => t,
                    (val) {
                      if (val != null) setState(() => _selectedFlatBhk = val);
                    },
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                if (_isPlot) ...[
                  _buildFormField(
                    'Plot Area',
                    _areaValueCtrl,
                    isNumber: true,
                    hint: 'e.g., 1000',
                  ),
                  _buildDropdownField<String>(
                    'Unit',
                    _areaUnit,
                    ['SqFt', 'Guntha', 'Acre'],
                    (u) => u,
                    (val) {
                      if (val != null) setState(() => _areaUnit = val);
                    },
                  ),
                ] else ...[
                  _buildDropdownField<String>(
                    'Area Type',
                    _selectedAreaType,
                    ['Carpet Area', 'Built-up Area'],
                    (t) => t,
                    (val) {
                      if (val != null) setState(() => _selectedAreaType = val);
                    },
                  ),
                  _buildFormField(
                    'Area (SqFt)',
                    _generalAreaCtrl,
                    isNumber: true,
                    hint: 'e.g., 1000',
                  ),
                ],
                if (!_isPlot && !_isNew)
                  _buildDropdownField<int>(
                    'Floor Number',
                    _selectedFloor,
                    List.generate(41, (i) => i),
                    (f) => f == 0 ? '0 (Ground)' : f.toString(),
                    (val) {
                      if (val != null) setState(() => _selectedFloor = val);
                    },
                    validator: (val) => val == null ? 'Required' : null,
                  ),
              ]),

              // ── Pricing ──
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

              // ── Additional ──
              if (!_isPlot && !_isNew || _isNew) ...[
                _buildSectionHeader('ADDITIONAL'),
                _buildGroupedCard([
                  if (!_isNew && !_isPlot)
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _availabilityDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null)
                          setState(() => _availabilityDate = picked);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Available From',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: AppColors.charcoal,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _availabilityDate != null
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(_availabilityDate!)
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
                  if (_isNew)
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (picked != null)
                          setState(() => _possessionDate = picked);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Possession Date',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: AppColors.charcoal,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _possessionDate != null
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(_possessionDate!)
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
                  if (!_isPlot && !_isNew)
                    _buildDropdownField<String>(
                      'Parking',
                      _selectedParking,
                      ['Open', 'Covered', 'Not available'],
                      (p) => p,
                      (val) {
                        if (val != null) setState(() => _selectedParking = val);
                      },
                    ),
                  if (!_isPlot && !_isNew)
                    _buildDropdownField<String>(
                      'Furnishing',
                      _selectedFurnishing,
                      ['Full', 'Semi', 'Unfurnished'],
                      (f) => f,
                      (val) {
                        if (val != null)
                          setState(() => _selectedFurnishing = val);
                      },
                    ),
                  if (_showAvailableFor)
                    _buildDropdownField<String>(
                      'Available For',
                      _selectedAvailableFor,
                      const ['Family', 'Bachelor', 'Any'],
                      (v) => v,
                      (val) {
                        if (val != null) {
                          setState(() => _selectedAvailableFor = val);
                        }
                      },
                    ),
                ]),
              ],

              // ── Submit ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator.adaptive())
                    : GestureDetector(
                        onTap: _submitProperty,
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.iosSystemBlue,
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.iosSystemBlue,
                                Color(0xFF0A7EEA),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.iosSystemBlue.withOpacity(
                                  0.35,
                                ),
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
                                Icons.maps_home_work_rounded,
                                color: AppColors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Post Property',
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
