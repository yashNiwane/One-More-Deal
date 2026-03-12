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
    final res = await conn.execute("SELECT id, user_id, category::text, listing_type::text, furnishing_status, parking FROM properties ORDER BY id DESC LIMIT 1");
    for (var row in res) {
      print('--- NEWEST PROPERTY ---');
      print('ID: ' + row[0].toString() + ' | Cat: ' + row[2].toString() + ' | LType: ' + row[3].toString() + ' | Furn: ' + row[4].toString() + ' | Park: ' + row[5].toString());
    }
  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
