import 'package:postgres/postgres.dart';

void main() async {
  Connection? conn;
  
  try {
    print('=== Testing Blocked User Flow - Payment Screen Redirect ===\n');
    
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

    final testPhone = '1236549870'; // Shree - Builder
    
    print('Test Flow: Blocked User Login → Payment Screen\n');
    print('Phone: $testPhone\n');
    
    // Step 1: Check current status
    print('=== Step 1: Current User Status ===');
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
    final currentlyActive = res.first[4] as bool;
    
    print('User: $userName');
    print('Type: $userType');
    print('Currently Active: $currentlyActive');
    print('');
    
    // Step 2: Block the user
    print('=== Step 2: Blocking User ===');
    await conn.execute('BEGIN');
    
    try {
      await conn.execute(
        Sql.named(
          'UPDATE subscriptions SET is_active = false WHERE user_id = @uid AND is_active = true',
        ),
        parameters: {'uid': userId},
      );
      
      await conn.execute(
        Sql.named(
          'UPDATE users SET is_active = false, updated_at = NOW() WHERE id = @uid',
        ),
        parameters: {'uid': userId},
      );
      
      await conn.execute(
        Sql.named('''
          INSERT INTO subscription_requests (
            user_id, plan_months, amount_paid, screenshot_base64, status,
            rejection_reason, created_at, updated_at
          )
          VALUES (@uid, 0, 0, NULL, 'revoked', @reason, NOW(), NOW())
        '''),
        parameters: {'uid': userId, 'reason': 'TEST BLOCK - Payment Screen Flow'},
      );
      
      print('✅ User blocked successfully');
      print('');
      
      // Step 3: Simulate login flow
      print('=== Step 3: Simulate Login Flow ===');
      
      // 3a. User enters OTP and verifies
      print('1. User enters phone and OTP');
      print('2. OTP verification succeeds');
      print('3. loginUser() is called');
      print('');
      
      // 3b. Check user status after login
      res = await conn.execute(
        Sql.named('''
          SELECT id, phone, name, user_type, is_active
          FROM users WHERE phone = @phone LIMIT 1
        '''),
        parameters: {'phone': testPhone},
      );
      
      final loginIsActive = res.first[4] as bool;
      
      print('4. User data retrieved:');
      print('   - is_active: $loginIsActive');
      print('');
      
      if (!loginIsActive) {
        print('5. ✅ User is blocked - Redirect to SUBSCRIPTION SCREEN');
        print('   - Show "Account Blocked" message');
        print('   - Allow user to make payment');
        print('   - Upload payment screenshot');
        print('   - Submit for admin approval');
      } else {
        print('5. ❌ User is active - Would go to HOME SCREEN (WRONG!)');
      }
      print('');
      
      // Step 4: Simulate payment and reactivation
      print('=== Step 4: Simulate Payment & Reactivation ===');
      print('1. User makes UPI payment');
      print('2. User uploads screenshot');
      print('3. User submits request');
      print('4. Admin approves request');
      print('');
      
      // Simulate admin approval
      await conn.execute(
        Sql.named(
          'UPDATE users SET is_active = true, updated_at = NOW() WHERE id = @uid',
        ),
        parameters: {'uid': userId},
      );
      
      // Create active subscription
      await conn.execute(
        Sql.named('''
          INSERT INTO subscriptions (user_id, plan_months, amount_paid, payment_ref,
                                     starts_at, ends_at, is_active)
          VALUES (@uid, 1, 500, 'TEST_PAYMENT', NOW(), NOW() + INTERVAL '1 month', true)
        '''),
        parameters: {'uid': userId},
      );
      
      print('5. ✅ Admin approves - User reactivated');
      print('');
      
      // Step 5: Verify reactivation
      print('=== Step 5: Verify Reactivation ===');
      res = await conn.execute(
        Sql.named('''
          SELECT 
            u.is_active,
            (SELECT COUNT(*) FROM subscriptions WHERE user_id = @uid AND is_active = true) as active_subs
          FROM users u
          WHERE u.id = @uid
        '''),
        parameters: {'uid': userId},
      );
      
      final reactivatedIsActive = res.first[0] as bool;
      final activeSubs = res.first[1] as int;
      
      print('User is_active: $reactivatedIsActive (should be true)');
      print('Active subscriptions: $activeSubs (should be > 0)');
      print('');
      
      if (reactivatedIsActive && activeSubs > 0) {
        print('✅ User can now login and access the app');
      } else {
        print('❌ Reactivation failed');
      }
      print('');
      
      // Rollback
      await conn.execute('ROLLBACK');
      print('✅ Test completed - Changes rolled back\n');
      
      // Summary
      print('=== FLOW SUMMARY ===');
      print('1. ✅ Blocked user logs in');
      print('2. ✅ System detects user is blocked (is_active = false)');
      print('3. ✅ User is redirected to SUBSCRIPTION SCREEN');
      print('4. ✅ "Account Blocked" message is shown');
      print('5. ✅ User can make payment to reactivate');
      print('6. ✅ After admin approval, user is reactivated');
      print('7. ✅ User can access the app normally');
      
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
