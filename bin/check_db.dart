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

  final res = await conn.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'properties'");
  for (var row in res) {
    print(row[0]);
  }
  
  final res2 = await conn.execute("SELECT id, furnishing_status FROM properties ORDER BY id DESC LIMIT 5");
  print('--- Data ---');
  for (var row in res2) {
    print('ID: \${row[0]}, Furnishing: \${row[1]}');
  }

  await conn.close();
}
