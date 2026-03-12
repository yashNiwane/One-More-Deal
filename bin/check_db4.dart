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
    final res = await conn.execute("SELECT id, user_id, category, listing_type, furnishing_status, parking FROM properties ORDER BY id DESC LIMIT 5");
    for (var row in res) {
      print('ID: \${row[0]} | User: \${row[1]} | Cat: \${row[2]} | ListType: \${row[3]} | Furn: \${row[4]} | Parking: \${row[5]}');
    }
  } catch (e) {
    print('Error: \$e');
  }

  await conn.close();
}
