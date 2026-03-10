import '../models/subscription_model.dart';
import 'database_service.dart';
import 'auth_service.dart';

/// Manages subscription creation and access control checks.
class SubscriptionService {
  SubscriptionService._();

  // ── Access Check ───────────────────────────────────────────────────────

  /// Returns the current access status for the logged-in user.
  /// Used to decide: allow access | show trial banner | redirect to payment screen.
  static Future<AccessStatus> checkAccess() async {
    final phone = AuthService.userPhone;
    if (phone.isEmpty) return AccessStatus.notLoggedIn;

    final user = await DatabaseService.instance.getUserByPhone(phone);
    if (user == null) return AccessStatus.notLoggedIn;

    if (!user.isActive) return AccessStatus.blocked;

    // Check active subscription
    final sub = await DatabaseService.instance.getActiveSubscription(user.id!);
    if (sub != null && sub.isValid) {
      return AccessStatus.subscribed;
    }

    // Fall back to trial
    if (user.isTrial) return AccessStatus.trial;

    // Trial expired, no subscription
    return AccessStatus.trialExpired;
  }

  /// Quick sync helper — returns true if user can access the app right now.
  static Future<bool> hasAccess() async {
    final status = await checkAccess();
    return status == AccessStatus.trial || status == AccessStatus.subscribed;
  }

  // ── Create Subscription ────────────────────────────────────────────────

  /// Called after a UPI payment is confirmed.
  /// Creates the subscription row and reactivates the user.
  static Future<SubscriptionModel?> activateSubscription({
    required int userId,
    required SubscriptionPlan plan,
    required double amountPaid,
    required String paymentRef,
  }) async {
    // 1. Create subscription in DB
    final sub = await DatabaseService.instance.createSubscription(
      userId:      userId,
      planMonths:  plan.months,
      amountPaid:  amountPaid,
      paymentRef:  paymentRef,
    );

    // 2. Reactivate user + restore hidden properties
    final phone = AuthService.userPhone;
    if (phone.isNotEmpty) {
      await DatabaseService.instance.activateUser(phone);
      await _restoreUserProperties(userId);
    }

    return sub;
  }

  /// Re-shows user's properties that were hidden due to inactivity.
  static Future<void> _restoreUserProperties(int userId) async {
    // Done via DatabaseService which exposes a dedicated method.
    await DatabaseService.instance.restoreUserProperties(userId);
  }

  // ── Inactivity Hide ────────────────────────────────────────────────────

  /// Hides all properties of a user who has been inactive for > 7 days.
  /// Should be run on the backend/admin side, but exposed here for completeness.
  static Future<void> hidePropertiesIfInactive(int userId) async {
    await DatabaseService.instance.hidePropertiesForUser(userId);
  }
}

// ── Access Status Enum ─────────────────────────────────────────────────────────

enum AccessStatus {
  /// User is on free trial (access allowed + trial banner shown).
  trial,

  /// User has a valid paid subscription.
  subscribed,

  /// Free trial has expired, no active subscription — redirect to payment.
  trialExpired,

  /// User account deactivated (inactive > 7 days).
  blocked,

  /// User not logged in.
  notLoggedIn,
}
