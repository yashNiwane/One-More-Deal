import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/subscription_model.dart';
import 'landing_screen.dart';
import 'home_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  SubscriptionPlan _selectedPlan = SubscriptionPlan.monthly;

  void _setProcessing(bool value) {
    if (!mounted) return;
    setState(() => _isProcessing = value);
  }

  int get _amountInRupees {
    switch (_selectedPlan) {
      case SubscriptionPlan.monthly: return 500;
      case SubscriptionPlan.quarterly: return 1200;
      case SubscriptionPlan.halfYearly: return 2000;
    }
  }

  int get _amountInPaise => _amountInRupees * 100;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear(); // Removes all listeners
    super.dispose();
  }

  void _openCheckout() {
    _setProcessing(true);
    var options = {
      'key': 'rzp_test_SMqkvl2TaygPEM',
      'amount': _amountInPaise,
      'name': 'One More Deal',
      'description': '${_selectedPlan.label} Premium Upgrade',
      'prefill': {
        'contact': AuthService.userPhone,
        'email': ''
      },
      'theme': {
        'color': '#112255' // matches AppColors.primary
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
      _setProcessing(false);
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    int? userId = AuthService.currentUserId;
    if (userId == null) {
      final user = await DatabaseService.instance.getUserByPhone(AuthService.userPhone);
      userId = user?.id;
    }

    if (!mounted) return;

    if (userId != null) {
      final sub = await DatabaseService.instance.createSubscription(
        userId: userId,
        planMonths: _selectedPlan.months,
        amountPaid: _amountInRupees.toDouble(),
        paymentRef: response.paymentId ?? 'UNKNOWN_REF',
      );
      if (sub != null) {
        await AuthService.hasActiveSubscription(); // refresh cache
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Successful! Subscription activated.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
        return;
      }
    }
    
    // Fallback if db error
    _setProcessing(false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment processed but failed to update subscription. Please contact support.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _setProcessing(false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message ?? "Unknown error"}'), backgroundColor: AppColors.error,),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _setProcessing(false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent going back
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withOpacity(0.1),
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, size: 50, color: Colors.amber),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Unlock Full Access',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your free trial has ended. Subscribe now to continue connecting with buyers, managing listings, and closing deals faster!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: AppColors.white.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Payment Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Plan Selectors
                            ...SubscriptionPlan.values.map((plan) {
                              final int amount = plan == SubscriptionPlan.monthly ? 500 
                                  : plan == SubscriptionPlan.quarterly ? 1200 : 2000;
                                  
                              return GestureDetector(
                                onTap: () => setState(() => _selectedPlan = plan),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedPlan == plan ? AppColors.accent.withOpacity(0.1) : AppColors.offWhite,
                                    border: Border.all(
                                      color: _selectedPlan == plan ? AppColors.accent : AppColors.lightGray,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _selectedPlan == plan ? Icons.radio_button_checked : Icons.radio_button_off,
                                        color: _selectedPlan == plan ? AppColors.accent : AppColors.mediumGray,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          plan.label,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.charcoal,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '₹$amount',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                            const SizedBox(height: 16),
                            _isProcessing
                                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                                : ElevatedButton(
                                    onPressed: _openCheckout,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                      minimumSize: const Size(double.infinity, 56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      'Pay ₹$_amountInRupees & Continue',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: TextButton.icon(
                  onPressed: () async {
                    await AuthService.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LandingScreen()),
                        (_) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                  label: Text(
                    'Logout',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
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
