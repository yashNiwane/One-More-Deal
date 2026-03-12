import 'dart:convert';
import 'package:postgres/postgres.dart';

void main() async {
  final conn = await Connection.open(
    Endpoint(
      host:     'one-more-deal.cnkisqqwmvy2.ap-south-1.rds.amazonaws.com',
      port:     5432,
      database: 'OneMoreDeal',
      username: 'postgres',
      password: 'MmKnDMm#14',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );

  final res = await conn.execute("SELECT id, phone, trial_ends_at, NOW() as current_time FROM users WHERE phone = '9158120359'");
  for (final row in res) {
    var out = {};
    out['phone'] = row[1];
    
    final trialEndsAt = row[2] as DateTime?;
    out['trialEndsAt'] = trialEndsAt?.toIso8601String();
    
    if (trialEndsAt != null) {
      final diff = trialEndsAt.difference(DateTime.now().toUtc()).inDays;
      out['diff'] = diff;
      out['isTrial'] = diff > 0;
    }
    print(jsonEncode(out));
  }

  await conn.close();
}
