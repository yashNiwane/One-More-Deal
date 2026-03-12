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
    final res = await conn.execute("SELECT id, category::text FROM properties WHERE id = 30");
    for (var row in res) {
      print('ID: ' + row[0].toString() + ' | Category: ' + row[1].toString());
    }
    
    final resUser = await conn.execute("SELECT user_type FROM users WHERE id = (SELECT user_id FROM properties WHERE id = 30)");
    for (var row in resUser) {
      print('User Type for ID 30: ' + row[0].toString());
    }
  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
