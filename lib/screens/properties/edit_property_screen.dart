import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../services/property_service.dart';
import '../../models/property_model.dart';
import 'package:intl/intl.dart';

class EditPropertyScreen extends StatefulWidget {
  final PropertyModel property;
  const EditPropertyScreen({super.key, required this.property});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _priceCtrl;
  late TextEditingController _depositCtrl;
  late TextEditingController _generalAreaCtrl;
  late TextEditingController _subareaCtrl;
  String _selectedAreaType = 'Carpet Area';
  DateTime? _availabilityDate;
  String _selectedParking = 'Not available';
  String _selectedFurnishing = 'Unfurnished';

  bool get _isNew => widget.property.category == PropertyCategory.newProperty || widget.property.listingType == ListingType.newLaunch;
  bool get _isRent => widget.property.listingType == ListingType.rent;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: widget.property.price?.toString() ?? '');
    _depositCtrl = TextEditingController(text: widget.property.deposit?.toString() ?? '');
    _subareaCtrl = TextEditingController(text: widget.property.subarea ?? '');
    _selectedParking = widget.property.parking ?? 'Not available';
    _selectedFurnishing = widget.property.furnishingStatus ?? 'Unfurnished';
    
    if (widget.property.builtUpArea != null) {
      _selectedAreaType = 'Built-up Area';
      _generalAreaCtrl = TextEditingController(text: widget.property.builtUpArea.toString());
    } else {
      _selectedAreaType = 'Carpet Area';
      _generalAreaCtrl = TextEditingController(text: widget.property.carpetArea?.toString() ?? '');
    }
    
    if (!_isNew && widget.property.availability != null) {
      try {
        _availabilityDate = DateFormat('dd MMM yyyy').parse(widget.property.availability!);
      } catch (e) {
        _availabilityDate = DateTime.now();
      }
    }
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final updatedPrice = double.tryParse(_priceCtrl.text.trim());
      final updatedDeposit = _isRent ? double.tryParse(_depositCtrl.text.trim()) : null;
      final updatedArea = double.tryParse(_generalAreaCtrl.text.trim());
      
      final updatedProp = PropertyModel(
        id: widget.property.id,
        userId: widget.property.userId,
        category: widget.property.category,
        listingType: widget.property.listingType,
        city: widget.property.city,
        area: widget.property.area,
        subarea: _subareaCtrl.text.trim().isEmpty ? null : _subareaCtrl.text.trim(),
        societyName: widget.property.societyName,
        flatType: widget.property.flatType,
        areaValue: widget.property.areaValue,
        builtUpArea: _selectedAreaType == 'Built-up Area' ? updatedArea : null,
        carpetArea: _selectedAreaType == 'Carpet Area' ? updatedArea : null,
        areaUnit: widget.property.areaUnit,
        floorNumber: widget.property.floorNumber,
        floorCategory: widget.property.floorCategory,
        price: updatedPrice,
        deposit: updatedDeposit,
        availability: _isNew ? null : (_availabilityDate != null ? DateFormat('dd MMM yyyy').format(_availabilityDate!) : null),
        possessionDate: widget.property.possessionDate,
        parking: widget.property.category == PropertyCategory.newProperty ? null : _selectedParking,
        furnishingStatus: widget.property.category == PropertyCategory.newProperty ? null : _selectedFurnishing,
        isVisible: widget.property.isVisible,
        postedAt: widget.property.postedAt,
        refreshedAt: widget.property.refreshedAt,
        autoDeleteAt: widget.property.autoDeleteAt,
        createdAt: widget.property.createdAt,
        posterName: widget.property.posterName,
        posterCode: widget.property.posterCode,
      );
      await PropertyService.updateProperty(updatedProp);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property updated'), backgroundColor: AppColors.iosSystemGreen),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e'), backgroundColor: AppColors.iosDestructive),
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

  Widget _buildFormField(String label, TextEditingController ctrl, {bool isNumber = false, String? hint}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.iosSecondaryLabel),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.iosTertiaryLabel, fontWeight: FontWeight.w400),
        filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return '$label is required';
        return null;
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
        title: Text('Edit Property', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.charcoal)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.iosSystemBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: AppColors.iosSystemBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Only price, area, and availability can be modified.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.iosSystemBlue, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Area ──
              if (widget.property.listingType != ListingType.plot) ...[
                _buildSectionHeader('AREA'),
                _buildGroupedCard([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedAreaType,
                      style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal),
                      decoration: InputDecoration(
                        labelText: 'Area Type',
                        labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.iosSecondaryLabel),
                        filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                      ),
                      items: ['Carpet Area', 'Built-up Area'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) { if (val != null) setState(() => _selectedAreaType = val); },
                    ),
                  ),
                  _buildFormField('Area (SqFt)', _generalAreaCtrl, isNumber: true, hint: 'e.g., 1000'),
                ]),
              ],

              // ── Location ──
              _buildSectionHeader('LOCATION'),
              _buildGroupedCard([
                _buildFormField('Subarea', _subareaCtrl, hint: 'e.g., Sector 4'),
              ]),

              // ── Pricing ──
              _buildSectionHeader('PRICING'),
              _buildGroupedCard([
                _buildFormField(_isRent ? 'Rent (Monthly)' : 'Price', _priceCtrl, isNumber: true),
                if (_isRent) _buildFormField('Deposit', _depositCtrl, isNumber: true),
              ]),

              // ── Additional ──
              if (!_isNew) ...[
                _buildSectionHeader('ADDITIONAL'),
                _buildGroupedCard([
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: _availabilityDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (picked != null) setState(() => _availabilityDate = picked);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Text('Available From', style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal)),
                          const Spacer(),
                          Text(
                            _availabilityDate != null ? DateFormat('dd MMM yyyy').format(_availabilityDate!) : 'Select',
                            style: GoogleFonts.inter(fontSize: 15, color: _availabilityDate != null ? AppColors.iosSystemBlue : AppColors.iosSecondaryLabel),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.property.listingType != ListingType.plot) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String>(
                        value: _selectedParking,
                        style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal),
                        decoration: InputDecoration(
                          labelText: 'Parking',
                          labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.iosSecondaryLabel),
                          filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                        ),
                        items: ['Open', 'Covered', 'Not available'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (val) { if (val != null) setState(() => _selectedParking = val); },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String>(
                        value: _selectedFurnishing,
                        style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal),
                        decoration: InputDecoration(
                          labelText: 'Furnishing',
                          labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.iosSecondaryLabel),
                          filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                        ),
                        items: ['Full', 'Semi', 'Unfurnished'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: (val) { if (val != null) setState(() => _selectedFurnishing = val); },
                      ),
                    ),
                  ],
                ]),
              ],

              const SizedBox(height: 32),

              _isLoading
                ? const Center(child: CircularProgressIndicator.adaptive())
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
                          BoxShadow(color: AppColors.iosSystemBlue.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('Save Changes', style: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.3)),
                        ],
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
