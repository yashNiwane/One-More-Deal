import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../services/database_service.dart';
import '../../services/otp_service.dart';
import '../../widgets/gradient_button.dart';
import 'otp_verification_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  final bool isLogin;
  const PhoneAuthScreen({super.key, required this.isLogin});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _phoneFocus.requestFocus());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final phone = _phoneController.text.trim();

    try {
      final user = await DatabaseService.instance.getUserByPhone(phone);
      final exists = user != null;

      if (widget.isLogin && !exists) {
        setState(() {
          _isLoading = false;
          _errorText = 'Account not found. Please go back and Sign Up.';
        });
        HapticFeedback.vibrate();
        return;
      }
      
      if (!widget.isLogin && exists) {
        setState(() {
          _isLoading = false;
          _errorText = 'Account already exists. Please go back and Sign In.';
        });
        HapticFeedback.vibrate();
        return;
      }
    } catch (e) {
      // If DB check fails, we still allow proceeding (OTP takes over)
    }

    final result = await OTPService.sendOTP(phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) =>
              OTPVerificationScreen(phone: phone),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      );
    } else {
      setState(() => _errorText = result.error);
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ─── Top hero section ─────────────────────────────────────
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.42,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  AppAssets.agentsHandshake,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.primary),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x660D1B4B),
                        Color(0xFF0D1B4B),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 36,
                  left: 28,
                  right: 28,
                  child: FadeInDown(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isLogin ? 'Welcome back,' : 'Get started,',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: widget.isLogin ? 'Sign in to\nOne More Deal' : 'Create an\naccount',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              if (widget.isLogin)
                                TextSpan(
                                  text: '\nOMD Broker Associate',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.accentLight,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    height: 1.8,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Back button ──────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),

          // ─── Form sheet ───────────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.63,
            minChildSize: 0.63,
            maxChildSize: 0.95,
            builder: (_, controller) {
              return FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Text(
                                  'Enter your\nmobile number',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.charcoal,
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'We\'ll send you a 6-digit OTP to verify your number.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.mediumGray,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Phone input
                                Text(
                                  'Mobile Number',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkGray,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _phoneController,
                                  focusNode: _phoneFocus,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.charcoal,
                                    letterSpacing: 2,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '9876543210',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      color: AppColors.mediumGray,
                                      fontSize: 18,
                                      letterSpacing: 2,
                                    ),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 16),
                                      child: Text(
                                        '+91 |',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    prefixIconConstraints:
                                        const BoxConstraints(),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please enter your mobile number';
                                    }
                                    if (v.length != 10) {
                                      return 'Enter a valid 10-digit number';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _sendOTP(),
                                ),

                                // Error message
                                if (_errorText != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.error.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.error
                                              .withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: AppColors.error,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _errorText!,
                                            style: GoogleFonts.plusJakartaSans(
                                              color: AppColors.error,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 36),

                                GradientButton(
                                  label: AppStrings.sendOTP,
                                  icon: Icons.send_rounded,
                                  isLoading: _isLoading,
                                  onPressed: _sendOTP,
                                ),

                                const SizedBox(height: 24),

                                // Trust badges
                                _TrustBadges(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrustBadges extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Badge(icon: Icons.lock_outline_rounded, label: 'Secure OTP'),
        const SizedBox(width: 16),
        _Badge(icon: Icons.verified_rounded, label: 'Verified'),
        const SizedBox(width: 16),
        _Badge(icon: Icons.phone_android_rounded, label: 'Mobile Only'),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
