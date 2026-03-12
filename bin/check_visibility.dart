import 'package:postgres/postgres.dart';
import 'dart:io';

void main() async {
  final file = File('check_out.txt');
  var out = '';
  final conn = await Connection.open(
    Endpoint(
      host:     'one-more-deal.cnkisqqwmvy2.ap-south-1.rds.amazonaws.com',
      port:     5432,
      database: 'OneMoreDeal',
      username: 'postgres',
      password: 'MmKnDMm#14',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );

  final userRes = await conn.execute("SELECT id, is_active FROM users WHERE phone = '9158120359'");
  if (userRes.isEmpty) {
    out += 'User 9158120359 not found\n';
  } else {
    out += 'User ID: ' + userRes.first[0].toString() + ' | is_active: ' + userRes.first[1].toString() + '\n';
  }

  final propRes = await conn.execute("SELECT id, is_visible, is_deleted, auto_delete_at, NOW() as current_time FROM properties WHERE user_id = 9");
  for (final row in propRes) {
    out += 'Property ID: ' + row[0].toString() + ' | is_visible: ' + row[1].toString() + ' | is_deleted: ' + row[2].toString() + ' | auto_delete_at: ' + row[3].toString() + ' | current_time: ' + row[4].toString() + '\n';
  }

  await conn.close();
  await file.writeAsString(out);
}
