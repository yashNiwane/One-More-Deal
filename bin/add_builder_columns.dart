import 'package:postgres/postgres.dart';

void main() async {
  final conn = await Connection.open(
    Endpoint(
      host:     'one-more-deal.cnkisqqwmvy2.ap-south-1.rds.amazonaws.com',
      port:     5432,
      database: 'OneMoreDeal',
      username: 'postgres',
      password: 'MmKnDMm#14',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );

  try {
    print('Adding builder columns to properties table...');
    
    await conn.execute('''
      ALTER TABLE properties 
      ADD COLUMN IF NOT EXISTS rera_no TEXT,
      ADD COLUMN IF NOT EXISTS total_buildings INTEGER,
      ADD COLUMN IF NOT EXISTS amenities_count INTEGER,
      ADD COLUMN IF NOT EXISTS building_structure TEXT,
      ADD COLUMN IF NOT EXISTS total_units INTEGER,
      ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT true,
      ADD COLUMN IF NOT EXISTS variants JSONB
    ''');
    
    print('Columns added successfully.');
  } catch (e) {
    print('Error updating schema: $e');
  } finally {
    await conn.close();
  }
}
