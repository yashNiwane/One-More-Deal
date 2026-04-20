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
    var res = await conn.execute("SELECT table_name, column_name, udt_name FROM information_schema.columns WHERE data_type = 'USER-DEFINED';");
    for (var r in res) print(r[0].toString() + ' | ' + r[1].toString() + ' | ' + r[2].toString());
  } catch (e) {
    print('Error: ' + e.toString());
  }

  await conn.close();
}
