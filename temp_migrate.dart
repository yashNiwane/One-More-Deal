import 'package:postgres/postgres.dart';

void main() async {
  print('Connecting to db...');
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
    print('Adding column...');
    await conn.execute('ALTER TABLE properties ADD COLUMN subarea TEXT;');
    print('Added column successfully.');
  } catch (e) {
    print('Error: $e');
  } finally {
    await conn.close();
  }
}
