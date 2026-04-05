import 'lib/services/database_service.dart';

void main() async {
  final db = await DatabaseService.instance.db;
  final res = await db.execute('SELECT id, user_id, society_name, is_approved, is_deleted, is_visible FROM properties ORDER BY id DESC LIMIT 5;');
  for (final row in res) {
    print(row);
  }
}
