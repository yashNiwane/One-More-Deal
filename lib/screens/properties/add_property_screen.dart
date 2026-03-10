import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../models/property_model.dart';
import '../../widgets/gradient_button.dart';
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
  final _flatTypeCtrl = TextEditingController();
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
  String? _selectedFurnishing;
  DateTime? _possessionDate;

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
  bool get _isNew => _category == PropertyCategory.newProperty || _listingType == ListingType.newLaunch;
  bool get _isRent => _listingType == ListingType.rent;

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate missing fields that aren't form-controlled automatically
    if (_isNew && _possessionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Possession Date'), backgroundColor: AppColors.error),
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
        subarea: _subareaCtrl.text.trim().isEmpty ? null : _subareaCtrl.text.trim(),
        societyName: _isPlot ? null : _societyCtrl.text.trim(),
        flatType: _isPlot 
            ? null 
            : (_category == PropertyCategory.commercial 
                ? _flatTypeCtrl.text.trim() 
                : _selectedFlatBhk),
        areaValue: _isPlot ? double.tryParse(_areaValueCtrl.text.trim()) : null,
        builtUpArea: _isPlot ? null : (_selectedAreaType == 'Built-up Area' ? double.tryParse(_generalAreaCtrl.text.trim()) : null),
        carpetArea: _isPlot ? null : (_selectedAreaType == 'Carpet Area' ? double.tryParse(_generalAreaCtrl.text.trim()) : null),
        areaUnit: _isPlot ? _areaUnit : 'SqFt',
        floorNumber: _isPlot || _isNew ? null : floorNum,
        floorCategory: _isPlot || _isNew ? null : floorCat,
        price: double.tryParse(_priceCtrl.text.trim()),
        deposit: _isRent ? double.tryParse(_depositCtrl.text.trim()) : null,
        availability: _isNew ? null : (_availabilityDate != null ? DateFormat('dd MMM yyyy').format(_availabilityDate!) : null),
        possessionDate: _isNew ? _possessionDate : null,
        parking: _isPlot || _isNew ? null : _selectedParking,
        furnishingStatus: _isPlot || _isNew ? null : _selectedFurnishing,
      );

      final result = await PropertyService.addProperty(newProp);
      
      if (!mounted) return;
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property added successfully!'), backgroundColor: AppColors.primary),
        );
        Navigator.pop(context, true); // Return true to refresh parent list
      } else {
        throw Exception('Insert returned null');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding property: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, String? hint, bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
        ),
        validator: (val) {
          if (!isOptional && (val == null || val.trim().isEmpty)) return '$label is required';
          return null;
        },
      ),
    );
  }

  Widget _buildAreaAutocomplete() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) async {
          if (textEditingValue.text.length < 2) {
            return const Iterable<String>.empty();
          }
          final res = await PropertyService.searchCityAreas(textEditingValue.text);
          return res;
        },
        onSelected: (String selection) {
          _areaCtrl.text = selection;
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          controller.addListener(() {
            _areaCtrl.text = controller.text;
          });
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: 'Area / Locality',
              hintText: 'Search area (type 2+ letters)',
              prefixIcon: const Icon(Icons.search, color: AppColors.mediumGray),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Area / Locality is required';
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
                constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 40),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final option = options.elementAt(i);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBuilder = AuthService.userType == 'Builder';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('Add Property', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Dropdown
              DropdownButtonFormField<PropertyCategory>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Property Category',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: (isBuilder
                        ? [PropertyCategory.newProperty]
                        : [PropertyCategory.residential, PropertyCategory.commercial])
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat.value)))
                    .toList(),
                onChanged: isBuilder ? null : (val) {
                  if (val != null) {
                    setState(() {
                      _category = val;
                      // Reset listing type if moving away from commercial and currently plot
                      if (val != PropertyCategory.commercial && _listingType == ListingType.plot) {
                        _listingType = ListingType.resale;
                      }
                      if (_listingType == ListingType.newLaunch && val != PropertyCategory.newProperty) {
                        _listingType = ListingType.resale;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Listing Type Dropdown (hidden for Builder)
              if (!isBuilder)
                DropdownButtonFormField<ListingType>(
                  key: ValueKey('listing_${_category.value}'),
                  value: _listingType,
                  decoration: InputDecoration(
                    labelText: 'Listing Type',
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: (_category == PropertyCategory.commercial 
                          ? [ListingType.resale, ListingType.rent, ListingType.plot] 
                          : [ListingType.resale, ListingType.rent])
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.value)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _listingType = val);
                  },
                ),
              if (!isBuilder) const SizedBox(height: 16),

              _buildTextField('City', _cityCtrl),
              _buildAreaAutocomplete(),
              _buildTextField('Subarea', _subareaCtrl, hint: 'e.g., Sector 4, Phase 1', isOptional: true),

              if (!_isPlot)
                _buildTextField(_isNew ? 'Scheme / Society Name' : 'Society Name', _societyCtrl),

              if (!_isPlot)
                if (_category == PropertyCategory.commercial)
                  _buildTextField('Shop / Unit Number', _flatTypeCtrl, hint: 'e.g., Shop 14')
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedFlatBhk,
                      decoration: InputDecoration(
                        labelText: 'Flat / Bungalow',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'Bungalow']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFlatBhk = val);
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Please select an option';
                        return null;
                      },
                    ),
                  ),

              if (_isPlot)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField('Plot Area', _areaValueCtrl, isNumber: true, hint: 'e.g., 1000'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        key: const ValueKey('unit_plot'),
                        value: _areaUnit,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: ['SqFt', 'Guntha', 'Acre']
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (val) { if (val != null) setState(() => _areaUnit = val); },
                      ),
                    )
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _selectedAreaType,
                        decoration: InputDecoration(
                          labelText: 'Area Type',
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: ['Carpet Area', 'Built-up Area']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedAreaType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _buildTextField('Area (SqFt)', _generalAreaCtrl, isNumber: true, hint: 'e.g., 1000'),
                    ),
                  ],
                ),

              if (!_isPlot && !_isNew)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<int>(
                    value: _selectedFloor,
                    decoration: InputDecoration(
                      labelText: 'Floor Number',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: List.generate(41, (index) => index).map((floor) {
                      return DropdownMenuItem(
                        value: floor,
                        child: Text(floor == 0 ? '0 (Ground)' : floor.toString()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFloor = val);
                    },
                    validator: (val) => val == null ? 'Floor Number is required' : null,
                  ),
                ),

              if (_isRent)
                ...[
                  _buildTextField('Rent (Monthly)', _priceCtrl, isNumber: true, hint: 'e.g., 15000'),
                  _buildTextField('Deposit', _depositCtrl, isNumber: true, hint: 'e.g., 50000'),
                ]
              else
                _buildTextField('Price', _priceCtrl, isNumber: true, hint: 'e.g., 5000000'),

              if (!_isNew && !_isPlot)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _availabilityDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _availabilityDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Available From',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      child: Text(
                        _availabilityDate != null ? DateFormat('dd MMM yyyy').format(_availabilityDate!) : 'Select Date',
                        style: TextStyle(color: _availabilityDate != null ? AppColors.charcoal : AppColors.mediumGray),
                      ),
                    ),
                  ),
                ),

              if (_isNew)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        setState(() => _possessionDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Possession Date',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      child: Text(
                        _possessionDate != null ? DateFormat('dd MMM yyyy').format(_possessionDate!) : 'Select Date',
                        style: TextStyle(color: _possessionDate != null ? AppColors.charcoal : AppColors.mediumGray),
                      ),
                    ),
                  ),
                ),

              if (!_isPlot && !_isNew)
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  child: DropdownButtonFormField<String>(
                    value: _selectedParking,
                    decoration: InputDecoration(
                      labelText: 'Car Parking',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: ['Open', 'Covered', 'Not available']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedParking = val);
                    },
                  ),
                ),

              if (!_isPlot && !_isNew)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: DropdownButtonFormField<String>(
                    value: _selectedFurnishing,
                    decoration: InputDecoration(
                      labelText: 'Furnishing Status',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: ['Full', 'Semi', 'Unfurnished']
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFurnishing = val);
                    },
                  ),
                ),

              const SizedBox(height: 20),

              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : GradientButton(
                      label: 'Post Property',
                      onPressed: _submitProperty,
                    ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
