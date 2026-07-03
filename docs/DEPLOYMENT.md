# VyroShort — Deployment & Release

This document covers how VyroShort is built, signed, packaged, and released.

## Prerequisites
- macOS 15+, Xcode 26+, Swift 6
- `brew install xcodegen`

## Local build
```bash
xcodegen generate
xcodebuild -project VyroShort.xcodeproj -scheme VyroShort \
  -configuration Release -destination 'platform=macOS' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

## Code signing
VyroShort ships with a **stable self-signed identity** so macOS keeps the granted
Screen Recording permission across rebuilds:
```bash
scripts/setup_signing.sh   # one-time — creates "VyroShort Self-Signed" in a dedicated keychain
scripts/make_dmg.sh        # signs the app with it and builds dist/VyroShort.dmg
```
If the identity is absent, `make_dmg.sh` falls back to ad-hoc signing (permission
must be re-granted after each rebuild).

## Release
Two ways:
1. **Automated (recommended):** push a tag — the `release.yml` workflow builds,
   packages, and publishes a GitHub Release with the DMG attached.
   ```bash
   git tag v1.1.0 && git push origin v1.1.0
   ```
2. **Manual:**
   ```bash
   scripts/make_dmg.sh
   gh release create v1.1.0 dist/VyroShort.dmg --title "VyroShort v1.1.0" --generate-notes
   ```

## Versioning
`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` live in `project.yml`. Bump them,
regenerate, and tag `vX.Y.Z`. Keep `CHANGELOG.md` in sync.

## Notarization (for distribution outside your own machines)
The self-signed build runs on the developer's Mac but will show Gatekeeper
warnings elsewhere. For public distribution you need a **paid Apple Developer
Program** membership, then:
```bash
# Sign with a Developer ID Application certificate
codesign --force --deep --options runtime \
  --sign "Developer ID Application: <Your Name> (TEAMID)" VyroShort.app
# Notarize
xcrun notarytool submit dist/VyroShort.dmg --apple-id <id> --team-id <TEAMID> \
  --password <app-specific-password> --wait
xcrun stapler staple dist/VyroShort.dmg
```
Until then, first launch requires **right-click → Open → Open**.

## CI
`.github/workflows/ci.yml` builds + tests on every push/PR to `main` and uploads
the DMG as an artifact. `.github/workflows/release.yml` publishes releases on tags.
