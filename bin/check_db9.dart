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
    await conn.execute("UPDATE properties SET furnishing_status = 'Unfurnished' WHERE id = 30");
    print('Updated ID 30 directly');
  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
