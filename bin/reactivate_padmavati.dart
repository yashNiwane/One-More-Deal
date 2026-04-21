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
    // Give unlimited access (trial ends far in the future = year 2099)
    await conn.execute('''
      UPDATE users
      SET is_active = true,
          trial_ends_at = '2099-12-31 23:59:59'::timestamp
      WHERE id = 109
    ''');
    print('Padmanabh Developer (ID 109) given unlimited access until 2099.');

    // Restore property visibility
    await conn.execute('''
      UPDATE properties
      SET is_visible = true
      WHERE user_id = 109
        AND (is_deleted = false OR is_deleted IS NULL)
        AND auto_delete_at > NOW()
    ''');
    print('Properties restored and visible.');

    // Final check
    var check = await conn.execute('''
      SELECT p.id, p.society_name, p.city, p.is_visible, u.is_active, u.trial_ends_at
      FROM properties p
      JOIN users u ON u.id = p.user_id
      WHERE u.id = 109
        AND (p.is_deleted = false OR p.is_deleted IS NULL)
    ''');
    print('\nFinal state:');
    for (var r in check) {
      print('PropID: ' + r[0].toString() + ' | society: ' + r[1].toString() + ' | city: ' + r[2].toString() + ' | visible: ' + r[3].toString() + ' | user_active: ' + r[4].toString() + ' | trial_until: ' + r[5].toString());
    }

  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
