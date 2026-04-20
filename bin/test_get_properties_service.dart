import '../lib/services/database_service.dart';
import '../lib/models/property_model.dart';

void main() async {
  try {
    print('Testing query mirroring app filter for Builder properties using database_service.dart directly:');
    final db = DatabaseService.instance;

    final f2 = PropertyFilter()
      ..userTypeFilter = UserTypeFilter.builder;
      
    final r2 = await db.getProperties(filter: f2);
    print('Builder properties count: ' + r2.length.toString());

  } catch (e) {
    print('Error: ' + e.toString());
  }
}
