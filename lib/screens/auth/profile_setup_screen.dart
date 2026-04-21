import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/gradient_button.dart';
import '../home_screen.dart';
import '../subscription_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _companyController = TextEditingController();
  final _reraController = TextEditingController();
  final _areaController = TextEditingController();
  final _officeAddressController = TextEditingController();
  String _userType = 'Broker';
  bool _isSaving = false;
  static final RegExp _englishAsciiRegex = RegExp(r'^[\x00-\x7F]+$');

  String? _validateEnglish(
    String? value, {
    required String fieldName,
    bool requiredField = true,
  }) {
    final text = value?.trim() ?? '';
    if (requiredField && text.isEmpty) return 'Please enter $fieldName';
    if (text.isEmpty) return null;
    if (!_englishAsciiRegex.hasMatch(text)) {
      return 'Only English characters are allowed';
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _companyController.dispose();
    _reraController.dispose();
    _areaController.dispose();
    _officeAddressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await AuthService.saveProfile(
      name: _nameController.text.trim(),
      userType: _userType,
      city: _cityController.text.trim(),
      companyName: _companyController.text.trim(),
      reraNo: _userType == 'Broker' ? _reraController.text.trim() : null,
      area: _areaController.text.trim(),
      officeAddress: _officeAddressController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    HapticFeedback.heavyImpact();

    // Show congratulations and trial details before proceeding
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _FreeTrialDialog(),
    );

    if (!mounted) return;
    // Use direct push but still check subscription to prevent bypass
    final isBuilderUser = _userType == 'Builder' || _userType == 'Developer';
    final hasSub = isBuilderUser
        ? await AuthService.hasActiveSubscription()
        : true;
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            hasSub ? const HomeScreen() : const SubscriptionScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      // ─── Use CustomScrollView with SliverAppBar so layout is correct ─
      body: CustomScrollView(
        slivers: [
          // ─── Hero header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: false,
            floating: false,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.none,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -60,
                      left: -60,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    // Header text — positioned from bottom so it stays above the sheet
                    Positioned(
                      left: 28,
                      right: 28,
                      bottom: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '🎉 Almost there!',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.accentLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Complete your\nprofile',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Just a few details to personalize your experience.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status bar padding at top
                    Positioned(
                      top: topPad + 12,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Form content ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Full Name ────────────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      child: const _Label('Full Name'),
                    ),
                    const SizedBox(height: 8),
                    FadeInUp(
                      duration: const Duration(milliseconds: 350),
                      child: TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\x00-\x7F]'),
                          ),
                        ],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Your full name',
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        validator: (v) {
                          final englishError = _validateEnglish(
                            v,
                            fieldName: 'your full name',
                          );
                          if (englishError != null) return englishError;
                          if ((v?.trim().length ?? 0) < 2)
                            return 'Name too short';
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── User Type ────────────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      child: const _Label('I am a'),
                    ),
                    const SizedBox(height: 12),
                    FadeInUp(
                      duration: const Duration(milliseconds: 450),
                      child: Row(
                        children: [
                          _UserTypeCard(
                            label: 'Broker',
                            emoji: '🤝',
                            description: 'I connect\nbuyers & sellers',
                            isSelected: _userType == 'Broker',
                            onTap: () => setState(() => _userType = 'Broker'),
                          ),
                          const SizedBox(width: 14),
                          _UserTypeCard(
                            label: 'Builder',
                            emoji: '🏗',
                            description: 'I build & sell\nproperties',
                            isSelected: _userType == 'Builder',
                            onTap: () => setState(() => _userType = 'Builder'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── City ─────────────────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      child: const _Label('City'),
                    ),
                    const SizedBox(height: 8),
                    FadeInUp(
                      duration: const Duration(milliseconds: 550),
                      child: TextFormField(
                        controller: _cityController,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\x00-\x7F]'),
                          ),
                        ],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter your city',
                          prefixIcon: Icon(
                            Icons.location_city_rounded,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        validator: (v) =>
                            _validateEnglish(v, fieldName: 'your city'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Company/Firm Name ────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 550),
                      child: const _Label('Company/Firm Name (Optional)'),
                    ),
                    const SizedBox(height: 8),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: TextFormField(
                        controller: _companyController,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\x00-\x7F]'),
                          ),
                        ],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter your company or firm name',
                          prefixIcon: Icon(
                            Icons.business_rounded,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        validator: (v) => _validateEnglish(
                          v,
                          fieldName: 'your company or firm name',
                          requiredField: false,
                        ),
                      ),
                    ),

                    if (_userType == 'Broker') ...[
                      const SizedBox(height: 24),
                      FadeInUp(
                        duration: const Duration(milliseconds: 650),
                        child: const _Label('RERA Number (Optional)'),
                      ),
                      const SizedBox(height: 8),
                      FadeInUp(
                        duration: const Duration(milliseconds: 700),
                        child: TextFormField(
                          controller: _reraController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[\x00-\x7F]'),
                            ),
                          ],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter your RERA No.',
                            prefixIcon: Icon(
                              Icons.verified_rounded,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          validator: (v) => _validateEnglish(
                            v,
                            fieldName: 'your RERA Number',
                            requiredField: false,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      child: const _Label('Area'),
                    ),
                    const SizedBox(height: 8),
                    FadeInUp(
                      duration: const Duration(milliseconds: 750),
                      child: TextFormField(
                        controller: _areaController,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\x00-\x7F]'),
                          ),
                        ],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Shivaji Nagar',
                          prefixIcon: Icon(
                            Icons.map_rounded,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        validator: (v) =>
                            _validateEnglish(v, fieldName: 'your area'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      duration: const Duration(milliseconds: 750),
                      child: const _Label('Office Address'),
                    ),
                    const SizedBox(height: 8),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: TextFormField(
                        controller: _officeAddressController,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\x00-\x7F]'),
                          ),
                        ],
                        maxLines: 2,
                        minLines: 1,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Full office address',
                          prefixIcon: Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        validator: (v) => _validateEnglish(
                          v,
                          fieldName: 'your office address',
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    if (AuthService.tempLoginError != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Login DB Error:\n${AuthService.tempLoginError}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    // ── Submit ───────────────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 750),
                      child: GradientButton(
                        label: 'Complete Setup',
                        icon: Icons.check_circle_outline_rounded,
                        isLoading: _isSaving,
                        onPressed: _save,
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        color: AppColors.darkGray,
        fontSize: 13,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final String label;
  final String emoji;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.label,
    required this.emoji,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.lightGray,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.white : AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isSelected
                      ? AppColors.white.withValues(alpha: 0.7)
                      : AppColors.mediumGray,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? AppColors.accent : AppColors.lightGray,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreeTrialDialog extends StatelessWidget {
  const _FreeTrialDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                size: 50,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to OMD Broker Associates!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your profile is complete.\nYou are all set to start exploring and posting properties.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.mediumGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Let\'s Get Started',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
