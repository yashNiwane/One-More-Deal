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
    print('Starting database migration for ENUM types...');
    await conn.execute("ALTER TABLE properties ALTER COLUMN category TYPE VARCHAR(50) USING category::text;");
    print('1. category altered to VARCHAR(50)');
    
    await conn.execute("ALTER TABLE properties ALTER COLUMN listing_type TYPE VARCHAR(50) USING listing_type::text;");
    print('2. listing_type altered to VARCHAR(50)');
    
    await conn.execute("ALTER TABLE properties ALTER COLUMN floor_category TYPE VARCHAR(50) USING floor_category::text;");
    print('3. floor_category altered to VARCHAR(50)');
    
    print('Database migration completed successfully!');
  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
