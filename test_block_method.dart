import 'package:postgres/postgres.dart';

void main() async {
  Connection? conn;
  
  try {
    print('Testing blockUserByPhone method logic...\n');
    
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
    print('✅ Connected\n');

    // Test with a builder phone number
    final testPhone = '1236549870'; // Shree - Builder
    print('Testing with phone: $testPhone');
    
    // Step 1: Get user by phone
    print('\n=== Step 1: Get user by phone ===');
    var res = await conn.execute(
      Sql.named('''
        SELECT id, phone, name, user_type, city, company_name,
               is_active, trial_days, trial_ends_at, last_login_at, created_at, current_session_token, user_code
        FROM users WHERE phone = @phone LIMIT 1
      '''),
      parameters: {'phone': testPhone},
    );
    
    if (res.isEmpty) {
      print('❌ User not found for phone $testPhone');
      return;
    }
    
    final userId = res.first[0] as int;
    final userName = res.first[2] ?? res.first[5];
    final userType = res.first[3];
    print('✅ Found user: ID=$userId, Name=$userName, Type=$userType');
    
    // Start transaction for dry run
    await conn.execute('BEGIN');
    
    try {
      // Step 2: Deactivate subscriptions
      print('\n=== Step 2: Deactivate subscriptions ===');
      res = await conn.execute(
        Sql.named(
          'UPDATE subscriptions SET is_active = false WHERE user_id = @uid AND is_active = true RETURNING id',
        ),
        parameters: {'uid': userId},
      );
      print('✅ Deactivated ${res.length} subscription(s)');
      
      // Step 3: Deactivate user
      print('\n=== Step 3: Deactivate user ===');
      await conn.execute(
        Sql.named(
          'UPDATE users SET is_active = false, updated_at = NOW() WHERE id = @uid',
        ),
        parameters: {'uid': userId},
      );
      print('✅ User deactivated');
      
      // Step 4: Create revoked subscription request
      print('\n=== Step 4: Create revoked subscription request ===');
      res = await conn.execute(
        Sql.named('''
          INSERT INTO subscription_requests (
            user_id, plan_months, amount_paid, screenshot_base64, status,
            rejection_reason, created_at, updated_at
          )
          VALUES (@uid, 0, 0, NULL, 'revoked', @reason, NOW(), NOW())
          RETURNING id
        '''),
        parameters: {'uid': userId, 'reason': 'TEST BLOCK FOR BUILDER'},
      );
      print('✅ Created revoked request with ID: ${res.first[0]}');
      
      // Verify final state
      print('\n=== Verification ===');
      res = await conn.execute(
        Sql.named('''
          SELECT 
            u.is_active,
            (SELECT COUNT(*) FROM subscriptions WHERE user_id = @uid AND is_active = true) as active_subs,
            (SELECT COUNT(*) FROM subscription_requests WHERE user_id = @uid AND status = 'revoked') as revoked_count
          FROM users u
          WHERE u.id = @uid
        '''),
        parameters: {'uid': userId},
      );
      
      final isActive = res.first[0] as bool;
      final activeSubs = res.first[1] as int;
      final revokedCount = res.first[2] as int;
      
      print('User is_active: $isActive');
      print('Active subscriptions: $activeSubs');
      print('Revoked requests: $revokedCount');
      
      if (!isActive && activeSubs == 0 && revokedCount > 0) {
        print('\n✅ ALL CHECKS PASSED - Block functionality works for builders!');
      } else {
        print('\n❌ CHECKS FAILED');
      }
      
      // Rollback
      await conn.execute('ROLLBACK');
      print('\n✅ Changes rolled back (dry run completed)');
      
    } catch (e) {
      await conn.execute('ROLLBACK');
      print('\n❌ Error: $e');
      rethrow;
    }
    
    // Additional check: Test with different user types
    print('\n\n=== Testing with different user types ===');
    res = await conn.execute('''
      SELECT user_type, COUNT(*) as count
      FROM users
      WHERE user_type IN ('Broker', 'Builder', 'Developer')
      GROUP BY user_type
    ''');
    
    print('User type distribution:');
    for (var row in res) {
      print('  - ${row[0]}: ${row[1]} users');
    }
    
    // Check if there are any blocked builders
    print('\n=== Currently blocked builders/developers ===');
    res = await conn.execute('''
      SELECT u.name, u.company_name, u.phone, u.user_type, u.is_active
      FROM users u
      WHERE u.user_type IN ('Builder', 'Developer')
        AND u.is_active = false
    ''');
    
    if (res.isEmpty) {
      print('No blocked builders/developers found');
    } else {
      print('Found ${res.length} blocked builder(s)/developer(s):');
      for (var row in res) {
        print('  - ${row[0] ?? row[1]} (${row[2]}) | Type: ${row[3]} | Active: ${row[4]}');
      }
    }

  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await conn?.close();
    print('\n✅ Connection closed');
  }
}
