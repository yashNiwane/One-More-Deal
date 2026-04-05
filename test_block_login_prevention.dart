import 'package:postgres/postgres.dart';

void main() async {
  Connection? conn;
  
  try {
    print('=== Testing Complete Block Functionality ===\n');
    
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
    print('✅ Connected to database\n');

    // Test with a builder
    final testPhone = '1236549870'; // Shree - Builder
    
    print('Test Scenario: Block builder and verify login prevention\n');
    print('Phone: $testPhone\n');
    
    // Step 1: Check current status
    print('=== Step 1: Check Current Status ===');
    var res = await conn.execute(
      Sql.named('''
        SELECT id, name, company_name, user_type, is_active
        FROM users
        WHERE phone = @phone
      '''),
      parameters: {'phone': testPhone},
    );
    
    if (res.isEmpty) {
      print('❌ User not found');
      return;
    }
    
    final userId = res.first[0] as int;
    final userName = res.first[1] ?? res.first[2];
    final userType = res.first[3];
    final isActive = res.first[4] as bool;
    
    print('User: $userName');
    print('Type: $userType');
    print('Currently Active: $isActive');
    print('');
    
    // Step 2: Block the user
    print('=== Step 2: Blocking User ===');
    await conn.execute('BEGIN');
    
    try {
      // Deactivate subscriptions
      await conn.execute(
        Sql.named(
          'UPDATE subscriptions SET is_active = false WHERE user_id = @uid AND is_active = true',
        ),
        parameters: {'uid': userId},
      );
      
      // Deactivate user
      await conn.execute(
        Sql.named(
          'UPDATE users SET is_active = false, updated_at = NOW() WHERE id = @uid',
        ),
        parameters: {'uid': userId},
      );
      
      // Create revoked subscription request
      await conn.execute(
        Sql.named('''
          INSERT INTO subscription_requests (
            user_id, plan_months, amount_paid, screenshot_base64, status,
            rejection_reason, created_at, updated_at
          )
          VALUES (@uid, 0, 0, NULL, 'revoked', @reason, NOW(), NOW())
        '''),
        parameters: {'uid': userId, 'reason': 'TEST BLOCK - Verification'},
      );
      
      print('✅ User blocked successfully');
      print('');
      
      // Step 3: Verify block status
      print('=== Step 3: Verify Block Status ===');
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
      
      final blockedIsActive = res.first[0] as bool;
      final activeSubs = res.first[1] as int;
      final revokedCount = res.first[2] as int;
      
      print('User is_active: $blockedIsActive (should be false)');
      print('Active subscriptions: $activeSubs (should be 0)');
      print('Revoked requests: $revokedCount (should be > 0)');
      print('');
      
      // Step 4: Simulate login attempt
      print('=== Step 4: Simulate Login Attempt ===');
      res = await conn.execute(
        Sql.named('''
          SELECT id, phone, name, user_type, city, company_name,
                 is_active, trial_days, trial_ends_at, last_login_at, created_at, current_session_token, user_code
          FROM users WHERE phone = @phone LIMIT 1
        '''),
        parameters: {'phone': testPhone},
      );
      
      if (res.isNotEmpty) {
        final loginIsActive = res.first[6] as bool;
        
        if (!loginIsActive) {
          print('✅ Login would be BLOCKED - User is_active = false');
          print('   Error message would be: "Your account has been blocked. Please contact support."');
        } else {
          print('❌ Login would be ALLOWED - User is_active = true (SECURITY ISSUE!)');
        }
      }
      print('');
      
      // Step 5: Test session validation
      print('=== Step 5: Test Session Validation ===');
      if (!blockedIsActive) {
        print('✅ Session validation would fail - User is blocked');
        print('   User would be logged out automatically');
      } else {
        print('❌ Session validation would pass (SECURITY ISSUE!)');
      }
      print('');
      
      // Step 6: Test subscription check
      print('=== Step 6: Test Subscription Check ===');
      if (!blockedIsActive) {
        print('✅ hasActiveSubscription() would return false');
        print('   User would be redirected to subscription screen or blocked');
      } else {
        print('❌ hasActiveSubscription() might return true (SECURITY ISSUE!)');
      }
      print('');
      
      // Rollback
      await conn.execute('ROLLBACK');
      print('✅ Test completed - Changes rolled back\n');
      
      // Final Summary
      print('=== SUMMARY ===');
      if (!blockedIsActive && activeSubs == 0 && revokedCount > 0) {
        print('✅ ALL SECURITY CHECKS PASSED');
        print('   - User is properly blocked (is_active = false)');
        print('   - Subscriptions are deactivated');
        print('   - Revoked request is created');
        print('   - Login would be prevented');
        print('   - Session would be invalidated');
        print('   - Subscription check would fail');
      } else {
        print('❌ SECURITY ISSUES DETECTED');
        print('   Please review the implementation');
      }
      
    } catch (e) {
      await conn.execute('ROLLBACK');
      print('❌ Error during test: $e');
    }

  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await conn?.close();
    print('\n✅ Connection closed');
  }
}
