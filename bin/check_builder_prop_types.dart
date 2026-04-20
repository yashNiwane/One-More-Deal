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
    var res = await conn.execute('''
      SELECT p.id, p.category, p.listing_type, u.name
      FROM properties p
      JOIN users u ON u.id = p.user_id
      WHERE (u.user_type = 'Builder' OR u.user_type = 'Developer')
    ''');
    
    for (var r in res) {
      print('ID: ' + r[0].toString() + ' | Cat: ' + r[1].toString() + ' | ListType: ' + r[2].toString() + ' | Name: ' + r[3].toString());
    }

  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
