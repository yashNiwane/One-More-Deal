import 'package:flutter/widgets.dart';
import 'lib/services/database_service.dart';
import 'lib/models/property_model.dart';
// @dart=2.19
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print('Testing exact app filter calls:');
    final db = DatabaseService.instance;
    
    final f1 = PropertyFilter(city: 'Pune')
      ..category = PropertyCategory.residential
      ..listingType = ListingType.resale;
    
    final r1 = await db.getProperties(filter: f1);
    print('Pune + Resale Residential: \${r1.length}');

    final f2 = PropertyFilter(city: 'Pune')
      ..userTypeFilter = UserTypeFilter.builder;
    
    final r2 = await db.getProperties(filter: f2);
    print('Pune + Builder: \${r2.length}');

  } catch (e) {
    print('Error: \$e');
  }
}
