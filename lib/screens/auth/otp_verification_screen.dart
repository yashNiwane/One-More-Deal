import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../services/otp_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/gradient_button.dart';
import 'profile_setup_screen.dart';
import '../home_screen.dart';
import '../subscription_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phone;
  const OTPVerificationScreen({super.key, required this.phone});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with TickerProviderStateMixin {
  final _otpController = TextEditingController();
  final _pinFocus = FocusNode();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorText;
  int _resendCountdown = 30;
  Timer? _timer;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -8.0, end: 6.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 6.0, end: -6.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
  }

  void _startTimer() {
    _resendCountdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown <= 0) {
        t.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _pinFocus.dispose();
    _shakeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      setState(() => _errorText = 'Please enter the complete 4-digit OTP');
      _shakeController.forward(from: 0);
      HapticFeedback.vibrate();
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    final result = await OTPService.verifyOTP(otp);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result.success) {
      HapticFeedback.heavyImpact();

      try {
        await AuthService.loginUser(widget.phone);

        if (!mounted) return;
        
        // Check if user is blocked - builder/developer go to subscription screen.
        // Brokers are free users and should continue to app.
        final user = await DatabaseService.instance.getUserByPhone(widget.phone);
        final isBuilderUser = user?.userType?.value == 'Builder' || user?.userType?.value == 'Developer';
        if (user != null && !user.isActive && isBuilderUser) {
          debugPrint('[OTP] User is blocked - navigating to subscription screen');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            (_) => false,
          );
          return;
        }
        
        // Navigate to profile setup if no profile, else home
        bool isProfileDone = AuthService.isProfileComplete;

        // Fallback check: Fetch from Database to ensure no local cache failure
        if (!isProfileDone) {
          try {
            if (user != null &&
                user.name != null &&
                user.name!.trim().isNotEmpty) {
              isProfileDone = true;
            }
          } catch (_) {}
        }

        if (!isProfileDone) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => const ProfileSetupScreen(),
              transitionDuration: const Duration(milliseconds: 400),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
        } else {
          await _navigateToHome();
        }
      } catch (e) {
        if (!mounted) return;
        
        setState(() {
          _errorText = 'Network Error. Check your connection and try again.';
          _isVerifying = false;
        });
        _shakeController.forward(from: 0);
        HapticFeedback.heavyImpact();
      }
    } else {
      if (!mounted) return;
      setState(() => _errorText = result.error);
      _shakeController.forward(from: 0);
      HapticFeedback.vibrate();
    }
  }

  Future<void> _navigateToHome() async {
    final hasSub = await AuthService.hasActiveSubscription();
    if (!mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => hasSub ? const HomeScreen() : const SubscriptionScreen()),
      (_) => false,
    );
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() => _isResending = true);
    final result = await OTPService.retryOTP();

    if (!mounted) return;
    setState(() => _isResending = false);

    if (result.success) {
      _startTimer();
      _otpController.clear();
      setState(() => _errorText = null);
      _showSnack('OTP resent successfully!', isError: false);
    } else {
      _showSnack(result.error ?? 'Failed to resend OTP', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 58,
      textStyle: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.primaryLight, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    final filledPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.primary.withValues(alpha: 0.06),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.error, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.charcoal,
              size: 18,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              FadeInDown(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // OTP icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text('🔐', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Verify your\nnumber',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                        height: 1.2,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        text: 'OTP sent to ',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.mediumGray,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: '+91 ${widget.phone}',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ─── PIN Input ──────────────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_shakeAnim.value, 0),
                    child: child,
                  ),
                  child: Center(
                    child: Pinput(
                      controller: _otpController,
                      focusNode: _pinFocus,
                      length: 4,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: filledPinTheme,
                      errorPinTheme: errorPinTheme,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      closeKeyboardWhenCompleted: true,
                      hapticFeedbackType: HapticFeedbackType.lightImpact,
                      onCompleted: (_) => _verify(),
                      cursor: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 9),
                            width: 22,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Error ──────────────────────────────────────────────
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                FadeIn(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
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
                ),
              ],

              const SizedBox(height: 32),

              // ─── Verify button ──────────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: GradientButton(
                  label: AppStrings.verifyOTP,
                  icon: Icons.verified_rounded,
                  isLoading: _isVerifying,
                  onPressed: _verify,
                ),
              ),

              const SizedBox(height: 28),

              // ─── Resend section ─────────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Center(
                  child: Column(
                    children: [
                      if (_resendCountdown > 0)
                        Text.rich(
                          TextSpan(
                            text: AppStrings.didntReceive,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.mediumGray,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: 'Resend in ${_resendCountdown}s',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _resendOTP,
                          child: _isResending
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryLight,
                                  ),
                                )
                              : Text.rich(
                                  TextSpan(
                                    text: AppStrings.didntReceive,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.mediumGray,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: AppStrings.resendOTP,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.primaryLight,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      const SizedBox(height: 20),
                      // Security note
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.security_rounded,
                              color: AppColors.primaryLight,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'OTP expires in 10 minutes',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.primaryLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
