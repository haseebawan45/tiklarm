@echo off
echo Rebuilding Tiklarm...
echo.

echo Cleaning previous build...
call flutter clean

echo.
echo Getting dependencies...
call flutter pub get

echo.
echo Building Android APK...
call flutter build apk --release

echo.
echo Building Web...
call flutter build web --release

echo.
echo Build complete!
echo APK: build\app\outputs\flutter-apk\app-release.apk
echo Web: build\web\
echo.
pause 