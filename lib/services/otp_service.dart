/// Mock OTP Service — uses hardcoded OTP "123456" for testing.
/// Replace with real MSG91 integration when ready.
class OTPService {
  OTPService._();

  static String _reqId = '';
  static String _mockPhone = '';
  static String get reqId => _reqId;

  /// Simulates sending OTP. Always succeeds.
  static Future<OTPResult> sendOTP(String mobile) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    _mockPhone = mobile;
    _reqId = 'MOCK_REQ_${DateTime.now().millisecondsSinceEpoch}';
    return OTPResult(success: true, reqId: _reqId);
  }

  /// Accepts "123456" as the valid OTP, rejects anything else.
  static Future<OTPResult> verifyOTP(String otp) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (otp == '123456') {
      return OTPResult(success: true);
    }
    return OTPResult(
      success: false,
      error: 'Invalid OTP. Use 123456 for testing.',
    );
  }

  /// Simulates OTP resend.
  static Future<OTPResult> retryOTP() async {
    await Future.delayed(const Duration(seconds: 1));
    return OTPResult(success: true);
  }

  static void initialize() {}
}

class OTPResult {
  final bool success;
  final String? error;
  final String? reqId;

  OTPResult({required this.success, this.error, this.reqId});
}
