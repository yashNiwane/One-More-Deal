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
  
  try {
    final res = await conn.execute("SELECT id, furnishing_status, pg_typeof(furnishing_status) FROM properties ORDER BY id DESC LIMIT 5");
    for (var row in res) {
      print('ID: ' + row[0].toString() + ' | Furnishing: ' + row[1].toString() + ' | Type: ' + row[2].toString());
    }
  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
