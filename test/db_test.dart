import 'package:flutter_test/flutter_test.dart';
import 'package:one_more_deal/services/database_service.dart';

void main() {
  test('fetch properties', () async {
    try {
      final res = await DatabaseService.instance.getProperties();
      print('Got properties: ${res.length}');
    } catch (e, st) {
      print('Error during fetch: $e');
      print(st);
      rethrow;
    }
  });
}
