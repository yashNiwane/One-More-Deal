import 'package:postgres/postgres.dart';

void main() async {
  final c = await Connection.open(
    Endpoint(host:'one-more-deal.cnkisqqwmvy2.ap-south-1.rds.amazonaws.com',port:5432,database:'OneMoreDeal',username:'postgres',password:'MmKnDMm#14'),
    settings:const ConnectionSettings(sslMode:SslMode.require),
  );
  final r = await c.execute('SELECT id, phone, name, user_type, company_name FROM users ORDER BY id DESC LIMIT 10');
  for(final row in r) print(row);
  await c.close();
}
