import 'package:postgres/postgres.dart';

void main() async {
  final conn = await Connection.open(
    Endpoint(
      host: 'one-more-deal.cnkisqqwmvy2.ap-south-1.rds.amazonaws.com',
      port: 5432,
      database: 'OneMoreDeal',
      username: 'postgres',
      password: 'MmKnDMm#14',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );

  final phone = '9356965875';

  // Expire the trial
  await conn.execute(Sql.named("UPDATE users SET trial_ends_at = NOW() - INTERVAL '1 day' WHERE phone = @phone"), parameters: {'phone': phone});
  print('Trial expired for $phone');
  
  // Get user ID
  final userRes = await conn.execute(Sql.named("SELECT id FROM users WHERE phone = @phone"), parameters: {'phone': phone});
  if (userRes.isNotEmpty) {
    final userId = userRes.first[0];
    print('User ID for $phone is $userId');
    // Delete any active subscriptions
    await conn.execute(Sql.named("DELETE FROM subscriptions WHERE user_id = @userId"), parameters: {'userId': userId});
    print('Subscriptions removed for user $phone (ID: $userId)');
  } else {
    print('User with phone $phone not found in the database.');
  }

  final res = await conn.execute(Sql.named("SELECT id, phone, name, trial_ends_at FROM users WHERE phone = @phone"), parameters: {'phone': phone});
  for (final row in res) {
    print('User status: \${row.toColumnMap()}');
  }

  await conn.close();
}
