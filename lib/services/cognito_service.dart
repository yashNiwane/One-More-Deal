import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
// Android applicationId / iOS Bundle ID should have the redirect URI configured.

class CognitoService {
  // Replace these with your actual Cognito User Pool details
  static const String _clientId = 'vpj04d43n0i551ic28d3o4kbq';
  static const String _domain = 'ap-south-1whjl5xhgt.auth.ap-south-1.amazoncognito.com';
  static const String _redirectUrl = 'onemoredeal://oauth2-callback';

  /// Initiates the OAuth2 flow with Google via AWS Cognito Hosted UI
  static Future<bool> signInWithGoogle() async {
    try {
      debugPrint('[CognitoService] Initiating Google Sign-In...');
      
      final result = await const FlutterAppAuth().authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: 'https://$_domain/oauth2/authorize',
            tokenEndpoint: 'https://$_domain/oauth2/token',
          ),
          scopes: ['openid', 'email', 'profile'],
        ),
      );
      
      final idToken = result?.idToken;
      if (idToken == null) return false;
      
      // Successfully authenticated
      debugPrint('[CognitoService] Success. ID Token: $idToken');
      
      return true; 
    } catch (e) {
      debugPrint('[CognitoService] Google SignIn Error: $e');
      return false;
    }
  }
}
