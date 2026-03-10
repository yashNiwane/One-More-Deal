/// Mirrors the `subscriptions` table row.
class SubscriptionModel {
  final int id;
  final int userId;
  final int planMonths;   // 1 | 3 | 6
  final double? amountPaid;
  final String? paymentRef; // UPI transaction ID
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final DateTime createdAt;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planMonths,
    this.amountPaid,
    this.paymentRef,
    required this.startsAt,
    this.endsAt,
    required this.isActive,
    required this.createdAt,
  });

  /// Whether this subscription is currently valid (active + not expired).
  bool get isValid {
    if (!isActive) return false;
    if (endsAt == null) return false;
    return endsAt!.isAfter(DateTime.now().toUtc());
  }

  /// Days remaining in this subscription.
  int get daysRemaining {
    if (endsAt == null) return 0;
    return endsAt!.difference(DateTime.now().toUtc()).inDays.clamp(0, 9999);
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> m) =>
      SubscriptionModel(
        id:          m['id'] as int,
        userId:      m['user_id'] as int,
        planMonths:  m['plan_months'] as int,
        amountPaid:  double.tryParse(m['amount_paid']?.toString() ?? ''),
        paymentRef:  m['payment_ref'] as String?,
        startsAt:    m['starts_at'] as DateTime,
        endsAt:      m['ends_at'] as DateTime?,
        isActive:    (m['is_active'] as bool?) ?? false,
        createdAt:   (m['created_at'] as DateTime?) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id':          id,
        'user_id':     userId,
        'plan_months': planMonths,
        'amount_paid': amountPaid,
        'payment_ref': paymentRef,
        'starts_at':   startsAt.toIso8601String(),
        'ends_at':     endsAt?.toIso8601String(),
        'is_active':   isActive,
        'created_at':  createdAt.toIso8601String(),
      };
}

/// Available subscription plans.
enum SubscriptionPlan {
  monthly(1, 'Monthly'),
  quarterly(3, 'Quarterly (3 months)'),
  halfYearly(6, 'Half Yearly (6 months)');

  const SubscriptionPlan(this.months, this.label);
  final int months;
  final String label;
}
