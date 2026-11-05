#!/bin/sh
# Regenerates Resources/AppIcon.icns and docs/icon.png from the MoonDots shape.
set -e
cd "$(dirname "$0")/.."

DEV="$(xcode-select -p)"
SDK="${SLEEPY_SDK:-$(ls -d "$DEV"/SDKs/MacOSX26.*.sdk "$DEV"/SDKs/MacOSX26.sdk 2>/dev/null | sort -V | tail -1)}"
SDK_ARGS=""
[ -n "$SDK" ] && SDK_ARGS="-sdk $SDK"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir "$WORK/AppIcon.iconset"

swiftc -parse-as-library $SDK_ARGS Sources/SleepyCore/MoonDots.swift scripts/make-icon.swift -o "$WORK/make-icon"
"$WORK/make-icon" "$WORK/AppIcon.iconset"
iconutil -c icns "$WORK/AppIcon.iconset" -o Resources/AppIcon.icns

mkdir -p docs
cp "$WORK/AppIcon.iconset/icon_512x512@2x.png" docs/icon.png
echo "Wrote Resources/AppIcon.icns and docs/icon.png"
