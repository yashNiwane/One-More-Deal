import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/property_model.dart';
import '../models/subscription_model.dart';
import '../models/enquiry_model.dart';

typedef DailyCount = ({DateTime day, int count});

/// Central singleton for all AWS RDS PostgreSQL operations.
/// Connects lazily on first use — no need to call connect() manually.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Connection? _conn;
  bool _connecting = false;
  bool get isConnected => _conn != null;

  // ═══════════════════════════════════════════════════════════════════════
  // CONNECTION
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> connect() async {
    if (isConnected || _connecting) return;
    _connecting = true;
    try {
      _conn = await Connection.open(
        Endpoint(
          host:     'one-more-deal.cnkisqqwmvy2.ap-south-1.rds.amazonaws.com',
          port:     5432,
          database: 'OneMoreDeal',
          username: 'postgres',
          password: 'MmKnDMm#14',
        ),
        settings: const ConnectionSettings(sslMode: SslMode.require),
      );
      debugPrint('[DB] Connected to RDS ✅');
    } catch (e) {
      debugPrint('[DB] Connection failed: $e');
      rethrow;
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    await _conn?.close();
    _conn = null;
  }

  /// Lazy getter — connects automatically on first use or if connection dropped.
  Future<Connection> get _db async {
    if (_conn == null || !_conn!.isOpen) {
      _conn = null;
      _connecting = false; // Reset lock if stale
      await connect();
    }
    return _conn!;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // USERS
  // ═══════════════════════════════════════════════════════════════════════

  /// First-time signup OR re-login: upserts the row and returns the full user.
  Future<UserModel?> upsertUser(String phone, String sessionToken) async {
    final res = await (await _db).execute(
      Sql.named('''
        INSERT INTO users (phone, last_login_at, current_session_token)
        VALUES (@phone, NOW(), @token)
        ON CONFLICT (phone) DO UPDATE
          SET last_login_at = NOW(),
              current_session_token = @token,
              updated_at    = NOW()
        RETURNING id, phone, name, user_type, city, company_name,
                  is_active, trial_days, trial_ends_at, last_login_at, created_at, current_session_token, user_code
      '''),
      parameters: {'phone': phone, 'token': sessionToken},
    );
    if (res.isEmpty) return null;
    return UserModel.fromMap(res.first.toColumnMap());
  }

  /// Updates profile after the profile-setup screen.
  Future<void> updateUserProfile({
    required String phone,
    required String name,
    required String userType,
    required String city,
    required String companyName,
  }) async {
    await (await _db).execute(
      Sql.named('''
        UPDATE users
        SET name            = @name,
            user_type       = @userType,
            city            = @city,
            company_name    = @companyName,
            updated_at      = NOW()
        WHERE phone = @phone
      '''),
      parameters: {
        'phone': phone,
        'name': name,
        'userType': userType,
        'city': city,
        'companyName': companyName,
      },
    );
  }

  /// Retrieves a user row by phone number.
  Future<UserModel?> getUserByPhone(String phone) async {
    final res = await (await _db).execute(
      Sql.named('''
        SELECT id, phone, name, user_type, city, company_name,
               is_active, trial_days, trial_ends_at, last_login_at, created_at, current_session_token, user_code
        FROM users WHERE phone = @phone LIMIT 1
      '''),
      parameters: {'phone': phone},
    );
    if (res.isEmpty) return null;
    return UserModel.fromMap(res.first.toColumnMap());
  }

  /// Deactivates a user (soft-delete — hides properties).
  Future<void> deactivateUser(String phone) async {
    await (await _db).execute(
      Sql.named('''
        UPDATE users SET is_active = false, updated_at = NOW()
        WHERE phone = @phone
      '''),
      parameters: {'phone': phone},
    );
  }

  /// Reactivates user after successful subscription payment.
  Future<void> activateUser(String phone) async {
    await (await _db).execute(
      Sql.named('''
        UPDATE users SET is_active = true, updated_at = NOW()
        WHERE phone = @phone
      '''),
      parameters: {'phone': phone},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Creates a new subscription after UPI payment succeeds.
  Future<SubscriptionModel?> createSubscription({
    required int userId,
    required int planMonths,
    required double amountPaid,
    required String paymentRef,
  }) async {
    try {
      // Deactivate any existing active subscription first
      await (await _db).execute(
        Sql.named(
          'UPDATE subscriptions SET is_active = false WHERE user_id = @uid AND is_active = true',
        ),
        parameters: {'uid': userId},
      );

      // Successfully bought? REACTIVATE the user to restore their properties
      await (await _db).execute(
        Sql.named('UPDATE users SET is_active = true WHERE id = @uid'),
        parameters: {'uid': userId},
      );

      final res = await (await _db).execute(
        Sql.named('''
          INSERT INTO subscriptions (user_id, plan_months, amount_paid, payment_ref,
                                     starts_at, ends_at, is_active)
          VALUES (@uid, @months, @amount, @ref,
                  NOW(), NOW() + (INTERVAL '1 month' * CAST(@months AS INTEGER)), true)
          RETURNING id, user_id, plan_months, amount_paid, payment_ref,
                    starts_at, ends_at, is_active, created_at
        '''),
        parameters: {
          'uid':    userId,
          'months': planMonths,
          'amount': amountPaid,
          'ref':    paymentRef,
        },
      );
      if (res.isEmpty) return null;
      return SubscriptionModel.fromMap(res.first.toColumnMap());
    } catch (e) {
      debugPrint('DB createSubscription Error: $e');
      return null;
    }
  }

  /// Returns the currently active subscription for a user, or null.
  Future<SubscriptionModel?> getActiveSubscription(int userId) async {
    final res = await (await _db).execute(
      Sql.named('''
        SELECT id, user_id, plan_months, amount_paid, payment_ref,
               starts_at, ends_at, is_active, created_at
        FROM subscriptions
        WHERE user_id = @uid AND is_active = true AND ends_at > NOW()
        ORDER BY ends_at DESC LIMIT 1
      '''),
      parameters: {'uid': userId},
    );
    if (res.isEmpty) return null;
    return SubscriptionModel.fromMap(res.first.toColumnMap());
  }

  /// Retrieves a user's phone number by ID (for contact feature).
  Future<String?> getUserPhoneById(int id) async {
    final res = await (await _db).execute(
      Sql.named('SELECT phone FROM users WHERE id = @id LIMIT 1'),
      parameters: {'id': id},
    );
    if (res.isEmpty) return null;
    return res.first[0] as String?;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CITY AREAS
  // ═══════════════════════════════════════════════════════════════════════

  /// Searches for city areas matching the query string.
  Future<List<String>> searchCityAreas(String query) async {
    final res = await (await _db).execute(
      Sql.named('SELECT area FROM city_areas WHERE area ILIKE @query ORDER BY area ASC LIMIT 10'),
      parameters: {'query': '%$query%'},
    );
    return res.map((r) => r[0] as String).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ENQUIRIES
  // ═══════════════════════════════════════════════════════════════════════

  /// Logs an enquiry (Call/WhatsApp) into the database.
  Future<void> logEnquiry({
    required int propertyId,
    int? enquirerId,
    required EnquiryType type,
  }) async {
    await (await _db).execute(
      Sql.named('''
        INSERT INTO enquiries (property_id, enquirer_id, type, created_at)
        VALUES (@pid, @eid, @type, NOW())
      '''),
      parameters: {
        'pid': propertyId,
        'eid': enquirerId,
        'type': type.value,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════

  /// Inserts a new property listing with the correct auto_delete_at.
  Future<PropertyModel?> addProperty(PropertyModel p) async {
    final deleteDays = p.listingType == ListingType.rent ? 30 : 60;
    final res = await (await _db).execute(
      Sql.named('''
        INSERT INTO properties (
          user_id, category, listing_type, city, area, subarea, society_name,
          flat_type, area_value, built_up_area, carpet_area, area_unit, floor_number, floor_category,
          price, deposit, availability, possession_date, parking, furnishing_status,
          rera_no, total_buildings, amenities_count, building_structure, total_units, is_approved, variants,
          posted_at, refreshed_at, auto_delete_at
        ) VALUES (
          @userId, @category::property_category, @listingType::listing_type,
          @city, @area, @subarea, @societyName,
          @flatType, @areaValue, @builtUpArea, @carpetArea, @areaUnit, @floorNumber, @floorCategory::floor_category,
          @price, @deposit, @availability, @possessionDate, @parking, @furnishingStatus,
          @reraNo, @totalBuildings, @amenitiesCount, @buildingStructure, @totalUnits, @isApproved, @variants::jsonb,
          NOW(), NOW(), NOW() + (@deleteDays * INTERVAL '1 day')
        )
        RETURNING *
      '''),
      parameters: {
        'userId':         p.userId,
        'category':       p.category.value,
        'listingType':    p.listingType.value,
        'city':           p.city,
        'area':           p.area,
        'subarea':        p.subarea,
        'societyName':    p.societyName,
        'flatType':       p.flatType,
        'areaValue':      p.areaValue,
        'builtUpArea':    p.builtUpArea,
        'carpetArea':     p.carpetArea,
        'areaUnit':       p.areaUnit,
        'floorNumber':    p.floorNumber,
        'floorCategory':  p.floorCategory?.value,
        'price':          p.price,
        'deposit':        p.deposit,
        'availability':   p.availability,
        'possessionDate': p.possessionDate?.toIso8601String().substring(0, 10),
        'parking':        p.parking,
        'furnishingStatus': p.furnishingStatus,
        'reraNo':         p.reraNo,
        'totalBuildings': p.totalBuildings,
        'amenitiesCount': p.amenitiesCount,
        'buildingStructure': p.buildingStructure,
        'totalUnits':     p.totalUnits,
        'isApproved':     p.isApproved,
        'variants':       p.variants != null ? jsonEncode(p.variants) : null,
        'deleteDays':     deleteDays,
      },
    );
    if (res.isEmpty) return null;
    return PropertyModel.fromMap(res.first.toColumnMap());
  }

  /// Updates editable fields of an existing property.
  Future<void> updateProperty(PropertyModel p) async {
    if (p.id == null) throw ArgumentError('PropertyModel.id must not be null for update');
    await (await _db).execute(
      Sql.named('''
        UPDATE properties SET
          area            = @area,
          subarea         = @subarea,
          society_name    = @societyName,
          flat_type       = @flatType,
          area_value      = @areaValue,
          built_up_area   = @builtUpArea,
          carpet_area     = @carpetArea,
          floor_number    = @floorNumber,
          floor_category  = @floorCategory::floor_category,
          price           = @price,
          deposit         = @deposit,
          availability    = @availability,
          possession_date = @possessionDate,
          parking         = @parking,
          furnishing_status = @furnishingStatus
        WHERE id = @id AND user_id = @userId
      '''),
      parameters: {
        'id':             p.id,
        'userId':         p.userId,
        'area':           p.area,
        'subarea':        p.subarea,
        'societyName':    p.societyName,
        'flatType':       p.flatType,
        'areaValue':      p.areaValue,
        'builtUpArea':    p.builtUpArea,
        'carpetArea':     p.carpetArea,
        'floorNumber':    p.floorNumber,
        'floorCategory':  p.floorCategory?.value,
        'price':          p.price,
        'deposit':        p.deposit,
        'availability':   p.availability,
        'possessionDate': p.possessionDate?.toIso8601String().substring(0, 10),
        'parking':        p.parking,
        'furnishingStatus': p.furnishingStatus,
      },
    );
  }

  /// Soft-deletes a property so it fully disappears without erasing the actual database row.
  Future<void> deleteProperty(int propertyId, int userId) async {
    await (await _db).execute(
      Sql.named('''
        UPDATE properties SET is_deleted = true, is_visible = false
        WHERE id = @id AND user_id = @userId
      '''),
      parameters: {'id': propertyId, 'userId': userId},
    );
  }

  /// Refreshes a property — resets posted date and auto-delete timer.
  /// Rent → 30 days, all others → 60 days from NOW().
  Future<void> refreshProperty(int propertyId, int userId, ListingType listingType) async {
    final deleteDays = listingType == ListingType.rent ? 30 : 60;
    await (await _db).execute(
      Sql.named('''
        UPDATE properties SET
          refreshed_at   = NOW(),
          auto_delete_at = NOW() + (@days || ' days')::INTERVAL,
          is_visible     = true
        WHERE id = @id AND user_id = @userId
      '''),
      parameters: {'id': propertyId, 'userId': userId, 'days': deleteDays},
    );
  }

  /// Hides all expired properties for a user (calls auto-delete logic).
  /// Should be called on app startup and before showing listings.
  Future<void> expireOldProperties() async {
    await (await _db).execute(
      "UPDATE properties SET is_visible = false "
      "WHERE is_visible = true AND auto_delete_at < NOW()",
    );
  }

  /// Retrieves a user's own properties (My Properties screen).
  Future<List<PropertyModel>> getMyProperties(int userId) async {
    final res = await (await _db).execute(
      Sql.named('''
        SELECT * FROM properties
        WHERE user_id = @uid AND (is_deleted = false OR is_deleted IS NULL)
        ORDER BY refreshed_at DESC
      '''),
      parameters: {'uid': userId},
    );
    return res.map((r) => PropertyModel.fromMap(r.toColumnMap())).toList();
  }

  /// Retrieves ALL visible properties with optional filters.
  /// Sorted: Builder properties grouped by society → then by price, refreshed_at.
  Future<List<PropertyModel>> getProperties({PropertyFilter? filter}) async {
    // Build dynamic WHERE clauses
    // Only show properties from ACTIVE users, and properties that are visible and not auto-deleted
    final conditions = <String>[
      'p.is_visible = true',
      'p.auto_delete_at > NOW()',
      'u.is_active = true',
      '(u.trial_ends_at > NOW() OR EXISTS(SELECT 1 FROM subscriptions s WHERE s.user_id = u.id AND s.is_active = true AND s.ends_at > NOW()))',
      '(p.is_deleted = false OR p.is_deleted IS NULL)',
      '(p.is_approved = true)',
    ];
    final params = <String, dynamic>{};

    if (filter != null) {
      if (filter.city != null) {
        conditions.add('LOWER(p.city) = LOWER(@city)');
        params['city'] = filter.city;
      }
      if (filter.area != null) {
        conditions.add('LOWER(p.area) LIKE LOWER(@area)');
        params['area'] = '%${filter.area}%';
      }
      if (filter.society != null) {
        conditions.add('LOWER(p.society_name) LIKE LOWER(@society)');
        params['society'] = '%${filter.society}%';
      }
      if (filter.category != null) {
        conditions.add("p.category = @category::property_category");
        params['category'] = filter.category!.value;
      }
      if (filter.listingType != null) {
        conditions.add("p.listing_type = @listingType::listing_type");
        params['listingType'] = filter.listingType!.value;
      }
      if (filter.floorCategory != null) {
        conditions.add("p.floor_category = @floorCat::floor_category");
        params['floorCat'] = filter.floorCategory!.value;
      }
      if (filter.flatType != null) {
        conditions.add('LOWER(p.flat_type) LIKE LOWER(@flatType)');
        params['flatType'] = '%${filter.flatType}%';
      }
      if (filter.parking != null) {
        conditions.add('p.parking = @parking');
        params['parking'] = filter.parking;
      }
      if (filter.furnishingStatus != null) {
        conditions.add('p.furnishing_status = @furnishingStatus');
        params['furnishingStatus'] = filter.furnishingStatus;
      }
      if (filter.userTypeFilter != null) {
        conditions.add('u.user_type = @userType');
        params['userType'] = filter.userTypeFilter!.value;
      }
      if (filter.minPrice != null) {
        conditions.add('p.price >= @minPrice');
        params['minPrice'] = filter.minPrice;
      }
      if (filter.maxPrice != null) {
        conditions.add('p.price <= @maxPrice');
        params['maxPrice'] = filter.maxPrice;
      }
    }

    final where = conditions.join(' AND ');

    final res = await (await _db).execute(
      Sql.named('''
        SELECT p.*,
               COALESCE(NULLIF(TRIM(u.company_name), ''), u.name) AS poster_name,
               u.user_code AS poster_code,
               u.company_name AS poster_company,
               u.phone AS poster_phone
        FROM properties p
        JOIN users u ON u.id = p.user_id
        WHERE $where
        ORDER BY
          CASE WHEN p.refreshed_at > NOW() - INTERVAL '1 day' THEN 0 ELSE 1 END,
          p.refreshed_at DESC,
          CASE WHEN u.user_type = 'Builder' THEN 0 ELSE 1 END,
          p.society_name NULLS LAST
      '''),
      parameters: params,
    );
    return res.map((r) => PropertyModel.fromMap(r.toColumnMap())).toList();
  }



  /// Restores visible=true for properties hidden by inactivity (not by expiry).
  Future<void> restoreUserProperties(int userId) async {
    await (await _db).execute(
      Sql.named('''
        UPDATE properties
        SET is_visible = true
        WHERE user_id = @uid
          AND is_visible = false
          AND auto_delete_at > NOW()
          AND (is_deleted = false OR is_deleted IS NULL)
      '''),
      parameters: {'uid': userId},
    );
  }

  /// Hides all properties of a user (called on 7-day inactivity).
  Future<void> hidePropertiesForUser(int userId) async {
    await (await _db).execute(
      Sql.named('UPDATE properties SET is_visible = false WHERE user_id = @uid'),
      parameters: {'uid': userId},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HOME SCREEN STATS
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns stats for the HomeScreen dashboard.
  Future<Map<String, int>> getUserStats(String phone) async {
    final userRes = await (await _db).execute(
      Sql.named('SELECT id, trial_ends_at FROM users WHERE phone = @phone LIMIT 1'),
      parameters: {'phone': phone},
    );
    if (userRes.isEmpty) {
      return {'listings': 0, 'enquiries': 0, 'trialDaysLeft': 0, 'dealsClosed': 0};
    }

    final userId      = userRes.first[0] as int;
    final trialEndsAt = userRes.first[1] as DateTime?;
    final trialDaysLeft = trialEndsAt != null
        ? trialEndsAt.difference(DateTime.now().toUtc()).inDays.clamp(0, 9999)
        : 0;

    final listingsRes = await (await _db).execute(
      Sql.named('SELECT COUNT(*) FROM properties WHERE user_id=@uid AND is_visible=true'),
      parameters: {'uid': userId},
    );

    final enquiriesRes = await (await _db).execute(
      Sql.named('''
        SELECT COUNT(*) FROM enquiries e
        JOIN properties p ON p.id = e.property_id
        WHERE p.user_id = @uid
      '''),
      parameters: {'uid': userId},
    );

    return {
      'listings':     (listingsRes.first[0] as int?) ?? 0,
      'enquiries':    (enquiriesRes.first[0] as int?) ?? 0,
      'trialDaysLeft': trialDaysLeft,
      'dealsClosed':  0,
    };
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // ADMIN DASHBOARD
  // ═════════════════════════════════════════════════════════════════════════════

  /// Lightweight dashboard stats for the admin UI.
  /// All counts are computed on-demand (no caching).
  Future<Map<String, int>> getAdminDashboardStats() async {
    final db = await _db;

    Future<int> count(String sql, {Map<String, dynamic> params = const {}}) async {
      final res = await db.execute(Sql.named(sql), parameters: params);
      return ((res.isNotEmpty ? res.first[0] : 0) as int?) ?? 0;
    }

    final totalUsers = await count('SELECT COUNT(*) FROM users');
    final activeUsers = await count('SELECT COUNT(*) FROM users WHERE is_active = true');

    final totalProperties = await count('''
      SELECT COUNT(*)
      FROM properties
      WHERE (is_deleted = false OR is_deleted IS NULL)
    ''');

    final visibleProperties = await count('''
      SELECT COUNT(*)
      FROM properties
      WHERE is_visible = true
        AND auto_delete_at > NOW()
        AND (is_deleted = false OR is_deleted IS NULL)
    ''');

    final pendingApprovals = await count('''
      SELECT COUNT(*)
      FROM properties
      WHERE is_approved = false
        AND (is_deleted = false OR is_deleted IS NULL)
    ''');

    // Note: enum values use Title Case strings (e.g., 'New').
    final builderProjects = await count('''
      SELECT COUNT(*)
      FROM properties
      WHERE category = 'New'::property_category
        AND (is_deleted = false OR is_deleted IS NULL)
    ''');

    final activeSubscriptions = await count('''
      SELECT COUNT(*)
      FROM subscriptions
      WHERE is_active = true AND ends_at > NOW()
    ''');

    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'totalProperties': totalProperties,
      'visibleProperties': visibleProperties,
      'pendingApprovals': pendingApprovals,
      'builderProjects': builderProjects,
      'activeSubscriptions': activeSubscriptions,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════
  /// New users per day for the last [days] days.
  /// Returns sparse results (days with zero activity are omitted).
  Future<List<DailyCount>> getAdminNewUsersByDay({int days = 14}) async {
    final start = _startOfDayUtc(days: days);
    final res = await (await _db).execute(
      Sql.named('''
        SELECT created_at::date AS day, COUNT(*)::int AS c
        FROM users
        WHERE created_at >= @start
        GROUP BY day
        ORDER BY day
      '''),
      parameters: {'start': start},
    );

    return res.map((r) => (day: (r[0] as DateTime), count: (r[1] as int?) ?? 0)).toList(growable: false);
  }

  /// New listings per day (based on `posted_at`) for the last [days] days.
  /// Returns sparse results (days with zero activity are omitted).
  Future<List<DailyCount>> getAdminNewListingsByDay({int days = 14}) async {
    final start = _startOfDayUtc(days: days);
    final res = await (await _db).execute(
      Sql.named('''
        SELECT posted_at::date AS day, COUNT(*)::int AS c
        FROM properties
        WHERE posted_at IS NOT NULL
          AND posted_at >= @start
          AND (is_deleted = false OR is_deleted IS NULL)
        GROUP BY day
        ORDER BY day
      '''),
      parameters: {'start': start},
    );

    return res.map((r) => (day: (r[0] as DateTime), count: (r[1] as int?) ?? 0)).toList(growable: false);
  }

  /// Total count of listings by `category` (enum text).
  Future<Map<String, int>> getAdminPropertyCategoryBreakdown() async {
    final res = await (await _db).execute(
      Sql.named('''
        SELECT COALESCE(category::text, 'Unknown') AS k, COUNT(*)::int AS c
        FROM properties
        WHERE (is_deleted = false OR is_deleted IS NULL)
        GROUP BY k
        ORDER BY c DESC
      '''),
    );

    final map = <String, int>{};
    for (final row in res) {
      final key = (row[0] as String?)?.trim();
      if (key == null || key.isEmpty) continue;
      map[key] = (row[1] as int?) ?? 0;
    }
    return map;
  }

  DateTime _startOfDayUtc({required int days}) {
    final now = DateTime.now().toUtc();
    final start = now.subtract(Duration(days: days - 1));
    return DateTime.utc(start.year, start.month, start.day);
  }

  // ADMIN – BUILDER APPROVAL
  // ═══════════════════════════════════════════════════════════════════════

  /// Fetches all unapproved builder properties for the admin dashboard.
  Future<List<PropertyModel>> getPendingApprovals() async {
    final res = await (await _db).execute(
      Sql.named('''
        SELECT p.*,
               COALESCE(NULLIF(TRIM(u.company_name), ''), u.name) AS poster_name,
               u.user_code AS poster_code,
               u.company_name AS poster_company,
               u.phone AS poster_phone
        FROM properties p
        JOIN users u ON u.id = p.user_id
        WHERE p.is_approved = false
          AND (p.is_deleted = false OR p.is_deleted IS NULL)
        ORDER BY p.posted_at DESC
      '''),
      parameters: {},
    );
    return res.map((r) => PropertyModel.fromMap(r.toColumnMap())).toList();
  }

  /// Approves a builder property so it appears in the public Discover feed.
  Future<void> approveProperty(int propertyId) async {
    await (await _db).execute(
      Sql.named('UPDATE properties SET is_approved = true WHERE id = @id'),
      parameters: {'id': propertyId},
    );
  }

  /// Rejects (soft-deletes) a builder property.
  Future<void> rejectProperty(int propertyId) async {
    await (await _db).execute(
      Sql.named('UPDATE properties SET is_deleted = true, is_visible = false WHERE id = @id'),
      parameters: {'id': propertyId},
    );
  }
}
