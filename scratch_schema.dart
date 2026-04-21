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

  final res = await conn.execute("SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'users'");
  for (var row in res) {
    print('${row[0]} - ${row[1]} - Nullable: ${row[2]}');
  }
  await conn.close();
}
