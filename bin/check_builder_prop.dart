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
    var res2 = await conn.execute('''
      SELECT p.city, p.area
      FROM properties p
      JOIN users u ON u.id = p.user_id
      WHERE (u.user_type = 'Builder' OR u.user_type = 'Developer')
        AND p.is_visible = true
        AND p.auto_delete_at > NOW()
        AND u.is_active = true
        AND (p.is_deleted = false OR p.is_deleted IS NULL)
        AND (p.is_approved = true)
    ''');
    print('City of the single visible Builder property: ' + res2.first[0].toString() + ' (Area: ' + res2.first[1].toString() + ')');

  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
