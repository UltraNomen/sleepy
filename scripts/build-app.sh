#!/bin/sh
# Builds Sleepy.app into ./build without Xcode.
#
#   scripts/build-app.sh            release build
#   scripts/build-app.sh debug      debug build
#
# With only the Command Line Tools, the newest SDK's SwiftUI needs macro plugins
# that ship with Xcode, so the build uses a macOS 26 SDK. Set SLEEPY_SDK to override.
set -e
cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
DEV="$(xcode-select -p)"

if [ -z "$SLEEPY_SDK" ] && echo "$DEV" | grep -q CommandLineTools; then
  SLEEPY_SDK="$(ls -d "$DEV"/SDKs/MacOSX26.*.sdk "$DEV"/SDKs/MacOSX26.sdk 2>/dev/null | sort -V | tail -1)"
fi
SDK_ARGS=""
[ -n "$SLEEPY_SDK" ] && SDK_ARGS="--sdk $SLEEPY_SDK" && echo "Using SDK: $SLEEPY_SDK"

swift build -c "$CONFIG" $SDK_ARGS
BIN="$(swift build -c "$CONFIG" $SDK_ARGS --show-bin-path)/Sleepy"

APP="build/Sleepy.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Sleepy"
cp Resources/Info.plist "$APP/Contents/Info.plist"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"

codesign --force --sign - --timestamp=none "$APP"
echo "Built $APP"
