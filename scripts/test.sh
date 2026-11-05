#!/bin/sh
# Runs the unit tests without Xcode. SwiftPM doesn't find the Swift Testing macro
# plugin under the Command Line Tools on its own, and the app target needs a
# macOS 26 SDK there (see build-app.sh), so both are passed explicitly.
set -e
cd "$(dirname "$0")/.."
DEV="$(xcode-select -p)"
if ! echo "$DEV" | grep -q CommandLineTools; then
  exec swift test "$@"
fi
SDK="${SLEEPY_SDK:-$(ls -d "$DEV"/SDKs/MacOSX26.*.sdk "$DEV"/SDKs/MacOSX26.sdk 2>/dev/null | sort -V | tail -1)}"
FRAMEWORKS="$DEV/Library/Developer/Frameworks"
exec swift test --sdk "$SDK" \
  -Xswiftc -plugin-path -Xswiftc "$DEV/usr/lib/swift/host/plugins/testing" \
  -Xswiftc -F -Xswiftc "$FRAMEWORKS" -Xlinker -rpath -Xlinker "$FRAMEWORKS" "$@"
