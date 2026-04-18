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
    await conn.execute("ALTER TABLE users ADD COLUMN email VARCHAR(255) UNIQUE");
    print("Added email column.");
  } catch (e) {
    print("Column already exists or error: $e");
  }

  await conn.close();
}
