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
    var res = await conn.execute('''
      SELECT p.*,
             COALESCE(NULLIF(TRIM(u.company_name), ''), u.name) AS poster_name,
             u.user_code AS poster_code,
             u.company_name AS poster_company,
             u.phone AS poster_phone
      FROM properties p
      JOIN users u ON u.id = p.user_id
      WHERE (u.user_type = 'Builder' OR u.user_type = 'Developer')
        AND p.is_visible = true
    ''');
    
    print('Found builder properties: ' + res.length.toString());
    for (var r in res) {
      try {
        var map = r.toColumnMap();
        var model = PropertyModel.fromMap(map);
        print('Parsed builder property ID ' + model.id.toString() + ' successfully.');
      } catch (e) {
        print('Error parsing model: ' + e.toString());
        break;
      }
    }
  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
