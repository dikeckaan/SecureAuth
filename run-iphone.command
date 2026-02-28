#!/bin/bash
echo "=============================="
echo "  SecureAuth - iPhone Runner  "
echo "=============================="
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

# Auto-detect the first connected physical iOS device (version-independent)
DEVICE_ID=$(flutter devices 2>/dev/null \
  | grep " ios " | grep -iv "simulator" \
  | awk -F'•' '{gsub(/ /,"",$2); print $2}' \
  | head -1)

if [ -n "$DEVICE_ID" ]; then
  echo ">> Cihaz: $DEVICE_ID"
  flutter run --device-id "$DEVICE_ID" $MODE
else
  echo ">> Fiziksel iOS cihaz bulunamadi, Flutter'in secmesine birakildi..."
  flutter run -d ios $MODE
fi
