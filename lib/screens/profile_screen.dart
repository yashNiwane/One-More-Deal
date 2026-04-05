import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../services/auth_service.dart';
import 'admin/admin_screen.dart';
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
  late TextEditingController _reraCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _officeCtrl;
  late String _userType;
  bool _isEditing = false;
  bool _isSaving = false;
  static final RegExp _englishAsciiRegex = RegExp(r'^[\x00-\x7F]+$');

  String? _validateEnglish(
    String? value, {
    required String label,
    bool isOptional = false,
  }) {
    final text = value?.trim() ?? '';
    if (!isOptional && text.isEmpty) return '$label is required';
    if (text.isEmpty) return null;
    if (!_englishAsciiRegex.hasMatch(text)) {
      return 'Only English characters are allowed';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: AuthService.userName);
    _cityCtrl = TextEditingController(text: AuthService.userCity);
    _companyCtrl = TextEditingController(text: AuthService.userCompanyName);
    _reraCtrl = TextEditingController(text: AuthService.userReraNo);
    _areaCtrl = TextEditingController(text: AuthService.userArea);
    _officeCtrl = TextEditingController(text: AuthService.userOfficeAddress);
    _userType = AuthService.userType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _companyCtrl.dispose();
    _reraCtrl.dispose();
    _areaCtrl.dispose();
    _officeCtrl.dispose();
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
        reraNo: _userType == 'Broker' ? _reraCtrl.text.trim() : null,
        area: _areaCtrl.text.trim(),
        officeAddress: _officeCtrl.text.trim(),
      );
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: AppColors.iosSystemGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.iosDestructive,
          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Logout',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(color: AppColors.iosSecondaryLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.iosSystemBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: AppColors.iosDestructive,
                fontWeight: FontWeight.w700,
              ),
            ),
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

  Future<void> _openAdminPanel() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminScreen()));
  }

  double get _profileBottomInset {
    final safeInset = MediaQuery.of(context).padding.bottom;
    // Keep profile content above the floating dock + home indicator area.
    return 132 + safeInset;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF0B1733),
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: Text(
              'Profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                letterSpacing: -0.4,
              ),
            ),
            actions: [
              if (!_isEditing)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: () => setState(() => _isEditing = true),
                    child: Text(
                      'Edit',
                      style: GoogleFonts.inter(
                        color: AppColors.accentLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0B1733),
                    Color(0xFF132850),
                    Color(0xFFF3F5F9),
                    Color(0xFFF3F5F9),
                  ],
                  stops: [0, 0.22, 0.22, 1],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _isEditing ? _buildEditForm() : _buildProfileView(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF12244B), Color(0xFF1C3F86)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.goldGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        AuthService.userName.isNotEmpty
                            ? AuthService.userName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            AuthService.userType,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AuthService.userName.isNotEmpty
                              ? AuthService.userName
                              : 'User',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AuthService.userPhone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildHeroStat(
                        'City',
                        AuthService.userCity.isNotEmpty
                            ? AuthService.userCity
                            : '-',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildHeroStat(
                        'Code',
                        AuthService.userCode?.isNotEmpty == true
                            ? AuthService.userCode!
                            : '-',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildHeroStat(
                        'Company',
                        AuthService.userCompanyName.isNotEmpty
                            ? AuthService.userCompanyName
                            : '-',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Details'),
        const SizedBox(height: 8),
        _buildGroupedCard([
          _buildListRow(Icons.person_outlined, 'Name', AuthService.userName),
          _buildListRow(Icons.phone_outlined, 'Phone', AuthService.userPhone),
          _buildListRow(Icons.business_outlined, 'Type', AuthService.userType),
          _buildListRow(
            Icons.location_city_outlined,
            'City',
            AuthService.userCity,
          ),
          _buildListRow(
            Icons.apartment_outlined,
            'Company',
            AuthService.userCompanyName,
            isLast: false,
          ),
          if (AuthService.userType == 'Broker')
            _buildListRow(
              Icons.verified_outlined,
              'RERA',
              AuthService.userReraNo,
            ),
          _buildListRow(Icons.map_outlined, 'Area', AuthService.userArea),
          _buildListRow(
            Icons.location_on_outlined,
            'Office',
            AuthService.userOfficeAddress,
            isLast: true,
          ),
        ]),
        const SizedBox(height: 24),
        _buildSectionHeader('Account'),
        const SizedBox(height: 8),
        _buildGroupedCard(
          AuthService.isAdmin
              ? [
                  _buildTappableRow(
                    Icons.admin_panel_settings_outlined,
                    'Admin Panel',
                    AppColors.primary,
                    _openAdminPanel,
                  ),
                  _buildTappableRow(
                    Icons.logout_rounded,
                    'Logout',
                    AppColors.iosDestructive,
                    _logout,
                    isLast: true,
                  ),
                ]
              : [
                  _buildTappableRow(
                    Icons.logout_rounded,
                    'Logout',
                    AppColors.iosDestructive,
                    _logout,
                    isLast: true,
                  ),
                ],
        ),
        SizedBox(height: _profileBottomInset),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF12244B), Color(0xFF1C3F86)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit your account details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep your contact and business information up to date.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Read-only'),
          const SizedBox(height: 8),
          _buildGroupedCard([
            _buildInfoRow('Phone', AuthService.userPhone),
            _buildInfoRow('Type', AuthService.userType, isLast: true),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Edit profile'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildFormField('Full Name', _nameCtrl),
                Container(
                  height: 0.5,
                  color: AppColors.iosSeparator.withValues(alpha: 0.3),
                  margin: const EdgeInsets.only(left: 16),
                ),
                _buildFormField('City', _cityCtrl),
                Container(
                  height: 0.5,
                  color: AppColors.iosSeparator.withValues(alpha: 0.3),
                  margin: const EdgeInsets.only(left: 16),
                ),
                _buildFormField(
                  'Company / Agency',
                  _companyCtrl,
                  isLast: false,
                ),
                if (_userType == 'Broker') ...[
                  Container(
                    height: 0.5,
                    color: AppColors.iosSeparator.withValues(alpha: 0.3),
                    margin: const EdgeInsets.only(left: 16),
                  ),
                  _buildFormField('RERA No', _reraCtrl, isOptional: true),
                ],
                Container(
                  height: 0.5,
                  color: AppColors.iosSeparator.withValues(alpha: 0.3),
                  margin: const EdgeInsets.only(left: 16),
                ),
                _buildFormField('Area', _areaCtrl),
                Container(
                  height: 0.5,
                  color: AppColors.iosSeparator.withValues(alpha: 0.3),
                  margin: const EdgeInsets.only(left: 16),
                ),
                _buildFormField('Office Address', _officeCtrl, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _nameCtrl.text = AuthService.userName;
                    _cityCtrl.text = AuthService.userCity;
                    _companyCtrl.text = AuthService.userCompanyName;
                    _reraCtrl.text = AuthService.userReraNo;
                    _areaCtrl.text = AuthService.userArea;
                    _officeCtrl.text = AuthService.userOfficeAddress;
                    _userType = AuthService.userType;
                    setState(() => _isEditing = false);
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: AppColors.iosDestructive,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
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
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Save',
                            style: GoogleFonts.inter(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          SizedBox(height: _profileBottomInset),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.iosSystemBlue),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Text(
                  value.isNotEmpty ? value : '-',
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.darkGray,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Container(
            height: 0.5,
            color: AppColors.iosSeparator.withValues(alpha: 0.3),
            margin: const EdgeInsets.only(left: 52),
          ),
      ],
    );
  }

  Widget _buildTappableRow(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, {
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: color.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
          if (!isLast)
            Container(
              height: 0.5,
              color: AppColors.iosSeparator.withValues(alpha: 0.3),
              margin: const EdgeInsets.only(left: 52),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  value.isNotEmpty ? value : '-',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.darkGray,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Container(
            height: 0.5,
            color: AppColors.iosSeparator.withValues(alpha: 0.3),
            margin: const EdgeInsets.only(left: 16),
          ),
      ],
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController ctrl, {
    bool isLast = false,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextFormField(
        controller: ctrl,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\x00-\x7F]')),
        ],
        style: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.charcoal,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.iosSecondaryLabel,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        validator: (val) {
          return _validateEnglish(val, label: label, isOptional: isOptional);
        },
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}
