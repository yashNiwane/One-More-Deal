import 'package:postgres/postgres.dart';
import 'package:one_more_deal/models/user_model.dart';
import 'package:one_more_deal/services/database_service.dart';

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

  final res = await conn.execute("SELECT id, phone, name, user_type, city, company_name, is_active, trial_days, trial_ends_at, last_login_at, created_at, current_session_token FROM users WHERE phone = '9356965876' LIMIT 1");
  
  if (res.isNotEmpty) {
    try {
      final map = res.first.toColumnMap();
      print('RAW MAP: \$map');
      final user = UserModel.fromMap(map);
      print('MODEL PARSED: \${user.name}');
    } catch (e, st) {
      print('CRASH PARSING: \$e\\n\$st');
    }
  }

  await conn.close();
}
