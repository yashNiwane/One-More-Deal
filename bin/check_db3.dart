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
    final res2 = await conn.execute("SELECT id, category, furnishing_status FROM properties ORDER BY id DESC LIMIT 10");
    print('--- Data last 10 ---');
    for (var row in res2) {
      print('ID: ' + row[0].toString() + ', Category: ' + row[1].toString() + ', Furnishing: ' + row[2].toString());
    }
    
    final res3 = await conn.execute("SELECT id FROM properties WHERE furnishing_status IS NOT NULL");
    print('--- Any not null? ---');
    print(res3.length.toString() + ' rows have furnishing_status not null');
  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
