import 'dart:io';

void main() {
  final file = File('lib/services/auth_service.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll(
    '''  static Future<void> loginUser(String phone) async {
    final token =
        '\${DateTime.now().millisecondsSinceEpoch}_\${DateTime.now().microsecond}';

    try {
      final user = await DatabaseService.instance.upsertUser(phone, token);
      if (user != null) {
        _currentUser = user;
        // Cache profile status locally
        if (user.name?.trim().isNotEmpty == true) {
          await _p.setBool(_keyProfileComplete, true);
        }

        await _p.setBool(_keyIsLoggedIn, true);
        await _p.setString(_keyUserPhone, phone);
        await _p.setString(_keySessionToken, token);
        debugPrint('[AUTH] loginUser OK — userId=\${user.id}, phone=\$phone, isActive=\${user.isActive}');
      } else {
        throw Exception('Failed to upsert user record in database');
      }
    } catch (e, st) {
      debugPrint('[AUTH] loginUser DB ERROR: \$e\\n\$st');
      rethrow;
    }
  }''',
    '''  static Future<bool> loginWithGoogle(String email) async {
    final token = '\${DateTime.now().millisecondsSinceEpoch}_\${DateTime.now().microsecond}';
    try {
      final user = await DatabaseService.instance.getUserByEmail(email);
      if (user != null) {
        final updatedUser = await DatabaseService.instance.upsertUser(phone: user.phone, sessionToken: token, email: email);
        if (updatedUser != null) {
          _currentUser = updatedUser;
          if (updatedUser.name?.trim().isNotEmpty == true) {
            await _p.setBool(_keyProfileComplete, true);
          }
          await _p.setBool(_keyIsLoggedIn, true);
          await _p.setString(_keyUserPhone, updatedUser.phone);
          await _p.setString(_keySessionToken, token);
          debugPrint('[AUTH] loginWithGoogle OK - logged in existing user: \$email');
          return true;
        }
      }
      return false; // Not registered yet
    } catch (e, st) {
      debugPrint('[AUTH] loginWithGoogle error: \$e\\n\$st');
      return false;
    }
  }

  static Future<void> loginUser(String phone, {String? googleEmail}) async {
    final token = '\${DateTime.now().millisecondsSinceEpoch}_\${DateTime.now().microsecond}';

    try {
      if (googleEmail != null) {
        final existingUser = await DatabaseService.instance.getUserByPhone(phone);
        if (existingUser != null && existingUser.email != null && existingUser.email != googleEmail) {
          throw Exception('This mobile number is linked to another Google account. Please use a different number or sign in with the correct Google account.');
        }
      }

      final user = await DatabaseService.instance.upsertUser(phone: phone, sessionToken: token, email: googleEmail);
      if (user != null) {
        _currentUser = user;
        // Cache profile status locally
        if (user.name?.trim().isNotEmpty == true) {
          await _p.setBool(_keyProfileComplete, true);
        }

        await _p.setBool(_keyIsLoggedIn, true);
        await _p.setString(_keyUserPhone, phone);
        await _p.setString(_keySessionToken, token);
        debugPrint('[AUTH] loginUser OK — userId=\${user.id}, phone=\$phone, isActive=\${user.isActive}');
      } else {
        throw Exception('Failed to upsert user record in database');
      }
    } catch (e, st) {
      debugPrint('[AUTH] loginUser DB ERROR: \$e\\n\$st');
      rethrow;
    }
  }'''
  );

  file.writeAsStringSync(content);
  print('Done applying replacements to auth_service.dart');
}
