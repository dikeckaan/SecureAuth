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
# Auto-detect the first connected physical iOS device (version-independent)
DEVICE_ID=$(flutter devices 2>/dev/null \
  | grep " ios " | grep -iv "simulator" \
  | awk -F'•' '{gsub(/ /,"",$2); print $2}' \
  | head -1)

if [ -n "$DEVICE_ID" ]; then
  echo "Cihaz: $DEVICE_ID"
  flutter run --device-id "$DEVICE_ID" $MODE
else
  echo "Fiziksel iOS cihaz bulunamadi, Flutter'in secmesine birakildi..."
  flutter run -d ios $MODE
fi
