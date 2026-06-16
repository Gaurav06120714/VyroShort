#!/bin/bash
# Creates a stable self-signed code-signing identity for VyroShort in a dedicated
# keychain. Signing every build with this identity gives the app a constant code
# signature, so macOS keeps Screen Recording permission across rebuilds.
#
# Idempotent: re-running detects the existing identity and does nothing.
# Usage: scripts/setup_signing.sh
set -euo pipefail

IDENTITY="VyroShort Self-Signed"
KC_NAME="VyroShortSigning"
KC_PW="vyroshort"
KC="$HOME/Library/Keychains/${KC_NAME}.keychain-db"

if security find-identity -v -p codesigning 2>/dev/null | grep -q "$IDENTITY"; then
  echo ">>> Signing identity already present: $IDENTITY"
  exit 0
fi

echo ">>> Creating keychain $KC_NAME"
security create-keychain -p "$KC_PW" "$KC" 2>/dev/null || true
security set-keychain-settings "$KC"            # no auto-lock
security unlock-keychain -p "$KC_PW" "$KC"
# Keep the existing keychains in the search list and add ours.
EXISTING=$(security list-keychains -d user | sed 's/[",]//g' | xargs)
# shellcheck disable=SC2086
security list-keychains -d user -s "$KC" $EXISTING

WORK="$(mktemp -d)"
cat > "$WORK/openssl.cnf" <<'EOF'
[ req ]
distinguished_name = dn
x509_extensions    = v3
prompt             = no
[ dn ]
CN = VyroShort Self-Signed
O  = VyroShort
[ v3 ]
basicConstraints       = critical, CA:false
keyUsage               = critical, digitalSignature
extendedKeyUsage       = critical, codeSigning
EOF

echo ">>> Generating self-signed code-signing certificate (10 years)"
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout "$WORK/key.pem" -out "$WORK/cert.pem" -config "$WORK/openssl.cnf"
# -legacy: OpenSSL 3 must write the older PKCS12 format that Apple's
# `security import` (LibreSSL-based) can read, otherwise MAC verification fails.
LEGACY=""
if openssl version 2>/dev/null | grep -q "OpenSSL 3"; then LEGACY="-legacy"; fi
# shellcheck disable=SC2086
openssl pkcs12 -export $LEGACY -inkey "$WORK/key.pem" -in "$WORK/cert.pem" \
  -name "$IDENTITY" -out "$WORK/id.p12" -passout pass:"$KC_PW"

echo ">>> Importing identity into keychain"
security import "$WORK/id.p12" -k "$KC" -P "$KC_PW" -T /usr/bin/codesign -A
# Allow codesign to use the key without an interactive prompt.
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KC_PW" "$KC" >/dev/null

rm -rf "$WORK"
echo ">>> Done. Available identities:"
security find-identity -v -p codesigning | grep "$IDENTITY" || true
