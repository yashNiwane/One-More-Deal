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
    print('Testing query similar to addProperty insert...');
    
    // Testing the cast failure:
    final res = await conn.execute(
      Sql.named("SELECT @cat::property_category"),
      parameters: {'cat': 'Residential'}
    );
    print('Success: \$res');
    
    // testing insert
    await conn.execute("CREATE TABLE IF NOT EXISTS test_insert_app (id serial, cat varchar(50))");
    await conn.execute(
       Sql.named("INSERT INTO test_insert_app (cat) VALUES (@cat::property_category)"),
       parameters: {'cat': 'Commercial'}
    );
    print('Insert succeeded');
    await conn.execute("DROP TABLE test_insert_app");
    
  } catch (e) {
    print('Error caught: \$e');
  }

  await conn.close();
}
