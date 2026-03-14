import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../models/property_model.dart';
import 'package:intl/intl.dart';

/// Builder-specific Add Property screen with variant support.
class AddBuilderPropertyScreen extends StatefulWidget {
  const AddBuilderPropertyScreen({super.key});

  @override
  State<AddBuilderPropertyScreen> createState() => _AddBuilderPropertyScreenState();
}

class _AddBuilderPropertyScreenState extends State<AddBuilderPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Top-level builder fields
  final _schemeCtrl = TextEditingController();
  final _reraCtrl = TextEditingController();
  final _landCtrl = TextEditingController();
  final _totalBuildingsCtrl = TextEditingController();
  final _amenitiesCtrl = TextEditingController();
  final _structureCtrl = TextEditingController();
  final _totalUnitsCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: AuthService.userCity);
  final _areaCtrl = TextEditingController();

  DateTime? _possessionDate;

  // Variants (up to 8)
  final List<_VariantData> _variants = [_VariantData()];

  @override
  void dispose() {
    _schemeCtrl.dispose();
    _reraCtrl.dispose();
    _landCtrl.dispose();
    _totalBuildingsCtrl.dispose();
    _amenitiesCtrl.dispose();
    _structureCtrl.dispose();
    _totalUnitsCtrl.dispose();
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  void _addVariant() {
    if (_variants.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 8 variants allowed'), backgroundColor: AppColors.iosDestructive),
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

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;

    if (_possessionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select RERA Possession Date'), backgroundColor: AppColors.iosDestructive),
      );
      return;
    }

    if (_variants.any((v) => v.flatType == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Flat Type for all variants'), backgroundColor: AppColors.iosDestructive),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User ID null');

      final variantsList = _variants.map((v) => {
        'flat_type': v.flatType ?? '',
        'carpet': double.tryParse(v.carpetCtrl.text.trim()) ?? 0,
        'agreement_cost': double.tryParse(v.agreementCtrl.text.trim()) ?? 0,
        'total_cost': double.tryParse(v.totalCostCtrl.text.trim()) ?? 0,
      }).toList();

      final newProp = PropertyModel(
        userId: userId,
        category: PropertyCategory.newProperty,
        listingType: ListingType.newLaunch,
        city: _cityCtrl.text.trim(),
        area: _areaCtrl.text.trim(),
        societyName: _schemeCtrl.text.trim(),
        areaValue: double.tryParse(_landCtrl.text.trim()),
        areaUnit: 'Acre',
        possessionDate: _possessionDate,
        reraNo: _reraCtrl.text.trim(),
        totalBuildings: int.tryParse(_totalBuildingsCtrl.text.trim()),
        amenitiesCount: int.tryParse(_amenitiesCtrl.text.trim()),
        buildingStructure: _structureCtrl.text.trim(),
        totalUnits: int.tryParse(_totalUnitsCtrl.text.trim()),
        isApproved: false, // Requires admin approval
        variants: variantsList,
      );

      final result = await PropertyService.addProperty(newProp);

      if (!mounted) return;
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property submitted for approval!'),
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
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.iosDestructive),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Reusable form helpers ──

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, bottom: 8, top: 26),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.iosSecondaryLabel, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(Container(height: 0.5, color: AppColors.iosSeparator.withOpacity(0.3), margin: const EdgeInsets.only(left: 16)));
      }
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.iosCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {bool isNumber = false, String? hint, bool isOptional = false, String? suffix}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.iosSecondaryLabel),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.iosTertiaryLabel, fontWeight: FontWeight.w400),
        suffixStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.iosSecondaryLabel, fontWeight: FontWeight.w500),
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (val) {
        if (!isOptional && (val == null || val.trim().isEmpty)) return '$label is required';
        return null;
      },
    );
  }

  Widget _buildAreaAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.length < 2) return const Iterable<String>.empty();
        return await PropertyService.searchCityAreas(textEditingValue.text);
      },
      onSelected: (String selection) => _areaCtrl.text = selection,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        controller.addListener(() => _areaCtrl.text = controller.text);
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal),
          decoration: InputDecoration(
            labelText: 'Area / Locality',
            hintText: 'Search area (2+ letters)',
            labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.iosSecondaryLabel),
            hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.iosTertiaryLabel, fontWeight: FontWeight.w400),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Area is required';
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
              constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 56),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final option = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.location_on_outlined, size: 18, color: AppColors.iosSystemBlue),
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
    return Scaffold(
      backgroundColor: AppColors.iosGroupedBg,
      appBar: AppBar(
        backgroundColor: AppColors.iosGroupedBg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Add Project', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Location ──
              _buildSectionHeader('LOCATION'),
              _buildGroupedCard([
                _buildFormField('City', _cityCtrl),
                _buildAreaAutocomplete(),
              ]),

              // ── Project Details ──
              _buildSectionHeader('PROJECT DETAILS'),
              _buildGroupedCard([
                _buildFormField('Scheme Name', _schemeCtrl, hint: 'e.g., Athashree Apartment'),
                _buildFormField('RERA No', _reraCtrl, hint: 'e.g., P52100012345'),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setState(() => _possessionDate = picked);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Text('RERA Possession Date', style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal)),
                        const Spacer(),
                        Text(
                          _possessionDate != null ? DateFormat('dd/MM/yy').format(_possessionDate!) : 'Select',
                          style: GoogleFonts.inter(fontSize: 15, color: _possessionDate != null ? AppColors.iosSystemBlue : AppColors.iosSecondaryLabel),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildFormField('Land', _landCtrl, isNumber: true, hint: 'e.g., 3', suffix: 'Acres'),
                _buildFormField('Total Buildings', _totalBuildingsCtrl, isNumber: true, hint: 'e.g., 3'),
                _buildFormField('Amenities', _amenitiesCtrl, isNumber: true, hint: 'e.g., 35+'),
                _buildFormField('Building Structure', _structureCtrl, hint: 'e.g., B2+G+2+35'),
                _buildFormField('Total Units', _totalUnitsCtrl, isNumber: true, hint: 'e.g., 200'),
              ]),

              // ── Variants ──
              _buildSectionHeader('VARIANTS (${_variants.length}/8)'),
              
              for (int i = 0; i < _variants.length; i++) ...[
                _buildVariantCard(i),
                const SizedBox(height: 12),
              ],

              // Add New Variant Button
              if (_variants.length < 8)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: _addVariant,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text('Add Variant', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.iosSystemBlue,
                      side: BorderSide(color: AppColors.iosSystemBlue.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

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
                          gradient: const LinearGradient(
                            colors: [AppColors.iosSystemBlue, Color(0xFF0A7EEA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: AppColors.iosSystemBlue.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, color: AppColors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Submit for Approval', style: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                    ),
              ),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Your listing will be reviewed by admin before it appears on Discover.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.iosSecondaryLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVariantCard(int index) {
    final v = _variants[index];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.iosCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: AppColors.iosSystemBlue.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.iosSystemBlue.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.iosSystemBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text('${index + 1}', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Text('Variant ${index + 1}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
                const Spacer(),
                if (_variants.length > 1)
                  GestureDetector(
                    onTap: () => _removeVariant(index),
                    child: Icon(Icons.remove_circle_outline_rounded, color: AppColors.iosDestructive.withOpacity(0.7), size: 22),
                  ),
              ],
            ),
          ),
          Container(height: 0.5, color: AppColors.iosSeparator.withOpacity(0.3)),
          // Flat Type Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: DropdownButtonFormField<String>(
              value: v.flatType,
              isExpanded: true,
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal),
              decoration: InputDecoration(
                labelText: 'Flat Type',
                labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.iosSecondaryLabel),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              items: ['1 BHK', '1.5 BHK', '2 BHK', '2.5 BHK', '3 BHK', '3.5 BHK', '4 BHK', '4.5 BHK']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => v.flatType = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
          ),
          Container(height: 0.5, color: AppColors.iosSeparator.withOpacity(0.3), margin: const EdgeInsets.only(left: 16)),
          _buildFormField('Carpet (SqFt)', v.carpetCtrl, isNumber: true, hint: 'e.g., 750'),
          Container(height: 0.5, color: AppColors.iosSeparator.withOpacity(0.3), margin: const EdgeInsets.only(left: 16)),
          _buildFormField('Agreement Cost', v.agreementCtrl, isNumber: true, hint: 'e.g., 7500000'),
          Container(height: 0.5, color: AppColors.iosSeparator.withOpacity(0.3), margin: const EdgeInsets.only(left: 16)),
          _buildFormField('Total Cost', v.totalCostCtrl, isNumber: true, hint: 'e.g., 8055000'),
        ],
      ),
    );
  }
}

/// Internal variant data holder.
class _VariantData {
  String? flatType;
  final carpetCtrl = TextEditingController();
  final agreementCtrl = TextEditingController();
  final totalCostCtrl = TextEditingController();

  void dispose() {
    carpetCtrl.dispose();
    agreementCtrl.dispose();
    totalCostCtrl.dispose();
  }
}
