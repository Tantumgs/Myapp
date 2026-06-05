@echo off
cd /d "%~dp0"
echo Installing dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo Error: flutter pub get failed
    pause
    exit /b 1
)
echo Building APK...
flutter build apk --release
if %errorlevel% neq 0 (
    echo Error: build failed
    pause
    exit /b 1
)
echo Build successful! APK location:
dir "%~dp0build\app\outputs\flutter-apk\app-release.apk"
pause