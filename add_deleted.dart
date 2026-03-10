import 'package:postgres/postgres.dart';

Future<void> main() async {
  print('Connecting to DB...');
  try {
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
    print('Connected. Adding is_deleted column...');
    await conn.execute('ALTER TABLE properties ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false;');
    print('Done.');
    await conn.close();
  } catch (e) {
    print('Failed: \$e');
  }
}
