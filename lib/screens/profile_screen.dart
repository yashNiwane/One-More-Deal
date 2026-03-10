import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/gradient_button.dart';
import 'landing_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _companyCtrl;
  late String _userType;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: AuthService.userName);
    _cityCtrl = TextEditingController(text: AuthService.userCity);
    _companyCtrl = TextEditingController(text: AuthService.userCompanyName);
    _userType = AuthService.userType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await AuthService.saveProfile(
        name: _nameCtrl.text.trim(),
        userType: _userType,
        city: _cityCtrl.text.trim(),
        companyName: _companyCtrl.text.trim(),
      );
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('LOGOUT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (_) => false,
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.mediumGray)),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : '—',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.charcoal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {IconData icon = Icons.edit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
        ),
        validator: (val) {
          if (val == null || val.trim().isEmpty) return '$label is required';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          // Premium Gradient Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        // Avatar
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.goldGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              AuthService.userName.isNotEmpty ? AuthService.userName[0].toUpperCase() : '?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AuthService.userName.isNotEmpty ? AuthService.userName : 'User',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${AuthService.userType} · ${AuthService.userCity}${AuthService.userCode != null ? ' · ${AuthService.userCode}' : ''}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _isEditing ? _buildEditForm() : _buildProfileView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Details Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Profile Details', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
                  TextButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accent),
                    label: Text('Edit', style: GoogleFonts.plusJakartaSans(color: AppColors.accent, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Divider(),
              _buildInfoRow(Icons.person_outline, 'Name', AuthService.userName),
              _buildInfoRow(Icons.phone_outlined, 'Phone', AuthService.userPhone),
              _buildInfoRow(Icons.business_outlined, 'Type', AuthService.userType),
              _buildInfoRow(Icons.location_city_outlined, 'City', AuthService.userCity),
              _buildInfoRow(Icons.apartment_outlined, 'Company', AuthService.userCompanyName),
              if (AuthService.userCode != null)
                _buildInfoRow(Icons.badge_outlined, 'User Code', AuthService.userCode!),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Logout Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: Text('Logout', style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.red, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Profile', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.charcoal)),
                    TextButton(
                      onPressed: () {
                        // Reset to original values
                        _nameCtrl.text = AuthService.userName;
                        _cityCtrl.text = AuthService.userCity;
                        _companyCtrl.text = AuthService.userCompanyName;
                        _userType = AuthService.userType;
                        setState(() => _isEditing = false);
                      },
                      child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.error, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Phone (read-only)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_locked_outlined, color: AppColors.mediumGray, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        AuthService.userPhone,
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.mediumGray),
                      ),
                      const Spacer(),
                      Text('Cannot change', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.mediumGray)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildEditField('Full Name', _nameCtrl, icon: Icons.person_outline),
                _buildEditField('City', _cityCtrl, icon: Icons.location_city_outlined),
                _buildEditField('Company / Agency Name', _companyCtrl, icon: Icons.apartment_outlined),

                // User Type (read-only)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business_outlined, color: AppColors.mediumGray, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        AuthService.userType,
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.mediumGray),
                      ),
                      const Spacer(),
                      Text('Cannot change', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.mediumGray)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _isSaving
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : GradientButton(
                  label: 'Save Changes',
                  onPressed: _saveProfile,
                ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
