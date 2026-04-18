import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_colors.dart';
import '../models/subscription_model.dart';
import '../models/subscription_request_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'home_screen.dart';
import 'landing_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isProcessing = false;
  bool _isLoadingRequest = true;
  SubscriptionPlan _selectedPlan = SubscriptionPlan.monthly;
  final ImagePicker _imagePicker = ImagePicker();
  SubscriptionRequestModel? _latestRequest;
  XFile? _selectedScreenshot;

  static const String _phoneNumber = '9860999991';
  static const String _upiPayeeName = 'One More Deal™';

  int get _amountInRupees {
    switch (_selectedPlan) {
      case SubscriptionPlan.monthly:
        return 3000;
      case SubscriptionPlan.quarterly:
        return 6000;
      case SubscriptionPlan.halfYearly:
        return 12000;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLatestRequest();
    _checkIfBlocked();
  }
  
  bool _isBlocked = false;
  
  Future<void> _checkIfBlocked() async {
    final user = await DatabaseService.instance.getUserByPhone(AuthService.userPhone);
    if (!mounted || user == null) return;

    final isBuilderUser =
        user.userType?.value == 'Builder' || user.userType?.value == 'Developer';
    if (!isBuilderUser) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
      return;
    }

    if (!user.isActive) {
      setState(() => _isBlocked = true);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<int?> _resolveUserId() async {
    var userId = AuthService.currentUserId;
    if (userId != null) return userId;
    final user = await DatabaseService.instance.getUserByPhone(AuthService.userPhone);
    return user?.id;
  }

  Future<void> _loadLatestRequest() async {
    final userId = await _resolveUserId();
    if (userId != null) {
      final request = await DatabaseService.instance.getLatestSubscriptionRequestForUser(userId);
      if (!mounted) return;
      setState(() {
        _latestRequest = request;
        _isLoadingRequest = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isLoadingRequest = false);
  }

  Future<void> _openUpiApp() async {
    final String upiAddress = '$_phoneNumber@upi';
    // IMPORTANT: Do not url-encode the UPI address, GPay fails to parse '%40'
    final String urlStr = 'upi://pay?pa=$upiAddress&pn=${Uri.encodeComponent(_upiPayeeName)}&am=$_amountInRupees&cu=INR&tn=OMD+Subscription';
    final uri = Uri.parse(urlStr);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No UPI app found. Please use the shown phone number in your payment app.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _pickScreenshot() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (!mounted || file == null) return;
    setState(() => _selectedScreenshot = file);
  }

  Future<void> _submitManualRequest() async {
    if (_selectedScreenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a payment screenshot first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final userId = await _resolveUserId();
    if (userId == null) return;

    setState(() => _isProcessing = true);
    final bytes = await File(_selectedScreenshot!.path).readAsBytes();
    final screenshotBase64 = base64Encode(bytes);

    final request = await DatabaseService.instance.upsertSubscriptionRequest(
      userId: userId,
      planMonths: _selectedPlan.months,
      amountPaid: _amountInRupees.toDouble(),
      screenshotBase64: screenshotBase64,
    );

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _latestRequest = request;
      _selectedScreenshot = null;
    });

    if (request == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to submit your request right now.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment request sent to admin for approval.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = _latestRequest;
    final isPending = request?.status == SubscriptionRequestStatus.pending;
    final isRejected = request?.status == SubscriptionRequestStatus.rejected;
    final isApproved = request?.status == SubscriptionRequestStatus.approved;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 50,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_isBlocked) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.block_rounded,
                                color: AppColors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Account Blocked',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Your account has been blocked. Make a payment below to reactivate your account.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: AppColors.white.withValues(alpha: 0.9),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                        'Pay from any UPI app and send the request to admin for approval.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: AppColors.white.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ...[
                              SubscriptionPlan.monthly,
                              SubscriptionPlan.quarterly,
                            ].map((plan) {
                              final amount = switch (plan) {
                                SubscriptionPlan.monthly => 3000,
                                SubscriptionPlan.quarterly => 6000,
                                SubscriptionPlan.halfYearly => 12000,
                              };

                              return GestureDetector(
                                onTap: () => setState(() => _selectedPlan = plan),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedPlan == plan
                                        ? AppColors.accent.withValues(alpha: 0.1)
                                        : AppColors.offWhite,
                                    border: Border.all(
                                      color: _selectedPlan == plan
                                          ? AppColors.accent
                                          : AppColors.lightGray,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _selectedPlan == plan
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: _selectedPlan == plan
                                            ? AppColors.accent
                                            : AppColors.mediumGray,
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
                                        'Rs $amount',
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
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.offWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.lightGray),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pay with UPI',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.charcoal,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Amount: Rs $_amountInRupees',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Phone Number: $_phoneNumber',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkGray,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _openUpiApp,
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(double.infinity, 52),
                                        side: const BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      icon: const Icon(Icons.open_in_new_rounded),
                                      label: Text(
                                        'Open UPI App',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Complete the payment, then upload the payment screenshot and send it to admin.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      height: 1.45,
                                      color: AppColors.darkGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _pickScreenshot,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 52),
                                  side: const BorderSide(color: AppColors.accent),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.upload_file_rounded),
                                label: Text(
                                  _selectedScreenshot == null
                                      ? 'Upload Payment Screenshot'
                                      : 'Screenshot Selected',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            if (_selectedScreenshot != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _selectedScreenshot!.name,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkGray,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (_isLoadingRequest)
                              const Center(
                                child: CircularProgressIndicator(color: AppColors.accent),
                              )
                            else if (isPending)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  'Payment screenshot submitted. Waiting for admin approval.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            else if (isRejected)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.error.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Previous request rejected',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      request?.rejectionReason ?? 'No reason shared.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkGray,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Upload a new screenshot and submit again.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.darkGray,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isApproved)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.success.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  'Your subscription is active.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              )
                            else if (_isProcessing)
                              const Center(
                                child: CircularProgressIndicator(color: AppColors.accent),
                              ),
                            if (!isApproved && !_isLoadingRequest && !_isProcessing) ...[
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: _submitManualRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  isPending
                                      ? 'Update Screenshot'
                                      : isRejected
                                          ? 'Re-submit With New Screenshot'
                                          : 'I Have Paid - Send For Approval',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
