import 'package:postgres/postgres.dart';
import '../lib/models/property_model.dart';
import 'dart:convert';

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
    print('Testing query mirroring app filter for Resale Residential:');
    final conditions = <String>[
      'p.is_visible = true',
      'p.auto_delete_at > NOW()',
      'u.is_active = true',
      "(u.user_type = 'Broker' OR u.trial_ends_at > NOW() OR EXISTS(SELECT 1 FROM subscriptions s WHERE s.user_id = u.id AND s.is_active = true AND s.ends_at > NOW()))",
      '(p.is_deleted = false OR p.is_deleted IS NULL)',
      '(p.is_approved = true)',
    ];
    final params = <String, dynamic>{};

    conditions.add("p.category = @category");
    params['category'] = 'Residential';

    conditions.add("p.listing_type = @listingType");
    params['listingType'] = 'Resale';

    final where = conditions.join(' AND ');

    final res = await conn.execute(
      Sql.named('''
        SELECT p.*,
               COALESCE(NULLIF(TRIM(u.company_name), ''), u.name) AS poster_name,
               u.user_code AS poster_code,
               u.company_name AS poster_company,
               u.phone AS poster_phone
        FROM properties p
        JOIN users u ON u.id = p.user_id
        WHERE \$where
      '''.replaceAll('\$where', where)),
      parameters: params,
    );
    
    print('Raw db matches parameterized: ' + res.length.toString());
    
    // Now map them to PropertyModel
    int parsed = 0;
    for (var r in res) {
      try {
        var map = r.toColumnMap();
        var model = PropertyModel.fromMap(map);
        parsed++;
      } catch (e) {
        print('Error parsing model: ' + e.toString());
        break; // print only first error
      }
    }
    print('Parsed successfully: ' + parsed.toString());
    
  } catch (e) {
    print('Query failed with: ' + e.toString());
  }

  await conn.close();
}
