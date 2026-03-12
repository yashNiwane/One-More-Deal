import 'package:postgres/postgres.dart';
void main() async {
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
  
  final res = await conn.execute("SELECT column_name, column_default, data_type FROM information_schema.columns WHERE table_name = 'users';");
  for(final row in res) {
    print(row[0].toString() + " | " + (row[1] ?? 'NULL').toString() + " | " + row[2].toString());
  }

  print('\n-- TRIGGERS --');
  final trig = await conn.execute("SELECT trigger_name, action_statement FROM information_schema.triggers WHERE event_object_table = 'users';");
  for(final row in trig) {
    print(row[0].toString() + ' -> ' + row[1].toString());
  }

  await conn.close();
}
