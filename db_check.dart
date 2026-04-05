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

  final res = await conn.execute("SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'generate_user_code';");
  for (final row in res) {
    print("--- FUNCTION DEF ---");
    print(row[0].toString().replaceAll('\r', ''));
    print("--------------------");
  }

  await conn.close();
}
