@echo off
echo ========================================
echo Setting up One More Deal App Logo
echo ========================================
echo.

echo Step 1: Getting Flutter dependencies...
call flutter pub get
echo.

echo Step 2: Generating app icons from logo.png...
call dart run flutter_launcher_icons
echo.

echo Step 3: Cleaning build cache...
call flutter clean
echo.

echo Step 4: Getting dependencies again...
call flutter pub get
echo.

echo ========================================
echo Logo setup complete!
echo ========================================
echo.
echo Next steps:
echo 1. Uninstall the old app from your device/emulator
echo 2. Run: flutter run
echo.
pause
