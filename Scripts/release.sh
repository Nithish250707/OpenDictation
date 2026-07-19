#!/bin/bash
# Builds a distributable DMG of Open Dictation.
#
# Usage:
#   Scripts/release.sh <version>
#
# Optional environment:
#   CODESIGN_IDENTITY  "Developer ID Application: Name (TEAMID)" — enables real
#                      signing with hardened runtime. Without it the app is
#                      ad-hoc signed (fine for local testing, not distribution).
#   NOTARY_PROFILE     notarytool keychain profile name — enables notarization
#                      and stapling. Requires CODESIGN_IDENTITY.
#
# Output: dist/OpenDictation-<version>.dmg
# If Sparkle's sign_update tool is present in the build products, the EdDSA
# signature line for the appcast is printed at the end.

set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?usage: Scripts/release.sh <version>}"
DERIVED="build-release"
DIST="dist"
APP="$DERIVED/Build/Products/Release/OpenDictation.app"
DMG="$DIST/OpenDictation-$VERSION.dmg"

echo "==> Building Release"
xcodebuild -project OpenDictation.xcodeproj -scheme OpenDictation \
    -configuration Release -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED" build | grep -E ': (warning|error):|BUILD (SUCCEEDED|FAILED)' || true
test -d "$APP"

if [ -n "${CODESIGN_IDENTITY:-}" ]; then
    echo "==> Signing with Developer ID (hardened runtime)"
    sign() { codesign --force --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$@"; }
    SPARKLE="$APP/Contents/Frameworks/Sparkle.framework"
    if [ -d "$SPARKLE" ]; then
        # Sparkle's nested executables must be signed individually:
        # https://sparkle-project.org/documentation/sandboxing/#code-signing
        sign "$SPARKLE/Versions/B/XPCServices/Installer.xpc"
        sign --preserve-metadata=entitlements "$SPARKLE/Versions/B/XPCServices/Downloader.xpc"
        sign "$SPARKLE/Versions/B/Autoupdate"
        sign "$SPARKLE/Versions/B/Updater.app"
        sign "$SPARKLE"
    fi
    sign --entitlements OpenDictation/OpenDictation.entitlements "$APP"
else
    echo "==> No CODESIGN_IDENTITY set — ad-hoc signing (not for distribution)"
    codesign --force --deep --sign - "$APP"
fi

echo "==> Verifying signature"
codesign --verify --deep --strict "$APP"

echo "==> Creating DMG"
mkdir -p "$DIST"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "Open Dictation" -srcfolder "$STAGING" -ov -quiet -format UDZO "$DMG"
hdiutil verify -quiet "$DMG"

if [ -n "${NOTARY_PROFILE:-}" ]; then
    echo "==> Notarizing (this can take a few minutes)"
    xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG"
elif [ -n "${CODESIGN_IDENTITY:-}" ]; then
    echo "==> Skipping notarization (set NOTARY_PROFILE to enable)"
fi

SIGN_UPDATE="$(find "$DERIVED/SourcePackages/artifacts" -name sign_update -type f 2>/dev/null | head -1)"
echo
echo "==> Done: $DMG"
if [ -n "$SIGN_UPDATE" ]; then
    echo "==> Appcast enclosure attributes (add to appcast.xml):"
    "$SIGN_UPDATE" "$DMG"
else
    echo "==> sign_update not found; build once so SwiftPM fetches Sparkle's tools"
fi
