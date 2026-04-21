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
    print('Adding available_for column to properties table...');
    await conn.execute('''
      ALTER TABLE properties
      ADD COLUMN IF NOT EXISTS available_for TEXT
    ''');
    print('Column added successfully.');
  } catch (e) {
    print('Error updating schema: $e');
  } finally {
    await conn.close();
  }
}
