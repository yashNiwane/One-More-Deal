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

    // Test 1: Check total users
    print('=== TEST 1: Total Users ===');
    var res = await conn.execute('SELECT COUNT(*) FROM users');
    print('Total users: ${res.first[0]}\n');

    // Test 2: Check users by type
    print('=== TEST 2: Users by Type ===');
    res = await conn.execute('''
      SELECT user_type, COUNT(*) 
      FROM users 
      GROUP BY user_type
    ''');
    for (var row in res) {
      print('${row[0]}: ${row[1]}');
    }
    print('');

    // Test 3: Check subscriptions
    print('=== TEST 3: Active Subscriptions ===');
    res = await conn.execute('''
      SELECT COUNT(*) 
      FROM subscriptions 
      WHERE is_active = true AND ends_at > NOW()
    ''');
    print('Active subscriptions: ${res.first[0]}\n');

    // Test 4: Check trial periods
    print('=== TEST 4: Users with Trial Info ===');
    res = await conn.execute('''
      SELECT 
        user_type,
        COUNT(*) as total,
        COUNT(trial_ends_at) as with_trial,
        SUM(CASE WHEN trial_ends_at > NOW() THEN 1 ELSE 0 END) as active_trial
      FROM users
      WHERE user_type IN ('Broker', 'Builder', 'Developer')
      GROUP BY user_type
    ''');
    for (var row in res) {
      print('${row[0]}: Total=${row[1]}, WithTrial=${row[2]}, ActiveTrial=${row[3]}');
    }
    print('');

    // Test 5: Check upcoming suspensions (7 days)
    print('=== TEST 5: Upcoming Suspensions (7 days) ===');
    res = await conn.execute('''
      WITH upcoming AS (
        SELECT
          u.id,
          u.user_type,
          u.name,
          u.company_name,
          u.trial_ends_at,
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
      )
      SELECT 
        user_type,
        name,
        company_name,
        trial_ends_at,
        valid_till,
        GREATEST(
          0,
          CEIL(EXTRACT(EPOCH FROM (valid_till - NOW())) / 86400.0)
        )::int AS days_left
      FROM upcoming
      WHERE valid_till IS NOT NULL
        AND valid_till >= NOW()
        AND valid_till <= NOW() + INTERVAL '7 days'
      ORDER BY valid_till ASC
      LIMIT 10
    ''');
    
    if (res.isEmpty) {
      print('❌ No suspensions found in next 7 days');
    } else {
      print('Found ${res.length} suspensions:');
      for (var row in res) {
        print('  - ${row[0]}: ${row[1] ?? row[2]} | Valid till: ${row[4]} | Days left: ${row[5]}');
      }
    }
    print('');

    // Test 6: Check upcoming suspensions (30 days)
    print('=== TEST 6: Upcoming Suspensions (30 days) ===');
    res = await conn.execute('''
      WITH upcoming AS (
        SELECT
          u.id,
          u.user_type,
          u.name,
          u.company_name,
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
      )
      SELECT 
        user_type,
        name,
        company_name,
        valid_till,
        GREATEST(
          0,
          CEIL(EXTRACT(EPOCH FROM (valid_till - NOW())) / 86400.0)
        )::int AS days_left
      FROM upcoming
      WHERE valid_till IS NOT NULL
        AND valid_till >= NOW()
        AND valid_till <= NOW() + INTERVAL '30 days'
      ORDER BY valid_till ASC
      LIMIT 10
    ''');
    
    if (res.isEmpty) {
      print('❌ No suspensions found in next 30 days');
    } else {
      print('Found ${res.length} suspensions:');
      for (var row in res) {
        print('  - ${row[0]}: ${row[1] ?? row[2]} | Valid till: ${row[3]} | Days left: ${row[4]}');
      }
    }
    print('');

    // Test 7: Check all users with validity info
    print('=== TEST 7: All Users Validity Status ===');
    res = await conn.execute('''
      SELECT
        u.user_type,
        u.name,
        u.company_name,
        u.trial_ends_at,
        (
          SELECT MAX(s.ends_at)
          FROM subscriptions s
          WHERE s.user_id = u.id
            AND s.is_active = true
            AND s.ends_at > NOW()
        ) as subscription_ends,
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
      ORDER BY valid_till ASC NULLS LAST
      LIMIT 20
    ''');
    
    print('Sample of users with validity info:');
    for (var row in res) {
      final validTill = row[5];
      final status = validTill == null 
          ? 'NO VALIDITY' 
          : (validTill as DateTime).isBefore(DateTime.now()) 
              ? 'EXPIRED' 
              : 'ACTIVE';
      print('  - ${row[0]}: ${row[1] ?? row[2]} | Trial: ${row[3]} | Sub: ${row[4]} | Valid: ${row[5]} | Status: $status');
    }
    print('');

    // Test 8: Check recent payments
    print('=== TEST 8: Recent Payments (7 days) ===');
    res = await conn.execute('''
      SELECT COUNT(*) 
      FROM subscriptions 
      WHERE created_at >= NOW() - INTERVAL '7 days'
    ''');
    print('Payments in last 7 days: ${res.first[0]}\n');

    print('=== TEST 9: Recent Payments (30 days) ===');
    res = await conn.execute('''
      SELECT COUNT(*) 
      FROM subscriptions 
      WHERE created_at >= NOW() - INTERVAL '30 days'
    ''');
    print('Payments in last 30 days: ${res.first[0]}\n');

  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await conn?.close();
    print('\n✅ Connection closed');
  }
}
