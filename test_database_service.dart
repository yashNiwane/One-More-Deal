import 'lib/services/database_service.dart';

void main() async {
  print('Testing DatabaseService methods...\n');
  
  try {
    // Test 1: getAdminCompactOverviewStats
    print('=== Test 1: getAdminCompactOverviewStats ===');
    final overview = await DatabaseService.instance.getAdminCompactOverviewStats(
      suspensionDays: 7,
    );
    print('Overview stats:');
    overview.forEach((key, value) {
      print('  $key: $value');
    });
    print('');

    // Test 2: getAdminUpcomingSuspensions (7 days)
    print('=== Test 2: getAdminUpcomingSuspensions (7 days) ===');
    final susp7 = await DatabaseService.instance.getAdminUpcomingSuspensions(days: 7);
    print('Found ${susp7.length} suspensions in next 7 days:');
    for (var s in susp7) {
      print('  - ${s['userType']}: ${s['name']} | Phone: ${s['phone']} | Days: ${s['daysLeft']}');
    }
    print('');

    // Test 3: getAdminUpcomingSuspensions (30 days)
    print('=== Test 3: getAdminUpcomingSuspensions (30 days) ===');
    final susp30 = await DatabaseService.instance.getAdminUpcomingSuspensions(days: 30);
    print('Found ${susp30.length} suspensions in next 30 days:');
    for (var s in susp30) {
      print('  - ${s['userType']}: ${s['name']} | Phone: ${s['phone']} | Days: ${s['daysLeft']}');
    }
    print('');

    // Test 4: getAdminRecentPayments (7 days)
    print('=== Test 4: getAdminRecentPayments (7 days) ===');
    final pay7 = await DatabaseService.instance.getAdminRecentPayments(days: 7);
    print('Found ${pay7.length} payments in last 7 days:');
    for (var p in pay7) {
      print('  - ${p['name']} | Phone: ${p['phone']} | Amount: ${p['amount']}');
    }
    print('');

    // Test 5: getAdminRecentPayments (30 days)
    print('=== Test 5: getAdminRecentPayments (30 days) ===');
    final pay30 = await DatabaseService.instance.getAdminRecentPayments(days: 30);
    print('Found ${pay30.length} payments in last 30 days:');
    for (var p in pay30) {
      print('  - ${p['name']} | Phone: ${p['phone']} | Amount: ${p['amount']}');
    }
    print('');

    print('✅ All tests completed successfully!');
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await DatabaseService.instance.disconnect();
  }
}
