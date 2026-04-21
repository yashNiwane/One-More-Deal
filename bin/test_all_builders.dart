import 'package:flutter/widgets.dart';
import 'lib/services/database_service.dart';
import 'lib/models/property_model.dart';
// @dart=2.19
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print('Testing query mirroring app filter for Builder properties:');
    final db = DatabaseService.instance;
    
    final f1 = PropertyFilter()
      ..category = PropertyCategory.residential
      ..listingType = ListingType.resale;
      
    final r1 = await db.getProperties(filter: f1);
    print('Resale Residential: \${r1.length}');

    final f2 = PropertyFilter()
      ..userTypeFilter = UserTypeFilter.builder;
      
    final r2 = await db.getProperties(filter: f2);
    print('Builder properties: \${r2.length}');

  } catch (e) {
    print('Error: \$e');
  }
}
