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

  print('Connected, sanitizing builder properties...');

  try {
    final query = '''
      UPDATE properties
      SET is_visible = false
      WHERE is_visible = true
        AND user_id IN (SELECT id FROM users WHERE user_type IN ('Builder', 'Developer'))
        AND id NOT IN (
          SELECT MAX(id)
          FROM properties
          WHERE is_visible = true
          GROUP BY user_id
        )
      RETURNING id;
    ''';
    
    final res = await conn.execute(query);
    print('Successfully deactivated ${res.length} older builder properties, keeping only the newest active per builder.');
    
  } catch (e) {
    print('Error: $e');
  }

  await conn.close();
  print('Done!');
}
