enum SubscriptionRequestStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  revoked('revoked');

  const SubscriptionRequestStatus(this.value);
  final String value;

  static SubscriptionRequestStatus fromString(String? raw) {
    return SubscriptionRequestStatus.values.firstWhere(
      (status) => status.value == raw,
      orElse: () => SubscriptionRequestStatus.pending,
    );
  }
}

class SubscriptionRequestModel {
  final int id;
  final int userId;
  final int planMonths;
  final double? amountPaid;
  final String? screenshotBase64;
  final SubscriptionRequestStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? screenshotUpdatedAt;
  final String? requesterName;
  final String? requesterPhone;

  const SubscriptionRequestModel({
    required this.id,
    required this.userId,
    required this.planMonths,
    this.amountPaid,
    this.screenshotBase64,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.screenshotUpdatedAt,
    this.requesterName,
    this.requesterPhone,
  });

  bool get hasScreenshot => (screenshotBase64 ?? '').trim().isNotEmpty;

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    try {
      return (value as dynamic).asString as String;
    } catch (_) {
      return value.toString();
    }
  }

  factory SubscriptionRequestModel.fromMap(Map<String, dynamic> m) {
    return SubscriptionRequestModel(
      id: m['id'] as int,
      userId: m['user_id'] as int,
      planMonths: m['plan_months'] as int,
      amountPaid: double.tryParse(m['amount_paid']?.toString() ?? ''),
      screenshotBase64: _parseString(m['screenshot_base64']),
      status: SubscriptionRequestStatus.fromString(_parseString(m['status'])),
      rejectionReason: _parseString(m['rejection_reason']),
      createdAt: (m['created_at'] as DateTime?) ?? DateTime.now(),
      updatedAt: (m['updated_at'] as DateTime?) ?? DateTime.now(),
      screenshotUpdatedAt: m['screenshot_updated_at'] as DateTime?,
      requesterName: _parseString(m['requester_name']),
      requesterPhone: _parseString(m['requester_phone']),
    );
  }
}
