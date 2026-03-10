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

  print('Creating dummy user...');
  final userRes = await conn.execute('''
    INSERT INTO users (phone, name, user_type, city, is_active, trial_ends_at)
    VALUES ('0000000000', 'Test User', 'Broker', 'Pune', true, NOW() + INTERVAL '30 days')
    ON CONFLICT (phone) DO UPDATE SET name = 'Test User', is_active = true
    RETURNING id
  ''');
  
  final userId = userRes.first[0] as int;
  print('Dummy user ID: $userId');

  print('Clearing old dummy properties...');
  await conn.execute(Sql.named('DELETE FROM properties WHERE user_id = @userId'), parameters: {'userId': userId});

  print('Inserting sample properties...');
  
  // 1. Residential Resale
  await conn.execute(Sql.named('''
    INSERT INTO properties (
      user_id, category, listing_type, city, area, society_name,
      flat_type, area_value, area_unit, floor_number, floor_category,
      price, availability, parking, posted_at, refreshed_at, auto_delete_at
    ) VALUES (
      @uid, 'Residential'::property_category, 'Resale'::listing_type, 'Pune', 'Kharadi', 'Ganga Constella',
      '2 BHK', 1050, 'SqFt', 4, 'Mid'::floor_category,
      8500000, 'Immediate', true, NOW(), NOW(), NOW() + INTERVAL '60 days'
    )
  '''), parameters: {'uid': userId});

  // 2. Residential Rent
  await conn.execute(Sql.named('''
    INSERT INTO properties (
      user_id, category, listing_type, city, area, society_name,
      flat_type, area_value, area_unit, floor_number, floor_category,
      price, availability, parking, posted_at, refreshed_at, auto_delete_at
    ) VALUES (
      @uid, 'Residential'::property_category, 'Rent'::listing_type, 'Pune', 'Viman Nagar', 'Rohan Mithila',
      '3 BHK', 1500, 'SqFt', 2, 'Low'::floor_category,
      45000, '15 Days', true, NOW(), NOW(), NOW() + INTERVAL '30 days'
    )
  '''), parameters: {'uid': userId});

  // 3. Commercial Rent (Shop)
  await conn.execute(Sql.named('''
    INSERT INTO properties (
      user_id, category, listing_type, city, area, society_name,
      flat_type, area_value, area_unit, floor_number, floor_category,
      price, availability, parking, posted_at, refreshed_at, auto_delete_at
    ) VALUES (
      @uid, 'Commercial'::property_category, 'Rent'::listing_type, 'Pune', 'Baner', 'Pancard Club',
      'Shop 12', 400, 'SqFt', 1, 'Low'::floor_category,
      25000, 'Immediate', false, NOW(), NOW(), NOW() + INTERVAL '30 days'
    )
  '''), parameters: {'uid': userId});

  // 4. Commercial Resale (Office)
  await conn.execute(Sql.named('''
    INSERT INTO properties (
      user_id, category, listing_type, city, area, society_name,
      flat_type, area_value, area_unit, floor_number, floor_category,
      price, availability, parking, posted_at, refreshed_at, auto_delete_at
    ) VALUES (
      @uid, 'Commercial'::property_category, 'Resale'::listing_type, 'Pune', 'Kothrud', 'Karishma Society',
      'Office 4B', 800, 'SqFt', 3, 'Mid'::floor_category,
      12000000, 'Immediate', true, NOW(), NOW(), NOW() + INTERVAL '60 days'
    )
  '''), parameters: {'uid': userId});

  // 5. New Property (Builder)
  await conn.execute(Sql.named('''
    INSERT INTO properties (
      user_id, category, listing_type, city, area, society_name,
      flat_type, area_value, area_unit,
      price, possession_date, parking, posted_at, refreshed_at, auto_delete_at
    ) VALUES (
      @uid, 'New'::property_category, 'New'::listing_type, 'Pune', 'Wakad', 'Kalpataru Harmony',
      '2.5 BHK', 1200, 'SqFt',
      9500000, NOW() + INTERVAL '180 days', true, NOW(), NOW(), NOW() + INTERVAL '60 days'
    )
  '''), parameters: {'uid': userId});

  print('Dummy properties inserted successfully!');
  await conn.close();
}
