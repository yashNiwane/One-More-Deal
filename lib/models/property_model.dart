import 'dart:convert';

/// Mirrors the `properties` table row.
/// Covers all listing types from the requirements doc:
///   Residential Resale / Rent
///   Commercial Resale / Rent / Plot
///   New Property (Builder only)
class PropertyModel {
  final int? id;
  final int userId;

  // Classification
  final PropertyCategory category;
  final ListingType listingType;

  // Location
  final String city;
  final String area;
  final String? subarea;
  final String? societyName;

  // Details
  final String? flatType;       // BHK / Bungalow / Shop / Unit
  final double? areaValue;
  final double? builtUpArea;
  final double? carpetArea;
  final String areaUnit;        // SqFt | Guntha | Acre
  final int? floorNumber;
  final FloorCategory? floorCategory;
  final double? price;
  final double? deposit;          // Security deposit (Rent only)
  final String? availability;
  final DateTime? possessionDate; // Builder new property
  final String? parking;
  final String? furnishingStatus; // Full / Semi / Unfurnished

  // Builder-specific fields
  final String? reraNo;
  final int? totalBuildings;
  final int? amenitiesCount;
  final String? buildingStructure;
  final int? totalUnits;
  final bool isApproved;
  final List<Map<String, dynamic>>? variants; // up to 8 BHK variants

  // Poster company (joined from users table)
  final String? posterCompany;
  final String? posterPhone;

  // Lifecycle (null = DB will set NOW() on INSERT)
  final bool isVisible;
  final DateTime? postedAt;
  final DateTime? refreshedAt;
  final DateTime? autoDeleteAt;
  final DateTime? createdAt;

  // Poster info (joined from users table)
  final String? posterName;
  final String? posterCode;

  const PropertyModel({
    this.id,
    required this.userId,
    required this.category,
    required this.listingType,
    required this.city,
    required this.area,
    this.subarea,
    this.societyName,
    this.flatType,
    this.areaValue,
    this.builtUpArea,
    this.carpetArea,
    this.areaUnit = 'SqFt',
    this.floorNumber,
    this.floorCategory,
    this.price,
    this.deposit,
    this.availability,
    this.possessionDate,
    this.parking,
    this.furnishingStatus,
    this.reraNo,
    this.totalBuildings,
    this.amenitiesCount,
    this.buildingStructure,
    this.totalUnits,
    this.isApproved = true,
    this.variants,
    this.isVisible = true,
    this.postedAt,
    this.refreshedAt,
    this.autoDeleteAt,
    this.createdAt,
    this.posterName,
    this.posterCode,
    this.posterCompany,
    this.posterPhone,
  });

  // ── Business rules ──────────────────────────────────────────────────

  /// Auto-delete duration: Rent → 30 days, all others → 60 days.
  Duration get autoDeleteDuration => listingType == ListingType.rent
      ? const Duration(days: 30)
      : const Duration(days: 60);

  /// Days until auto-delete (0 if already past).
  int get daysUntilDelete {
    if (autoDeleteAt == null) return 0;
    return autoDeleteAt!.difference(DateTime.now().toUtc()).inDays.clamp(0, 9999);
  }

  bool get isExpired =>
      autoDeleteAt != null && autoDeleteAt!.isBefore(DateTime.now().toUtc());

  /// Compute floor category from floor number.
  /// Low = 1–2, Mid = 3–5, High = 6+
  static FloorCategory? floorCategoryFromNumber(int? floor) {
    if (floor == null) return null;
    if (floor <= 2) return FloorCategory.low;
    if (floor <= 5) return FloorCategory.mid;
    return FloorCategory.high;
  }

  static String? _parseEnumStr(dynamic val) {
    if (val == null) return null;
    if (val is String) return val;
    try {
      return (val as dynamic).asString as String; // UndecodedBytes wrapper
    } catch (_) {
      return val.toString();
    }
  }

  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  // ── Serialization ───────────────────────────────────────────────────

