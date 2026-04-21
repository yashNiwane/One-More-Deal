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
    print('Testing base conditions:');
    var res1 = await conn.execute("SELECT COUNT(*) FROM properties p JOIN users u ON u.id = p.user_id WHERE p.is_visible = true AND p.auto_delete_at > NOW() AND u.is_active = true AND (p.is_deleted = false OR p.is_deleted IS NULL) AND p.is_approved = true;");
    print('Base matches 1: ' + res1.first[0].toString());

    var res2 = await conn.execute("SELECT COUNT(*) FROM properties p JOIN users u ON u.id = p.user_id WHERE p.is_visible = true AND p.auto_delete_at > NOW() AND u.is_active = true AND (p.is_deleted = false OR p.is_deleted IS NULL) AND p.is_approved = true AND (u.user_type = 'Broker' OR u.trial_ends_at > NOW() OR EXISTS(SELECT 1 FROM subscriptions s WHERE s.user_id = u.id AND s.is_active = true AND s.ends_at > NOW()));");
    print('Base + Sub match: ' + res2.first[0].toString());

    print('Check specifically for Resale Residential:');
    var res3 = await conn.execute("SELECT COUNT(*) FROM properties p JOIN users u ON u.id = p.user_id WHERE p.category = 'Residential' AND p.listing_type = 'Resale';");
    print('Total Resale residential: ' + res3.first[0].toString());

    var res4 = await conn.execute("SELECT COUNT(*) FROM properties p JOIN users u ON u.id = p.user_id WHERE p.category = 'Residential' AND p.listing_type = 'Resale' AND p.is_visible = true AND (p.is_deleted = false OR p.is_deleted IS NULL);");
    print('Visible Resale residential: ' + res4.first[0].toString());

  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
