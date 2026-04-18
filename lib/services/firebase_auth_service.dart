import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  // serverClientId (client_type: 3) explicitly provided for Vivo/Oppo physical device compatibility
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '191003525122-eummehcouhuople7c08v1fde3loaedja.apps.googleusercontent.com',
  );

  static User? get currentUser => _auth.currentUser;

  /// Sign in with Google. Returns Firebase [User] on success, null on failure.
  static Future<User?> signInWithGoogle() async {
    try {
      // Clear any stale sign-in state (prevents DEVELOPER_ERROR code 10 on physical devices)
      await _googleSignIn.signOut();

      // Trigger Google account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await _auth.signInWithCredential(credential);

      debugPrint('[FirebaseAuthService] Signed in: ${result.user?.email}');
      return result.user;
    } catch (e, st) {
      debugPrint('[FirebaseAuthService] Google Sign-In error: $e');
      debugPrint('[FirebaseAuthService] Stack trace: $st');
      rethrow; // rethrow so UI can distinguish null-cancel vs error
    }
  }

  /// Sign out from both Google and Firebase
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
