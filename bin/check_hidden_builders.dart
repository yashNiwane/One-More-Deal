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
      SELECT p.id, p.is_visible, p.is_approved, p.is_deleted, p.auto_delete_at, u.is_active, u.name, u.phone
      FROM properties p
      JOIN users u ON u.id = p.user_id
      WHERE (u.user_type = 'Builder' OR u.user_type = 'Developer')
    ''');
    
    print('Breakdown of the 9 Builder Properties:');
    print('ID | vis | app | del | auto_del | user_act | user_name');
    for (var r in res2) {
      print(r[0].toString() + ' | ' + r[1].toString() + ' | ' + r[2].toString() + ' | ' + r[3].toString() + ' | ' + r[4].toString() + ' | ' + r[5].toString() + ' | ' + r[6].toString());
    }

  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
