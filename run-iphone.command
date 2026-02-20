#!/bin/bash
echo "=============================="
echo "  SecureAuth - iPhone Runner  "
echo "=============================="
echo ""
echo "Hedef: Kaan Dikec's iPhone (iOS 26.1)"
echo "Device: 00008120-000E19AC3603C01E"
echo ""
echo "1) Debug"
echo "2) Release"
echo ""
read -p "Mod secin (1/2): " choice

if [ "$choice" = "2" ]; then
  MODE="--release"
  echo ">> Release build baslatiliyor..."
else
  MODE="--debug"
  echo ">> Debug build baslatiliyor..."
fi

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="/tmp/secure-auth-build"

echo ""
echo ">> Proje kopyalaniyor..."
rm -rf "$DEST"
rsync -a --quiet \
  --exclude='build/' \
  --exclude='.dart_tool/' \
  --exclude='.flutter-plugins-dependencies*' \
  --exclude='android/build/' \
  --exclude='android/.gradle/' \
  --exclude='ios/build/' \
  --exclude='ios/Pods/' \
  --exclude='macos/build/' \
  --exclude='macos/Pods/' \
  --exclude='.idea/' \
  --exclude='*.iml' \
  "$SRC/" "$DEST"

echo ">> Bagimliliklar yukleniyor..."
cd "$DEST"
flutter pub get --quiet 2>/dev/null

echo ">> iPhone'a yukleniyor..."
flutter run \
  --device-id 00008120-000E19AC3603C01E \
  $MODE
