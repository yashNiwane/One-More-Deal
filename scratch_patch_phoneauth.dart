import 'dart:io';

void main() {
  final file = File('lib/screens/auth/phone_auth_screen.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll(
    '''      if (user != null) {
        setState(() {
          _googleSignedIn = true;
          _googleUser = user;
        });
        _phoneFocus.requestFocus();
      } else {''',
    '''      if (user != null) {
        if (user.email != null) {
          final isExistingUser = await AuthService.loginWithGoogle(user.email!);
          if (isExistingUser) {
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => const SplashScreen(),
                transitionDuration: const Duration(milliseconds: 400),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
              (route) => false,
            );
            return;
          }
        }
        
        setState(() {
          _googleSignedIn = true;
          _googleUser = user;
        });
        _phoneFocus.requestFocus();
      } else {'''
  );

  content = content.replaceAll(
    '''      // AuthService.loginUser uses upsertUser internally:
      // - New user  → INSERT row into PostgreSQL users table
      // - Old user  → UPDATE last_login_at in PostgreSQL users table
      // Either way the user ends up logged in with full session
      await AuthService.loginUser(phone);''',
    '''      // AuthService.loginUser links the Google email if provided.
      await AuthService.loginUser(phone, googleEmail: _googleUser?.email);'''
  );

  file.writeAsStringSync(content);
  print('Done applying replacements to phone_auth_screen.dart');
}
