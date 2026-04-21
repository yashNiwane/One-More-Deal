import 'dart:io';

void main() {
  final file = File('lib/services/database_service.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll(
    '''  Future<UserModel?> upsertUser(String phone, String sessionToken) async {
    final res = await (await _db).execute(
      Sql.named(\'\'\'
        INSERT INTO users (phone, last_login_at, current_session_token)
        VALUES (@phone, NOW(), @token)
        ON CONFLICT (phone) DO UPDATE
          SET last_login_at = NOW(),
              current_session_token = @token,
              updated_at    = NOW()
        RETURNING id, phone, name, user_type, city, company_name,
                  is_active, trial_days, trial_ends_at, last_login_at, created_at, current_session_token, user_code, rera_no, area, office_address
      \'\'\'),
      parameters: {'phone': phone, 'token': sessionToken},
    );
    if (res.isEmpty) return null;
    return UserModel.fromMap(res.first.toColumnMap());
  }''',
    '''  Future<UserModel?> upsertUser({required String phone, required String sessionToken, String? email}) async {
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
  }'''
  );

  content = content.replaceAll(
    '''  Future<UserModel?> getUserByPhone(String phone) async {
    final res = await (await _db).execute(
      Sql.named(\'\'\'
        SELECT id, phone, name, user_type, city, company_name,
               is_active, trial_days, trial_ends_at, last_login_at, created_at, current_session_token, user_code, rera_no, area, office_address
        FROM users WHERE phone = @phone LIMIT 1
      \'\'\'),
      parameters: {'phone': phone},
    );
    if (res.isEmpty) return null;
    return UserModel.fromMap(res.first.toColumnMap());
  }''',
    '''  Future<UserModel?> getUserByPhone(String phone) async {
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
  }'''
  );

  file.writeAsStringSync(content);
  print('Done applying replacements to database_service.dart');
}
