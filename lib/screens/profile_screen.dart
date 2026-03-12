import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
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
          const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.iosSystemGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.iosDestructive),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to logout?', style: GoogleFonts.inter(color: AppColors.iosSecondaryLabel)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.iosSystemBlue, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Logout', style: GoogleFonts.inter(color: AppColors.iosDestructive, fontWeight: FontWeight.w600)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iosGroupedBg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.iosGroupedBg,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: Text(
              'Profile',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              if (!_isEditing)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: () => setState(() => _isEditing = true),
                    child: Text('Edit', style: GoogleFonts.inter(color: AppColors.iosSystemBlue, fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isEditing ? _buildEditForm() : _buildProfileView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      children: [
        const SizedBox(height: 8),

        // ── Avatar card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.iosCardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: Text(
                    AuthService.userName.isNotEmpty ? AuthService.userName[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AuthService.userName.isNotEmpty ? AuthService.userName : 'User',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.charcoal, letterSpacing: -0.4),
              ),
              const SizedBox(height: 4),
              Text(
                '${AuthService.userType} · ${AuthService.userCity}${AuthService.userCode != null ? ' · ${AuthService.userCode}' : ''}',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.iosSecondaryLabel),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Details section ──
        _buildSectionHeader('DETAILS'),
        const SizedBox(height: 6),
        _buildGroupedCard([
          _buildListRow(Icons.person_outlined, 'Name', AuthService.userName),
          _buildListRow(Icons.phone_outlined, 'Phone', AuthService.userPhone),
          _buildListRow(Icons.business_outlined, 'Type', AuthService.userType),
          _buildListRow(Icons.location_city_outlined, 'City', AuthService.userCity),
          _buildListRow(Icons.apartment_outlined, 'Company', AuthService.userCompanyName, isLast: true),
        ]),

        const SizedBox(height: 24),

        // ── Account section ──
        _buildSectionHeader('ACCOUNT'),
        const SizedBox(height: 6),
        _buildGroupedCard([
          _buildTappableRow(Icons.logout_rounded, 'Logout', AppColors.iosDestructive, _logout, isLast: true),
        ]),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 8),

          // ── Read-only info ──
          _buildSectionHeader('READ-ONLY'),
          const SizedBox(height: 6),
          _buildGroupedCard([
            _buildInfoRow('Phone', AuthService.userPhone),
            _buildInfoRow('Type', AuthService.userType, isLast: true),
          ]),

          const SizedBox(height: 24),

          // ── Editable fields ──
          _buildSectionHeader('EDIT PROFILE'),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.iosCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _buildFormField('Full Name', _nameCtrl),
                Container(height: 0.5, color: AppColors.iosSeparator.withOpacity(0.3), margin: const EdgeInsets.only(left: 16)),
                _buildFormField('City', _cityCtrl),
                Container(height: 0.5, color: AppColors.iosSeparator.withOpacity(0.3), margin: const EdgeInsets.only(left: 16)),
                _buildFormField('Company / Agency', _companyCtrl, isLast: true),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Actions ──
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _nameCtrl.text = AuthService.userName;
                    _cityCtrl.text = AuthService.userCity;
                    _companyCtrl.text = AuthService.userCompanyName;
                    _userType = AuthService.userType;
                    setState(() => _isEditing = false);
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.iosCardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.iosDestructive, fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isSaving
                  ? const Center(child: CircularProgressIndicator.adaptive())
                  : GestureDetector(
                      onTap: _saveProfile,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.iosSystemBlue,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text('Save', style: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
              ),
            ],
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Helper builders ──

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Text(
          title,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.iosSecondaryLabel, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.iosCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.iosSystemBlue),
              const SizedBox(width: 12),
              Text(label, style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal)),
              const Spacer(),
              Flexible(
                child: Text(
                  value.isNotEmpty ? value : '—',
                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.iosSecondaryLabel),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Container(height: 0.5, color: AppColors.iosSeparator.withOpacity(0.3), margin: const EdgeInsets.only(left: 52)),
      ],
    );
  }

  Widget _buildTappableRow(IconData icon, String label, Color color, VoidCallback onTap, {bool isLast = false}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 12),
                Text(label, style: GoogleFonts.inter(fontSize: 15, color: color, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (!isLast)
            Container(height: 0.5, color: AppColors.iosSeparator.withOpacity(0.3), margin: const EdgeInsets.only(left: 52)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal)),
              const Spacer(),
              Text(value, style: GoogleFonts.inter(fontSize: 15, color: AppColors.iosSecondaryLabel)),
            ],
          ),
        ),
        if (!isLast)
          Container(height: 0.5, color: AppColors.iosSeparator.withOpacity(0.3), margin: const EdgeInsets.only(left: 16)),
      ],
    );
  }

  Widget _buildFormField(String label, TextEditingController ctrl, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: ctrl,
        style: GoogleFonts.inter(fontSize: 15, color: AppColors.charcoal),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.iosSecondaryLabel),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        validator: (val) {
          if (val == null || val.trim().isEmpty) return '$label is required';
          return null;
        },
      ),
    );
  }
}
