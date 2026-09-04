@echo off
setlocal
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter SDK was not found. Install Flutter and add it to PATH first.
  pause
  exit /b 1
)
flutter config --enable-windows-desktop
if not exist windows flutter create --platforms=windows .
flutter pub get
flutter run -d windows
endlocal