  static List<Map<String, dynamic>>? _parseVariants(dynamic val) {
    if (val == null) return null;
    if (val is List) return val.cast<Map<String, dynamic>>();
    if (val is String) {
      try {
        final decoded = jsonDecode(val);
        if (decoded is List) return decoded.cast<Map<String, dynamic>>();
      } catch (_) {}
    }
    return null;
  }

  factory PropertyModel.fromMap(Map<String, dynamic> m) => PropertyModel(
        id:              m['id'] as int?,
        userId:          m['user_id'] as int,
        category:        PropertyCategory.fromString(_parseEnumStr(m['category'])!),
        listingType:     ListingType.fromString(_parseEnumStr(m['listing_type'])!),
        city:            m['city'] as String,
        area:            m['area'] as String,
        subarea:         m['subarea'] as String?,
        societyName:     m['society_name'] as String?,
        flatType:        m['flat_type'] as String?,
        areaValue:       _parseDouble(m['area_value']),
        builtUpArea:     _parseDouble(m['built_up_area']),
        carpetArea:      _parseDouble(m['carpet_area']),
        areaUnit:        (m['area_unit'] as String?) ?? 'SqFt',
        floorNumber:     m['floor_number'] as int?,
        floorCategory:   FloorCategory.fromString(_parseEnumStr(m['floor_category'])),
        price:           _parseDouble(m['price']),
        deposit:         _parseDouble(m['deposit']),
        availability:    m['availability'] as String?,
        possessionDate:  m['possession_date'] as DateTime?,
        parking:         m['parking'] as String?,
        furnishingStatus:m['furnishing_status'] as String?,
        reraNo:          m['rera_no'] as String?,
        totalBuildings:  m['total_buildings'] as int?,
        amenitiesCount:  m['amenities_count'] as int?,
        buildingStructure: m['building_structure'] as String?,
        totalUnits:      m['total_units'] as int?,
        isApproved:      (m['is_approved'] as bool?) ?? true,
        variants:        _parseVariants(m['variants']),
        isVisible:       (m['is_visible'] as bool?) ?? true,
        postedAt:        m['posted_at'] as DateTime? ?? DateTime.now().toUtc(),
        refreshedAt:     m['refreshed_at'] as DateTime? ?? DateTime.now().toUtc(),
        autoDeleteAt:    m['auto_delete_at'] as DateTime?,
        createdAt:       m['created_at'] as DateTime?,
        posterName:      m['poster_name'] as String?,
        posterCode:      m['poster_code'] as String?,
        posterCompany:   m['poster_company'] as String?,
        posterPhone:     m['poster_phone'] as String?,
      );

  Map<String, dynamic> toInsertMap() => {
        'user_id':         userId,
        'category':        category.value,
        'listing_type':    listingType.value,
        'city':            city,
        'area':            area,
        'subarea':         subarea,
        'society_name':    societyName,
        'flat_type':       flatType,
        'area_value':      areaValue,
        'built_up_area':   builtUpArea,
        'carpet_area':     carpetArea,
        'area_unit':       areaUnit,
        'floor_number':    floorNumber,
        'floor_category':  floorCategory?.value,
        'price':           price,
        'deposit':         deposit,
        'availability':    availability,
        'possession_date': possessionDate?.toIso8601String().substring(0, 10),
        'parking':         parking,
        'furnishing_status': furnishingStatus,
        'rera_no':         reraNo,
        'total_buildings': totalBuildings,
        'amenities_count': amenitiesCount,
        'building_structure': buildingStructure,
        'total_units':     totalUnits,
        'is_approved':     isApproved,
        'variants':        variants != null ? jsonEncode(variants) : null,
      };

