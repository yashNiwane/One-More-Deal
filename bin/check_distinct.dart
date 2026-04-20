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
    var res = await conn.execute("SELECT DISTINCT category, listing_type FROM properties;");
    for (var r in res) {
      print('DB category: [' + r[0].toString() + '] listing_type: [' + r[1].toString() + ']');
    }
  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
