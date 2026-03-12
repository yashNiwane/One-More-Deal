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

  final res = await conn.execute("SELECT * FROM subscriptions WHERE user_id = 9 AND is_active = true AND ends_at > NOW() ORDER BY ends_at DESC LIMIT 1");
  if (res.isEmpty) {
    print('NO ACTIVE SUB FOUND IN DB');
  } else {
    print('SUB FOUND: \${res.first.toColumnMap()}');
  }

  await conn.close();
}
