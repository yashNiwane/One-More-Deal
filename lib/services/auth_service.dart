import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../models/user_model.dart';

/// Manages authentication state.
/// SharedPreferences = fast local session cache.
/// DatabaseService   = source of truth in AWS RDS.
class AuthService {
  AuthService._();

  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUserPhone = 'user_phone';
  static const _keySessionToken = 'session_token';
  static const _keyProfileComplete = 'profile_complete';

  static SharedPreferences? _prefs;
  static UserModel? _currentUser;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Hydrate user details from DB on app launch
    if (isLoggedIn && userPhone.isNotEmpty) {
      try {
        _currentUser = await DatabaseService.instance.getUserByPhone(userPhone);
        // Sync local cache with DB truth
        if (_currentUser?.name?.trim().isNotEmpty == true) {
          await _p.setBool(_keyProfileComplete, true);
        }
      } catch (e) {
        debugPrint('[AUTH] Init Network Error: $e — using local cache');
      }
    }
  }

  static SharedPreferences get _p {
    if (_prefs == null) throw Exception('AuthService not initialized');
    return _prefs!;
  }

  // ── Login (called after OTP verified) ────────────────────────────────

  static String? tempLoginError;

  static Future<bool> loginWithGoogle(String email) async {
    final token = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
    try {
      final user = await DatabaseService.instance.getUserByEmail(email);
      if (user != null) {
        final updatedUser = await DatabaseService.instance.upsertUser(phone: user.phone, sessionToken: token, email: email);
        if (updatedUser != null) {
          _currentUser = updatedUser;
          if (updatedUser.name?.trim().isNotEmpty == true) {
            await _p.setBool(_keyProfileComplete, true);
          }
          await _p.setBool(_keyIsLoggedIn, true);
          await _p.setString(_keyUserPhone, updatedUser.phone);
          await _p.setString(_keySessionToken, token);
          debugPrint('[AUTH] loginWithGoogle OK - logged in existing user: $email');
          return true;
        }
      }
      return false; // Not registered yet
    } catch (e, st) {
      debugPrint('[AUTH] loginWithGoogle error: $e\n$st');
      return false;
    }
  }

  static Future<void> loginUser(String phone, {String? googleEmail}) async {
    final token = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';

    try {
      if (googleEmail != null) {
        final existingUser = await DatabaseService.instance.getUserByPhone(phone);
        if (existingUser != null && existingUser.email != null && existingUser.email != googleEmail) {
          throw Exception('This mobile number is linked to another Google account. Please use a different number or sign in with the correct Google account.');
        }
      }

      final user = await DatabaseService.instance.upsertUser(phone: phone, sessionToken: token, email: googleEmail);
      if (user != null) {
        _currentUser = user;
        // Cache profile status locally
        if (user.name?.trim().isNotEmpty == true) {
          await _p.setBool(_keyProfileComplete, true);
        }

        await _p.setBool(_keyIsLoggedIn, true);
        await _p.setString(_keyUserPhone, phone);
        await _p.setString(_keySessionToken, token);
        debugPrint('[AUTH] loginUser OK — userId=${user.id}, phone=$phone, isActive=${user.isActive}');
      } else {
        throw Exception('Failed to upsert user record in database');
      }
    } catch (e, st) {
      debugPrint('[AUTH] loginUser DB ERROR: $e\n$st');
      rethrow;
    }
  }

  // ── Profile Setup ───────────────────────────────────────────────────

  static Future<void> saveProfile({
    required String name,
    required String userType,
    required String city,
    required String companyName,
    String? reraNo,
    String? area,
    String? officeAddress,
  }) async {
    try {
      await DatabaseService.instance.updateUserProfile(
        phone: userPhone,
        name: name,
        userType: userType,
        city: city,
        companyName: companyName,
        reraNo: reraNo,
        area: area,
        officeAddress: officeAddress,
      );
      // Re-hydrate dynamically instead of trusting local updates
      _currentUser = await DatabaseService.instance.getUserByPhone(userPhone);
      await _p.setBool(_keyProfileComplete, true);
      debugPrint('[AUTH] saveProfile OK — phone=$userPhone, name=$name');
    } catch (e) {
      debugPrint('[AUTH] saveProfile DB ERROR: $e');
    }
  }

  // ── Stats (HomeScreen) ──────────────────────────────────────────────

  static Future<Map<String, int>> getUserStats() async {
    try {
      return await DatabaseService.instance.getUserStats(userPhone);
    } catch (_) {
      return {
        'listings': 0,
        'enquiries': 0,
        'trialDaysLeft': 0,
        'dealsClosed': 0,
      };
    }
  }

  // ── Memory Getters (NO LOCAL PREFS EXCEPT FLAGS) ────────────────────

  static bool get isLoggedIn => _p.getBool(_keyIsLoggedIn) ?? false;
  static String get userPhone => _p.getString(_keyUserPhone) ?? '';
  static UserModel? get currentUser => _currentUser;

  static const Set<String> _adminPhoneLast10 = {
    '9356965876',
    '9158120359',
    '9209182221',
    '9356965875',
  };

  static String _digitsOnly(String s) => s.replaceAll(RegExp(r'\\D'), '');

  static String _last10Digits(String s) {
    final d = _digitsOnly(s);
    if (d.length <= 10) return d;
    return d.substring(d.length - 10);
  }

  static bool get isAdmin => _adminPhoneLast10.contains(_last10Digits(userPhone));

  static bool get isProfileComplete {
    // Primary: check in-memory user
    if (_currentUser?.name?.trim().isNotEmpty == true) return true;
    // Fallback: check local cache (survives DB failures)
    return _p.getBool(_keyProfileComplete) ?? false;
  }

  static String get userName => _currentUser?.name ?? '';
  static String get userType => _currentUser?.userType?.value ?? 'Broker';
  static String get userCity => _currentUser?.city ?? '';
  static String get userCompanyName => _currentUser?.companyName ?? '';
  static int? get currentUserId => _currentUser?.id;
  static String? get userCode => _currentUser?.userCode;
  static String get userReraNo => _currentUser?.reraNo ?? '';
  static String get userArea => _currentUser?.area ?? '';
  static String get userOfficeAddress => _currentUser?.officeAddress ?? '';

  // ── Session Validation ──────────────────────────────────────────────

  static Future<bool> isSessionValid() async {
    if (!isLoggedIn || userPhone.isEmpty) return false;
    try {
      final user = await DatabaseService.instance.getUserByPhone(userPhone);
      if (user == null) return false;
      
      // Update current user but don't block here - let hasActiveSubscription handle it
      _currentUser = user;

      final localToken = _p.getString(_keySessionToken);
      if (user.currentSessionToken != null &&
          user.currentSessionToken != localToken) {
        debugPrint(
          '[AUTH] Session hijacked/expired. Local: $localToken, DB: ${user.currentSessionToken}',
        );
        return false;
      }
      return true;
    } catch (_) {
      return true; // allow offline continuity
    }
  }

  // ── Subscription Checks ─────────────────────────────────────────────

  static Future<bool> hasActiveSubscription() async {
    if (!isLoggedIn || userPhone.isEmpty) return false;
    try {
      final user = await DatabaseService.instance.getUserByPhone(userPhone);
      if (user == null) return false;

      final userType = (user.userType?.value ?? '').trim().toLowerCase();
      if (userType == 'broker') {
        // Brokers are free users now. Keep them active even if old billing logic disabled them.
        if (!user.isActive) {
          await DatabaseService.instance.activateUser(user.phone);
          _currentUser = await DatabaseService.instance.getUserByPhone(userPhone);
        } else {
          _currentUser = user;
        }
        return true;
      }

      final isBuilderUser = userType == 'builder' || userType == 'developer';
      if (isBuilderUser) {
        final paymentsEnabled = await DatabaseService.instance.isFeatureEnabled(
          'builder_payments_enabled',
          fallback: false,
        );
        if (!paymentsEnabled) {
          if (!user.isActive) {
            await DatabaseService.instance.activateUser(user.phone);
            _currentUser =
                await DatabaseService.instance.getUserByPhone(user.phone);
          } else {
            _currentUser = user;
          }
          return true;
        }
      }
      
      // Check if user is blocked
      if (!user.isActive) {
        debugPrint('[AUTH] User is blocked - no active subscription: $userPhone');
        return false;
      }
      
      _currentUser = user; // keep in sync

      if (user.isTrial) {
        debugPrint('[AUTH] hasActiveSubscription -> isTrial true (days left: ${user.trialDaysLeft})');
        return true;
      }

      final sub = await DatabaseService.instance.getActiveSubscription(user.id);
      if (sub != null && sub.isValid) {
        debugPrint('[AUTH] hasActiveSubscription -> sub valid');
        return true;
      }

      debugPrint('[AUTH] hasActiveSubscription -> NO active sub & NO trial');
      if (user.isActive) {
        debugPrint('[AUTH] Auto-deactivating expired user: ${user.phone}');
        await DatabaseService.instance.deactivateUser(user.phone);
      }
      
      return false;
    } catch (e, st) {
      debugPrint('[AUTH] hasActiveSubscription Error: $e\n$st');
      return false; // Security fix: Do not default to true on errors
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────

  static Future<void> logout() async {
    _currentUser = null;
    await _p.clear();
  }
}
