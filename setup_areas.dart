import 'package:postgres/postgres.dart';

void main() async {
  print('Connecting to DB...');
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

  print('Creating table...');
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS city_areas (
      id SERIAL PRIMARY KEY,
      city VARCHAR(100) NOT NULL,
      area VARCHAR(100) NOT NULL,
      UNIQUE(city, area)
    );
  ''');

  print('Inserting data...');
  await conn.execute('''
    INSERT INTO city_areas (city, area) VALUES
    ('Pune', 'Kharadi'), ('Pune', 'Viman Nagar'), ('Pune', 'Wagholi'),
    ('Pune', 'Kalyani Nagar'), ('Pune', 'Koregaon Park'), ('Pune', 'Magarpatta'),
    ('Pune', 'Hadapsar'), ('Pune', 'Hinjewadi'), ('Pune', 'Wakad'),
    ('Pune', 'Baner'), ('Pune', 'Balewadi'), ('Pune', 'Aundh'),
    ('Pune', 'Kothrud'), ('Pune', 'Bavdhan'), ('Pune', 'Shivaji Nagar'),
    ('Pune', 'Camp'), ('Pune', 'Vishrantwadi'), ('Pune', 'Pimple Saudagar'),
    ('Pune', 'Pimpri'), ('Pune', 'Chinchwad'), ('Pune', 'Ravet'),
    ('Pune', 'Dhankawadi'), ('Pune', 'Katraj'), ('Pune', 'Kondhwa'),
    ('Pune', 'Wanowrie'), ('Pune', 'Fatima Nagar'), ('Pune', 'Yerwada'),
    ('Pune', 'Deccan Gymkhana'), ('Pune', 'Erandwane'), ('Pune', 'Nigdi'),
    ('Pune', 'Bhosari')
    ON CONFLICT DO NOTHING;
  ''');

  print('Areas setup complete.');
  await conn.close();
}
