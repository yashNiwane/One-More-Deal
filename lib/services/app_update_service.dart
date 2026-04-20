import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  AppUpdateService._();

  static bool _isChecking = false;

  static Future<void> checkAndRunImmediateUpdate() async {
    if (_isChecking) return;
    if (kIsWeb || !Platform.isAndroid) return;

    _isChecking = true;
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      final canImmediateUpdate =
          updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
          updateInfo.immediateUpdateAllowed;

      if (!canImmediateUpdate) return;

      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint('[UPDATE] Immediate update check skipped: $e');
    } finally {
      _isChecking = false;
    }
  }
}
