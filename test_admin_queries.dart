import 'package:postgres/postgres.dart';

void main() async {
  Connection? conn;
  
  try {
    print('Connecting to database...');
    conn = await Connection.open(
      Endpoint(
        host: 'one-more-deal.cnkisqqwmvy2.ap-south-1.rds.amazonaws.com',
        port: 5432,
        database: 'OneMoreDeal',
        username: 'postgres',
        password: 'MmKnDMm#14',
      ),
      settings: const ConnectionSettings(sslMode: SslMode.require),
    );
    print('✅ Connected successfully!\n');

    // Test the exact query from getAdminCompactOverviewStats
    print('=== TESTING getAdminCompactOverviewStats Query ===\n');
    
    final res = await conn.execute(
      Sql.named('''
        WITH upcoming AS (
          SELECT
            u.id,
            u.user_type,
            COALESCE(
              (
                SELECT MAX(s.ends_at)
                FROM subscriptions s
                WHERE s.user_id = u.id
                  AND s.is_active = true
                  AND s.ends_at > NOW()
              ),
              u.trial_ends_at
            ) AS valid_till
          FROM users u
          WHERE u.user_type IN ('Broker', 'Builder', 'Developer')
        ),
        susp AS (
          SELECT user_type
          FROM upcoming
          WHERE valid_till IS NOT NULL
            AND valid_till >= NOW()
            AND valid_till <= NOW() + (@days || ' days')::interval
        )
        SELECT
          (SELECT COUNT(*)::int FROM users WHERE user_type = 'Broker') AS total_brokers,
          (SELECT COUNT(*)::int FROM users WHERE user_type IN ('Builder', 'Developer')) AS total_builders,
          (SELECT COUNT(*)::int FROM susp WHERE user_type = 'Broker') AS broker_next7_suspension,
          (SELECT COUNT(*)::int FROM susp WHERE user_type IN ('Builder', 'Developer')) AS builder_next7_suspension,
          (
            SELECT COUNT(*)::int
            FROM properties p
            JOIN users u ON u.id = p.user_id
            WHERE (p.is_deleted = false OR p.is_deleted IS NULL)
              AND u.user_type = 'Broker'
          ) AS total_broker_listings,
          (
            SELECT COUNT(*)::int
            FROM properties p
            JOIN users u ON u.id = p.user_id
            WHERE (p.is_deleted = false OR p.is_deleted IS NULL)
              AND u.user_type IN ('Builder', 'Developer')
          ) AS total_builder_listings,
          (
            SELECT COUNT(*)::int
            FROM subscriptions
            WHERE created_at >= NOW() - INTERVAL '7 days'
          ) AS payments_7d,
          (
            SELECT COUNT(*)::int
            FROM subscriptions
            WHERE created_at >= NOW() - INTERVAL '30 days'
          ) AS payments_30d
      '''),
      parameters: {'days': 7},
    );

    if (res.isEmpty) {
      print('❌ No results returned!');
    } else {
      final row = res.first.toColumnMap();
      print('Overview Stats:');
      print('  Total Brokers: ${row['total_brokers']}');
      print('  Total Builders: ${row['total_builders']}');
      print('  Broker Next 7 Days Suspension: ${row['broker_next7_suspension']}');
      print('  Builder Next 7 Days Suspension: ${row['builder_next7_suspension']}');
      print('  Total Broker Listings: ${row['total_broker_listings']}');
      print('  Total Builder Listings: ${row['total_builder_listings']}');
      print('  Payments 7d: ${row['payments_7d']}');
      print('  Payments 30d: ${row['payments_30d']}');
    }
    print('');

    // Test the exact query from getAdminUpcomingSuspensions
    print('=== TESTING getAdminUpcomingSuspensions Query (7 days) ===\n');
    
    final suspRes = await conn.execute(
      Sql.named('''
        SELECT
          u.id,
          COALESCE(NULLIF(TRIM(u.company_name), ''), NULLIF(TRIM(u.name), ''), 'Unknown') AS name,
          u.phone,
          u.user_type,
          COALESCE(listings.total, 0) AS current_adds,
          ent.valid_till,
          GREATEST(
            0,
            CEIL(EXTRACT(EPOCH FROM (ent.valid_till - NOW())) / 86400.0)
          )::int AS days_left
        FROM users u
        JOIN LATERAL (
          SELECT COALESCE(
            (
              SELECT MAX(s.ends_at)
              FROM subscriptions s
              WHERE s.user_id = u.id
                AND s.is_active = true
                AND s.ends_at > NOW()
            ),
            u.trial_ends_at
          ) AS valid_till
        ) ent ON true
        LEFT JOIN LATERAL (
          SELECT COUNT(*)::int AS total
          FROM properties p
          WHERE p.user_id = u.id
            AND (p.is_deleted = false OR p.is_deleted IS NULL)
        ) listings ON true
        WHERE u.user_type IN ('Broker', 'Builder', 'Developer')
          AND ent.valid_till IS NOT NULL
          AND ent.valid_till >= NOW()
          AND ent.valid_till <= NOW() + (@days || ' days')::interval
        ORDER BY ent.valid_till ASC, name ASC
        LIMIT @limit
      '''),
      parameters: {'days': 7, 'limit': 200},
    );

    print('Found ${suspRes.length} suspensions in next 7 days:');
    for (var row in suspRes) {
      final m = row.toColumnMap();
      print('  - ${m['user_type']}: ${m['name']} | Phone: ${m['phone']} | Adds: ${m['current_adds']} | Days: ${m['days_left']}');
    }
    print('');

    // Test 30 days
    print('=== TESTING getAdminUpcomingSuspensions Query (30 days) ===\n');
    
    final susp30Res = await conn.execute(
      Sql.named('''
        SELECT
          u.id,
          COALESCE(NULLIF(TRIM(u.company_name), ''), NULLIF(TRIM(u.name), ''), 'Unknown') AS name,
          u.phone,
          u.user_type,
          COALESCE(listings.total, 0) AS current_adds,
          ent.valid_till,
          GREATEST(
            0,
            CEIL(EXTRACT(EPOCH FROM (ent.valid_till - NOW())) / 86400.0)
          )::int AS days_left
        FROM users u
        JOIN LATERAL (
          SELECT COALESCE(
            (
              SELECT MAX(s.ends_at)
              FROM subscriptions s
              WHERE s.user_id = u.id
                AND s.is_active = true
                AND s.ends_at > NOW()
            ),
            u.trial_ends_at
          ) AS valid_till
        ) ent ON true
        LEFT JOIN LATERAL (
          SELECT COUNT(*)::int AS total
          FROM properties p
          WHERE p.user_id = u.id
            AND (p.is_deleted = false OR p.is_deleted IS NULL)
        ) listings ON true
        WHERE u.user_type IN ('Broker', 'Builder', 'Developer')
          AND ent.valid_till IS NOT NULL
          AND ent.valid_till >= NOW()
          AND ent.valid_till <= NOW() + (@days || ' days')::interval
        ORDER BY ent.valid_till ASC, name ASC
        LIMIT @limit
      '''),
      parameters: {'days': 30, 'limit': 200},
    );

    print('Found ${susp30Res.length} suspensions in next 30 days:');
    for (var row in susp30Res) {
      final m = row.toColumnMap();
      print('  - ${m['user_type']}: ${m['name']} | Phone: ${m['phone']} | Adds: ${m['current_adds']} | Days: ${m['days_left']}');
    }
    print('');

    // Test recent payments
    print('=== TESTING getAdminRecentPayments Query (7 days) ===\n');
    
    final pay7Res = await conn.execute(
      Sql.named('''
        SELECT
          s.id,
          COALESCE(NULLIF(TRIM(u.company_name), ''), NULLIF(TRIM(u.name), ''), 'Unknown') AS name,
          u.phone,
          s.payment_ref,
          s.amount_paid,
          s.created_at AS payment_date,
          s.starts_at,
          s.ends_at,
          GREATEST(
            0,
            ROUND(EXTRACT(EPOCH FROM (s.ends_at - s.starts_at)) / 86400.0)
          )::int AS validity_days
        FROM subscriptions s
        JOIN users u ON u.id = s.user_id
        WHERE s.created_at >= NOW() - (@days || ' days')::interval
        ORDER BY s.created_at DESC
        LIMIT @limit
      '''),
      parameters: {'days': 7, 'limit': 300},
    );

    print('Found ${pay7Res.length} payments in last 7 days:');
    for (var row in pay7Res) {
      final m = row.toColumnMap();
      print('  - ${m['name']} | Phone: ${m['phone']} | Ref: ${m['payment_ref']} | Amount: ${m['amount_paid']}');
    }
    print('');

  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await conn?.close();
    print('✅ Connection closed');
  }
}
