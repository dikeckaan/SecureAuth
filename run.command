#!/bin/bash
echo "SecureAuth Build"
echo "----------------"
echo "1) Debug"
echo "2) Release"
echo ""
read -p "Mod secin (1/2): " choice

if [ "$choice" = "2" ]; then
  MODE="--release"
  echo "Release build baslatiliyor..."
else
  MODE="--debug"
  echo "Debug build baslatiliyor..."
fi

rm -rf /tmp/secure-auth-build
git clone "$(dirname "$0")" /tmp/secure-auth-build --quiet
cd /tmp/secure-auth-build
flutter pub get --quiet 2>/dev/null
flutter run --device-id 00008120-000E19AC3603C01E $MODE
