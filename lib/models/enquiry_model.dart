/// Mirrors the `enquiries` table row.
/// Logged every time a user taps Call or WhatsApp on a property listing.
class EnquiryModel {
  final int? id;
  final int propertyId;
  final int? enquirerId;
  final EnquiryType type;
  final DateTime? createdAt;

  const EnquiryModel({
    this.id,
    required this.propertyId,
    this.enquirerId,
    required this.type,
    this.createdAt,
  });

  factory EnquiryModel.fromMap(Map<String, dynamic> m) => EnquiryModel(
        id:          m['id'] as int?,
        propertyId:  m['property_id'] as int,
        enquirerId:  m['enquirer_id'] as int?,
        type:        EnquiryType.fromString(m['type'] as String),
        createdAt:   m['created_at'] as DateTime?,
      );

  Map<String, dynamic> toInsertMap() => {
        'property_id':  propertyId,
        'enquirer_id':  enquirerId,
        'type':         type.value,
      };
}

enum EnquiryType {
  call('Call'),
  whatsApp('WhatsApp');

  const EnquiryType(this.value);
  final String value;

  static EnquiryType fromString(String s) =>
      EnquiryType.values.firstWhere(
        (e) => e.value.toLowerCase() == s.toLowerCase(),
        orElse: () => EnquiryType.call,
      );
}
