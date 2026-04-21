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
    // Old condition (broken for builders without active subscription)
    var old = await conn.execute('''
      SELECT COUNT(*)
      FROM properties p
      JOIN users u ON u.id = p.user_id
      WHERE p.is_visible = true
        AND p.auto_delete_at > NOW()
        AND u.is_active = true
        AND (u.user_type = 'Broker' OR u.trial_ends_at > NOW() OR EXISTS(
          SELECT 1 FROM subscriptions s WHERE s.user_id = u.id AND s.is_active = true AND s.ends_at > NOW()
        ))
        AND (p.is_deleted = false OR p.is_deleted IS NULL)
        AND (p.is_approved = true)
        AND (u.user_type = 'Builder' OR u.user_type = 'Developer')
    ''');
    print('OLD query - builder properties visible: ' + old.first[0].toString());

    // Fixed condition  
    var fixed = await conn.execute('''
      SELECT COUNT(*)
      FROM properties p
      JOIN users u ON u.id = p.user_id
      WHERE p.is_visible = true
        AND p.auto_delete_at > NOW()
        AND u.is_active = true
        AND (u.user_type IN ('Builder', 'Developer') OR u.user_type = 'Broker' OR u.trial_ends_at > NOW() OR EXISTS(
          SELECT 1 FROM subscriptions s WHERE s.user_id = u.id AND s.is_active = true AND s.ends_at > NOW()
        ))
        AND (p.is_deleted = false OR p.is_deleted IS NULL)
        AND (p.is_approved = true)
        AND (u.user_type = 'Builder' OR u.user_type = 'Developer')
    ''');
    print('FIXED query - builder properties visible: ' + fixed.first[0].toString());

  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
