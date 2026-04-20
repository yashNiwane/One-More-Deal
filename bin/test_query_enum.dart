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
    var res = await conn.execute(
      Sql.named("SELECT id, category FROM properties WHERE category = @category::property_category LIMIT 1"),
      parameters: {'category': 'Residential'}
    );
    print('Matches: \${res.length}');
  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
