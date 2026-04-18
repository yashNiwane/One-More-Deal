import 'dart:io';

void main() {
  final file = File('lib/services/database_service.dart');
  final lines = file.readAsLinesSync();
  
  // Replace line 68 to 127
  // Index = lineNum - 1
  final startIdx = 67;
  final endIdx = 126; // '    return UserModel.fromMap(res.first.toColumnMap());\n  }'
  
  final replacement = '''
  /// First-time signup OR re-login: upserts the row and returns the full user.
  Future<UserModel?> upsertUser({required String phone, required String sessionToken, String? email}) async {
    final res = await (await _db).execute(
      Sql.named(\'\'\'
        INSERT INTO users (phone, email, last_login_at, current_session_token)
        VALUES (@phone, @email, NOW(), @token)
        ON CONFLICT (phone) DO UPDATE
          SET email         = COALESCE(users.email, @email),
              last_login_at = NOW(),
              current_session_token = @token,
              updated_at    = NOW()
        RETURNING id, phone, email, name, user_type, city, company_name,
                  is_active, trial_days, trial_ends_at, last_login_at, created_at, current_session_token, user_code, rera_no, area, office_address
      \'\'\'),
      parameters: {'phone': phone, 'email': email, 'token': sessionToken},
    );
    if (res.isEmpty) return null;
    return UserModel.fromMap(res.first.toColumnMap());
  }

  /// Updates profile after the profile-setup screen.
  Future<void> updateUserProfile({
    required String phone,
    required String name,
    required String userType,
    required String city,
    required String companyName, String? reraNo, String? area, String? officeAddress,
  }) async {
    await (await _db).execute(
      Sql.named(\'\'\'
        UPDATE users
        SET name            = @name,
            user_type       = @userType,
            city            = @city,
            company_name    = @companyName,
            updated_at      = NOW(), rera_no = @reraNo, area = @area, office_address = @officeAddress
        WHERE phone = @phone
      \'\'\'),
      parameters: {
        'phone': phone,
        'name': name,
        'userType': userType,
        'city': city,
        'companyName': companyName, 'reraNo': reraNo, 'area': area, 'officeAddress': officeAddress,
      },
    );
  }

  /// Retrieves a user row by phone number.
  Future<UserModel?> getUserByPhone(String phone) async {
    final res = await (await _db).execute(
      Sql.named(\'\'\'
        SELECT id, phone, email, name, user_type, city, company_name,
               is_active, trial_days, trial_ends_at, last_login_at, created_at, current_session_token, user_code, rera_no, area, office_address
        FROM users WHERE phone = @phone LIMIT 1
      \'\'\'),
      parameters: {'phone': phone},
    );
    if (res.isEmpty) return null;
    return UserModel.fromMap(res.first.toColumnMap());
  }

  /// Retrieves a user row by email.
  Future<UserModel?> getUserByEmail(String email) async {
    final res = await (await _db).execute(
      Sql.named(\'\'\'
        SELECT id, phone, email, name, user_type, city, company_name,
               is_active, trial_days, trial_ends_at, last_login_at, created_at, current_session_token, user_code, rera_no, area, office_address
        FROM users WHERE email = @email LIMIT 1
      \'\'\'),
      parameters: {'email': email},
    );
    if (res.isEmpty) return null;
    return UserModel.fromMap(res.first.toColumnMap());
  }''';

  lines.replaceRange(startIdx, endIdx + 1, [replacement]);
  file.writeAsStringSync(lines.join('\n'));
  print('Done.');
}
