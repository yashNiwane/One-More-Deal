import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/otp_service.dart';
import 'widgets/connectivity_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Load secrets
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('[ENV] Loaded — DB_HOST=${dotenv.env['DB_HOST']}');
  } catch (e) {
    debugPrint('[ENV] Failed to load .env: $e');
  }

  // Initialize OTP SDK
  OTPService.initialize();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D1B4B),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const OneMoreDealApp());
}

class OneMoreDealApp extends StatelessWidget {
  const OneMoreDealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One More Deal™',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return ConnectivityWrapper(child: child!);
      },
      home: const SplashScreen(),
    );
  }
}
