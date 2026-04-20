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
      SELECT column_name, data_type, udt_name 
      FROM information_schema.columns 
      WHERE table_name = 'properties'
        AND column_name IN ('category', 'listing_type', 'floor_category');
    ''');
    for (var row in res) {
      print(row[0].toString() + ': ' + row[1].toString() + ' (' + row[2].toString() + ')');
    }
  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
