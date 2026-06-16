#!/bin/bash
# Builds a signed, drag-to-Applications DMG for VyroShort.
# Usage: scripts/make_dmg.sh   (run from the project root)
set -euo pipefail

APP="build/Build/Products/Release/VyroShort.app"
DMG="dist/VyroShort.dmg"

if [ ! -d "$APP" ]; then
  echo "Release app not found. Build it first:"
  echo "  xcodebuild -project VyroShort.xcodeproj -scheme VyroShort -configuration Release \\"
  echo "    -destination 'platform=macOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build"
  exit 1
fi

mkdir -p dist
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/VyroShort.app"
S="$STAGE/VyroShort.app"

# Strip extended-attribute detritus, then sign the staged copy.
# Prefer the stable self-signed identity (scripts/setup_signing.sh) so Screen
# Recording permission survives rebuilds; fall back to ad-hoc if it's absent.
IDENTITY="VyroShort Self-Signed"
if security find-identity -v -p codesigning 2>/dev/null | grep -q "$IDENTITY"; then
  SIGN="$IDENTITY"
  echo ">>> Signing with stable identity: $IDENTITY"
else
  SIGN="-"
  echo ">>> Stable identity not found — signing ad-hoc (run scripts/setup_signing.sh for persistence)"
fi
xattr -c "$S"; find "$S" -exec xattr -c {} \; 2>/dev/null || true
codesign --remove-signature "$S" 2>/dev/null || true
codesign --force --deep --sign "$SIGN" "$S"
codesign --verify --strict "$S" && echo ">>> staged app signature OK"

ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "VyroShort" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"
echo ">>> built $DMG ($(du -h "$DMG" | cut -f1))"
