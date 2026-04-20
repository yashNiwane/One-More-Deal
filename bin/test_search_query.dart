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
    var res = await conn.execute(Sql.named('''
      SELECT COUNT(*)
      FROM properties p
      WHERE (LOWER(p.society_name) LIKE LOWER(@searchQuery) OR
           LOWER(p.subarea) LIKE LOWER(@searchQuery) OR
           LOWER(p.area) LIKE LOWER(@searchQuery) OR
           LOWER(p.city) LIKE LOWER(@searchQuery) OR
           LOWER(p.category::text) LIKE LOWER(@searchQuery) OR
           LOWER(p.listing_type::text) LIKE LOWER(@searchQuery) OR
           LOWER(p.bhk_type) LIKE LOWER(@searchQuery) OR
           LOWER(p.flat_type) LIKE LOWER(@searchQuery) OR
           LOWER(p.furnishing_status) LIKE LOWER(@searchQuery) OR
           LOWER(p.availability) LIKE LOWER(@searchQuery) OR
           LOWER(p.description) LIKE LOWER(@searchQuery) OR
           LOWER(p.price::text) LIKE LOWER(@searchQuery))
    '''), parameters: {'searchQuery': '%test%'});
    print('Query succeeded');
  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
