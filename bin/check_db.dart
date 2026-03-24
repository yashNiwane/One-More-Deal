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

  Future<void> printColumns(String table) async {
    final res = await conn.execute(
      Sql.named('''
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = @t
        ORDER BY ordinal_position
      '''),
      parameters: {'t': table},
    );

    print('\n=== Columns: $table ===');
    for (final row in res) {
      final m = row.toColumnMap();
      print('${m['column_name']} (${m['data_type']})');
    }
  }

  await printColumns('properties');

  // Search for fields that might correspond to "FOS / CP Slab / %"
  final patterns = <String>['%fos%', '%cp%', '%slab%', '%commission%', '%broker%', '%percent%'];
  for (final pat in patterns) {
    final res = await conn.execute(
      Sql.named('''
        SELECT table_name, column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = 'public' AND column_name ILIKE @p
        ORDER BY table_name, column_name
      '''),
      parameters: {'p': pat},
    );
    if (res.isEmpty) continue;

    print('\n=== Matches for $pat ===');
    for (final row in res) {
      final m = row.toColumnMap();
      print('${m['table_name']}.${m['column_name']} (${m['data_type']})');
    }
  }

  final latestBuilder = await conn.execute('''
    SELECT id, society_name, rera_no, possession_date, area_value, area_unit,
           total_buildings, total_units, amenities_count, building_structure,
           variants
    FROM properties
    WHERE category = 'New'
    ORDER BY id DESC
    LIMIT 1
  ''');

  print('\n=== Latest builder project (properties.category=New) ===');
  if (latestBuilder.isEmpty) {
    print('No builder projects found.');
  } else {
    final row = latestBuilder.first.toColumnMap();
    for (final e in row.entries) {
      print('${e.key}: ${e.value}');
    }
  }

  await conn.close();
}
