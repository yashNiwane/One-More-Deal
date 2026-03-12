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

  await conn.execute("UPDATE users SET is_active = true WHERE phone = '9158120359'");
  print('User 9158120359 reactivated.');

  await conn.close();
}