  PropertyModel copyWith({
    double? price,
    double? deposit,
    String? availability,
    double? areaValue,
    double? builtUpArea,
    double? carpetArea,
    String? parking,
    String? flatType,
    String? societyName,
    String? area,
    String? subarea,
    String? furnishingStatus,
    bool? isVisible,
    bool? isApproved,
    String? reraNo,
    int? totalBuildings,
    int? amenitiesCount,
    String? buildingStructure,
    int? totalUnits,
    List<Map<String, dynamic>>? variants,
  }) =>
      PropertyModel(
        id:              id,
        userId:          userId,
        category:        category,
        listingType:     listingType,
        city:            city,
        area:            area ?? this.area,
        subarea:         subarea ?? this.subarea,
        societyName:     societyName ?? this.societyName,
        flatType:        flatType ?? this.flatType,
        areaValue:       areaValue ?? this.areaValue,
        builtUpArea:     builtUpArea ?? this.builtUpArea,
        carpetArea:      carpetArea ?? this.carpetArea,
        areaUnit:        areaUnit,
        floorNumber:     floorNumber,
        floorCategory:   floorCategory,
        price:           price ?? this.price,
        deposit:         deposit ?? this.deposit,
        availability:    availability ?? this.availability,
        possessionDate:  possessionDate,
        parking:         parking ?? this.parking,
        furnishingStatus:furnishingStatus ?? this.furnishingStatus,
        reraNo:          reraNo ?? this.reraNo,
        totalBuildings:  totalBuildings ?? this.totalBuildings,
        amenitiesCount:  amenitiesCount ?? this.amenitiesCount,
        buildingStructure: buildingStructure ?? this.buildingStructure,
        totalUnits:      totalUnits ?? this.totalUnits,
        isApproved:      isApproved ?? this.isApproved,
        variants:        variants ?? this.variants,
        isVisible:       isVisible ?? this.isVisible,
        postedAt:        postedAt,
        refreshedAt:     refreshedAt,
        autoDeleteAt:    autoDeleteAt,
        createdAt:       createdAt,
        posterCompany:   posterCompany,
        posterPhone:     posterPhone,
      );
}

// ─── Enums ────────────────────────────────────────────────────────────────────

enum PropertyCategory {
  residential('Residential'),
  commercial('Commercial'),
  plot('Plot'),
  newProperty('New');

  const PropertyCategory(this.value);
  final String value;

  static PropertyCategory fromString(String s) =>
      PropertyCategory.values.firstWhere(
        (e) => e.value.toLowerCase() == s.toLowerCase(),
        orElse: () => PropertyCategory.residential,
      );
}

enum ListingType {
  resale('Resale'),
  rent('Rent'),
  newLaunch('New'),
  plot('Plot');

  const ListingType(this.value);
  final String value;

  static ListingType fromString(String s) =>
      ListingType.values.firstWhere(
        (e) => e.value.toLowerCase() == s.toLowerCase(),
        orElse: () => ListingType.resale,
      );
}

enum FloorCategory {
  low('Low'),   // Floor 1–2
  mid('Mid'),   // Floor 3–5
  high('High'); // Floor 6+

  const FloorCategory(this.value);
  final String value;

  static FloorCategory? fromString(String? s) {
    if (s == null) return null;
    return FloorCategory.values.firstWhere(
      (e) => e.value.toLowerCase() == s.toLowerCase(),
      orElse: () => FloorCategory.low,
    );
  }
}

/// Filter object for property discovery screen.
class PropertyFilter {
  String? city;
  String? area;
  String? society;
  PropertyCategory? category;
  ListingType? listingType;
  FloorCategory? floorCategory;
  String? flatType;          // BHK
  String? parking;           // Open, Covered, Not available
  String? furnishingStatus;  // Full, Semi, Unfurnished
  UserTypeFilter? userTypeFilter; // Broker | Builder
  double? maxPrice;
  double? minPrice;

  PropertyFilter({
    this.city,
    this.area,
    this.society,
    this.category,
    this.listingType,
    this.floorCategory,
    this.flatType,
    this.parking,
    this.furnishingStatus,
    this.userTypeFilter,
    this.maxPrice,
    this.minPrice,
  });

  bool get isEmpty => city == null && area == null && society == null &&
      category == null && listingType == null && floorCategory == null &&
      flatType == null && furnishingStatus == null && userTypeFilter == null &&
      maxPrice == null && minPrice == null;
}

enum UserTypeFilter {
  broker('Broker'),
  builder('Builder');

  const UserTypeFilter(this.value);
  final String value;
}
