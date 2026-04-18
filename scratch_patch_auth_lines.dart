import 'dart:io';

void main() {
  final file = File('lib/services/auth_service.dart');
  final lines = file.readAsLinesSync();
  
  // Replace line 45 to 69 with the new loginWithGoogle and loginUser methods.
  // Note: List is 0-indexed. Line 46 in IDE is index 45.
  final startIdx = 45;
  final endIdx = 69; // Line 70 is '  }' which we replace.
  
  final replacement = '''
  static Future<bool> loginWithGoogle(String email) async {
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
  }''';

  lines.replaceRange(startIdx, endIdx + 1, [replacement]);
  file.writeAsStringSync(lines.join('\n'));
  print('Done.');
}
