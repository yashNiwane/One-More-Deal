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

    // Test 1: Check builder users
    print('=== TEST 1: Builder/Developer Users ===');
    var res = await conn.execute('''
      SELECT id, name, company_name, phone, user_type, is_active
      FROM users
      WHERE user_type IN ('Builder', 'Developer')
      ORDER BY name
    ''');
    
    print('Found ${res.length} builders/developers:');
    for (var row in res) {
      print('  - ID: ${row[0]} | Name: ${row[1] ?? row[2]} | Phone: ${row[3]} | Type: ${row[4]} | Active: ${row[5]}');
    }
    print('');

    // Test 2: Check subscriptions for builders
    print('=== TEST 2: Active Subscriptions for Builders ===');
    res = await conn.execute('''
      SELECT u.id, u.name, u.company_name, u.phone, u.user_type, s.ends_at, s.is_active
      FROM users u
      LEFT JOIN subscriptions s ON s.user_id = u.id AND s.is_active = true AND s.ends_at > NOW()
      WHERE u.user_type IN ('Builder', 'Developer')
      ORDER BY u.name
    ''');
    
    print('Subscription status:');
    for (var row in res) {
      final hasActiveSub = row[6] == true;
      print('  - ${row[1] ?? row[2]} (${row[3]}) | Type: ${row[4]} | Active Sub: $hasActiveSub | Ends: ${row[5]}');
    }
    print('');

    // Test 3: Test blocking a builder (dry run - we'll rollback)
    print('=== TEST 3: Testing Block Functionality (DRY RUN) ===');
    
    // Find a builder to test with
    res = await conn.execute('''
      SELECT id, name, company_name, phone, user_type
      FROM users
      WHERE user_type IN ('Builder', 'Developer')
      LIMIT 1
    ''');
    
    if (res.isEmpty) {
      print('❌ No builders found to test with');
    } else {
      final testUserId = res.first[0] as int;
      final testUserName = res.first[1] ?? res.first[2];
      final testUserPhone = res.first[3] as String;
      final testUserType = res.first[4];
      
      print('Testing with: $testUserName ($testUserPhone) - Type: $testUserType');
      print('');
      
      // Start a transaction for dry run
      await conn.execute('BEGIN');
      
      try {
        // Step 1: Deactivate subscriptions
        print('Step 1: Deactivating subscriptions...');
        await conn.execute(
          Sql.named(
            'UPDATE subscriptions SET is_active = false WHERE user_id = @uid AND is_active = true',
          ),
          parameters: {'uid': testUserId},
        );
        print('✅ Subscriptions deactivated');
        
        // Step 2: Deactivate user
        print('Step 2: Deactivating user...');
        await conn.execute(
          Sql.named(
            'UPDATE users SET is_active = false, updated_at = NOW() WHERE id = @uid',
          ),
          parameters: {'uid': testUserId},
        );
        print('✅ User deactivated');
        
        // Step 3: Create revoked subscription request
        print('Step 3: Creating revoked subscription request...');
        await conn.execute(
          Sql.named('''
            INSERT INTO subscription_requests (
              user_id, plan_months, amount_paid, screenshot_base64, status,
              rejection_reason, created_at, updated_at
            )
            VALUES (@uid, 0, 0, NULL, 'revoked', @reason, NOW(), NOW())
          '''),
          parameters: {'uid': testUserId, 'reason': 'TEST BLOCK - DRY RUN'},
        );
        print('✅ Revoked subscription request created');
        
        // Verify the changes
        print('');
        print('Verifying changes:');
        res = await conn.execute(
          Sql.named('''
            SELECT u.is_active, 
                   (SELECT COUNT(*) FROM subscriptions WHERE user_id = @uid AND is_active = true) as active_subs,
                   (SELECT COUNT(*) FROM subscription_requests WHERE user_id = @uid AND status = 'revoked') as revoked_requests
            FROM users u
            WHERE u.id = @uid
          '''),
          parameters: {'uid': testUserId},
        );
        
        if (res.isNotEmpty) {
          final isActive = res.first[0] as bool;
          final activeSubs = res.first[1] as int;
          final revokedRequests = res.first[2] as int;
          
          print('  - User is_active: $isActive (should be false)');
          print('  - Active subscriptions: $activeSubs (should be 0)');
          print('  - Revoked requests: $revokedRequests (should be > 0)');
          
          if (!isActive && activeSubs == 0 && revokedRequests > 0) {
            print('');
            print('✅ Block functionality working correctly!');
          } else {
            print('');
            print('❌ Block functionality has issues!');
          }
        }
        
        // Rollback the transaction
        print('');
        print('Rolling back changes (dry run)...');
        await conn.execute('ROLLBACK');
        print('✅ Changes rolled back');
        
      } catch (e) {
        await conn.execute('ROLLBACK');
        print('❌ Error during test: $e');
      }
    }
    
    print('');
    print('=== TEST 4: Check if subscription_requests table exists ===');
    res = await conn.execute('''
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'subscription_requests'
      )
    ''');
    
    final tableExists = res.first[0] as bool;
    print('subscription_requests table exists: $tableExists');
    
    if (tableExists) {
      res = await conn.execute('''
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'subscription_requests'
        ORDER BY ordinal_position
      ''');
      
      print('Table columns:');
      for (var row in res) {
        print('  - ${row[0]}: ${row[1]}');
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
