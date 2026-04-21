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
    var query = '''
      SELECT p.id, p.area, p.city, p.is_visible, u.name, u.is_active, p.category, p.listing_type
      FROM properties p
      JOIN users u ON u.id = p.user_id
      WHERE (u.user_type = 'Builder' OR u.user_type = 'Developer')
        AND p.is_visible = true
        AND p.auto_delete_at > NOW()
        AND u.is_active = true
        AND (p.is_deleted = false OR p.is_deleted IS NULL)
        AND p.is_approved = true
        AND LOWER(p.city) = LOWER('Pune')
    ''';
    
    var res2 = await conn.execute(query);
    print('Fully strictly matched Builder property count for City "Pune": ' + res2.length.toString());

    if (res2.isNotEmpty) {
      for (var r in res2) {
        print(r.toString());
      }
    }

  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
