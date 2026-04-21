import 'package:postgres/postgres.dart';

Future<void> main() async {
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
    final rows = await conn.execute('''
      SELECT p.id, p.user_id, COALESCE(u.company_name, ''), COALESCE(u.name, '')
      FROM properties p
      JOIN users u ON u.id = p.user_id
      WHERE LOWER(COALESCE(u.company_name, '')) LIKE '%creoxy%'
         OR LOWER(COALESCE(u.name, '')) LIKE '%creoxy%'
      ORDER BY p.id
    ''');

    print('MATCH_COUNT=${rows.length}');
    for (final r in rows) {
      print('PROPERTY_ID=${r[0]} USER_ID=${r[1]} COMPANY=${r[2]} NAME=${r[3]}');
    }
  } finally {
    await conn.close();
  }
}
