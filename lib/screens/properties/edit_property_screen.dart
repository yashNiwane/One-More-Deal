import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../services/property_service.dart';
import '../../models/property_model.dart';
import '../../widgets/gradient_button.dart';
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
  String? _selectedFurnishing;

  bool get _isNew => widget.property.category == PropertyCategory.newProperty || widget.property.listingType == ListingType.newLaunch;
  bool get _isRent => widget.property.listingType == ListingType.rent;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: widget.property.price?.toString() ?? '');
    _depositCtrl = TextEditingController(text: widget.property.deposit?.toString() ?? '');
    _subareaCtrl = TextEditingController(text: widget.property.subarea ?? '');
    _selectedParking = widget.property.parking ?? 'Not available';
    _selectedFurnishing = widget.property.furnishingStatus;
    
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
        const SnackBar(content: Text('Property updated successfully'), backgroundColor: AppColors.primary),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: \$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text('Edit Property', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit \${widget.property.societyName ?? widget.property.category.value}',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoal),
              ),
              const SizedBox(height: 8),
              Text(
                'You can only modify the Price, Area, and Availability of an active listing. For other changes, please delete and repost.',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.mediumGray),
              ),
              const SizedBox(height: 24),
              
              if (widget.property.listingType != ListingType.plot)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
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
                        child: TextFormField(
                          controller: _generalAreaCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Area (SqFt)',
                            hintText: 'e.g., 1000',
                            filled: true,
                            fillColor: AppColors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              TextFormField(
                controller: _subareaCtrl,
                decoration: InputDecoration(
                  labelText: 'Subarea (Optional)',
                  hintText: 'e.g., Sector 4, Phase 1',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _isRent ? 'Rent (Monthly)' : 'Price',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
                ),
                validator: (val) {
                  final label = _isRent ? 'Rent' : 'Price';
                  if (val == null || val.trim().isEmpty) return '$label is required';
                  return null;
                },
              ),
              if (_isRent) const SizedBox(height: 16),
              if (_isRent)
                TextFormField(
                  controller: _depositCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Deposit',
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
                  ),
                ),
              if (_isRent) const SizedBox(height: 16),

              if (!_isNew)
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

              if (!_isNew && widget.property.listingType != ListingType.plot)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
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

              if (!_isNew && widget.property.listingType != ListingType.plot)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
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

              const SizedBox(height: 32),

              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : GradientButton(
                      label: 'Save Changes',
                      onPressed: _submitEdit,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
