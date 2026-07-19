#!/usr/bin/env bash
set -euo pipefail

SIGNING_DIR="${SIGNING_DIR:-private/apple-signing}"
KEY_PATH="$SIGNING_DIR/sheldon-drive.key"
CERT_PATH="$SIGNING_DIR/distribution.cer"
PROFILE_PATH="$SIGNING_DIR/profile.mobileprovision"
PEM_PATH="$SIGNING_DIR/distribution.pem"
P12_PATH="$SIGNING_DIR/distribution.p12"
P12_B64_PATH="$SIGNING_DIR/distribution.p12.b64"
PROFILE_B64_PATH="$SIGNING_DIR/profile.mobileprovision.b64"

missing=0
for path in "$KEY_PATH" "$CERT_PATH" "$PROFILE_PATH"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  cat >&2 <<'EOF'

Expected files:
  private/apple-signing/sheldon-drive.key
  private/apple-signing/distribution.cer
  private/apple-signing/profile.mobileprovision

Upload private/apple-signing/sheldon-drive.csr to Apple to create distribution.cer.
Download the App Store provisioning profile from Apple as profile.mobileprovision.
EOF
  exit 1
fi

read -rsp "P12 export password: " P12_PASSWORD
echo

openssl x509 -inform DER -in "$CERT_PATH" -out "$PEM_PATH"
openssl pkcs12 -export \
  -inkey "$KEY_PATH" \
  -in "$PEM_PATH" \
  -out "$P12_PATH" \
  -passout "pass:$P12_PASSWORD"

base64 -w 0 "$P12_PATH" > "$P12_B64_PATH"
base64 -w 0 "$PROFILE_PATH" > "$PROFILE_B64_PATH"

chmod 600 "$P12_PATH" "$P12_B64_PATH" "$PROFILE_B64_PATH"

cat <<EOF
Prepared signing assets:
  $P12_PATH
  $P12_B64_PATH
  $PROFILE_B64_PATH

GitHub secret values:
  APPLE_CERTIFICATE_PASSWORD = the P12 password you just entered
  APPLE_CERTIFICATE_P12_BASE64 = contents of $P12_B64_PATH
  APPLE_PROVISIONING_PROFILE_BASE64 = contents of $PROFILE_B64_PATH

These files are ignored by git under private/apple-signing/.
EOF
