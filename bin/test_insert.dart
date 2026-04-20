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
    await conn.execute("CREATE TABLE IF NOT EXISTS test_enum_insert ( id serial, t varchar(50) )");
    await conn.execute("INSERT INTO test_enum_insert (t) VALUES ('Residential'::property_category)");
    print('Inserted successfully with text column and enum cast!');
    await conn.execute("DROP TABLE test_enum_insert");
  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
