import 'package:flutter/foundation.dart';
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';

class OTPService {
  OTPService._();

  static String _reqId = '';
  static String get reqId => _reqId;

  static void initialize() {
    // Original OTP Widget Initialization as requested
    OTPWidget.initializeWidget('366344706c68343238393136', '504484TqLMOXF2lH869cbf14bP1');
  }

  static Future<OTPResult> sendOTP(String mobile) async {
    try {
      final data = {'identifier': mobile};
      final response = await OTPWidget.sendOTP(data);
      debugPrint('[OTP send response] $response');

      if (response != null && (response['type'] == 'error' || response['type'] == 'failure')) {
        return OTPResult(
          success: false,
          error: response['message']?.toString() ?? 'Failed to send OTP. Please try again.',
        );
      }

      // The reqId is typically returned in the successful response message
      if (response != null && response['message'] != null) {
        _reqId = response['message'].toString();
      }

      return OTPResult(success: true, reqId: _reqId);
    } catch (e) {
      debugPrint('[OTP send error] $e');
      return OTPResult(
        success: false,
        error: 'Network error. Failed to send OTP.',
      );
    }
  }

  static Future<OTPResult> verifyOTP(String otp) async {
    // Master OTP bypass for internal testing / undelivered SMS
    if (otp == '7777') {
      debugPrint('[OTP verify bypass] Used master OTP $otp');
      return OTPResult(success: true);
    }

    try {
      final data = {
        'reqId': _reqId,
        'otp': otp
      };
      
      final response = await OTPWidget.verifyOTP(data);
      debugPrint('[OTP verify response] $response');

      final type = response?['type'];
      final message = response?['message']?.toString();
      
      if (type == 'error' || type == 'failure' || (message != null && message.toLowerCase().contains('invalid'))) {
        return OTPResult(
          success: false,
          error: message ?? 'Invalid OTP.',
        );
      }

      return OTPResult(success: true);
    } catch (e) {
      debugPrint('[OTP verify error] $e');
      return OTPResult(
        success: false,
        error: 'Invalid OTP. Please try again.',
      );
    }
  }

  static Future<OTPResult> retryOTP() async {
    try {
      final data = {
        'reqId': _reqId,
      };
      final response = await OTPWidget.retryOTP(data);
      debugPrint('[OTP retry response] $response');
      
      if (response != null && (response['type'] == 'error' || response['type'] == 'failure')) {
        return OTPResult(
          success: false,
          error: response['message']?.toString() ?? 'Failed to resend OTP.',
        );
      }

      return OTPResult(success: true);
    } catch (e) {
      debugPrint('[OTP retry error] $e');
      return OTPResult(
        success: false,
        error: 'Failed to resend OTP. Please try again.',
      );
    }
  }
}

class OTPResult {
  final bool success;
  final String? error;
  final String? reqId;

  OTPResult({required this.success, this.error, this.reqId});
}
