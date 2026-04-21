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
    var res = await conn.execute('''
      SELECT u.id, u.name, u.phone, u.company_name, u.user_type, u.is_active, u.trial_ends_at
      FROM users u
      WHERE LOWER(u.name) LIKE LOWER('%padma%')
         OR LOWER(u.company_name) LIKE LOWER('%padma%')
    ''');
    
    print('Users matching padma:');
    for (var r in res) {
      print('ID: ' + r[0].toString() + ' | name: ' + r[1].toString() + ' | phone: ' + r[2].toString() + ' | company: ' + r[3].toString() + ' | type: ' + r[4].toString() + ' | active: ' + r[5].toString() + ' | trial: ' + r[6].toString());
    }

    if (res.isEmpty) {
      print('No user found with padma in name/company');
    }

    // Also get their properties
    if (res.isNotEmpty) {
      final userId = res.first[0];
      var propRes = await conn.execute('''
        SELECT id, society_name, city, area, is_visible, is_approved, is_deleted, auto_delete_at
        FROM properties
        WHERE user_id = \${userId}
      '''.replaceAll('\${userId}', userId.toString()));
      
      print('\nProperties of this user:');
      for (var r in propRes) {
        print('PropID: ' + r[0].toString() + ' | society: ' + r[1].toString() + ' | city: ' + r[2].toString() + ' | vis: ' + r[4].toString() + ' | approved: ' + r[5].toString() + ' | deleted: ' + r[6].toString() + ' | expiry: ' + r[7].toString());
      }
    }

  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
