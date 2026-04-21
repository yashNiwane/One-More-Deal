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

  final res = await conn.execute("SELECT * FROM properties WHERE society_name ILIKE '%Raghu Kul%'");
  print(res.length);
  for (final row in res) {
    print(row);
  }

  // Delete it
  await conn.execute("DELETE FROM properties WHERE society_name ILIKE '%Raghu Kul%'");
  print('Deleted');

  await conn.close();
}
