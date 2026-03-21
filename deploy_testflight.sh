#!/bin/bash
set -e

# ─── Qulo V2 — TestFlight Deploy Script ───

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── Load .env if exists ───
if [ -f "$PROJECT_DIR/.env" ]; then
  set -a
  source "$PROJECT_DIR/.env"
  set +a
fi

PUBSPEC="$PROJECT_DIR/pubspec.yaml"
EXPORT_PLIST="$PROJECT_DIR/ios/ExportOptions.plist"
ARCHIVE_DIR="$PROJECT_DIR/build/ios/archive"
IPA_DIR="$PROJECT_DIR/build/ios/ipa"

# ─── Colors ───
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[DEPLOY]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ─── 1. Increment build number ───
CURRENT_VERSION_LINE=$(grep '^version:' "$PUBSPEC")
VERSION_NAME=$(echo "$CURRENT_VERSION_LINE" | sed 's/version: //' | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION_LINE" | cut -d'+' -f2)
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))

log "Version: $VERSION_NAME+$BUILD_NUMBER → $VERSION_NAME+$NEW_BUILD_NUMBER"

sed -i '' "s/^version: ${VERSION_NAME}+${BUILD_NUMBER}/version: ${VERSION_NAME}+${NEW_BUILD_NUMBER}/" "$PUBSPEC"

# ─── 2. Clean ───
log "Cleaning previous build..."
cd "$PROJECT_DIR"
flutter clean
flutter pub get

# ─── 3. Build iOS archive ───
log "Building iOS release..."

# Production API URL — update this for your server
API_BASE_URL="${API_BASE_URL:-https://qulo-server-production.up.railway.app/api/v1}"

flutter build ipa \
  --release \
  --export-options-plist="$EXPORT_PLIST" \
  --dart-define=API_BASE_URL="$API_BASE_URL"

# ─── 4. Find the IPA ───
IPA_FILE=$(find "$PROJECT_DIR/build/ios/ipa" -name "*.ipa" -type f | head -1)

if [ -z "$IPA_FILE" ]; then
  err "IPA file not found in build/ios/ipa/"
fi

log "IPA ready: $IPA_FILE"

# ─── 5. Upload to TestFlight ───
log "Uploading to TestFlight..."

xcrun altool --upload-app \
  --type ios \
  --file "$IPA_FILE" \
  --apiKey "${APP_STORE_API_KEY:-}" \
  --apiIssuer "${APP_STORE_API_ISSUER:-}" \
  2>/dev/null || {
    warn "altool upload failed — trying xcrun notarytool / Transporter"
    warn "You can manually upload: $IPA_FILE"
    warn "Open Transporter.app and drag the IPA, or use:"
    echo ""
    echo "  xcrun altool --upload-app --type ios --file \"$IPA_FILE\" --apiKey YOUR_KEY --apiIssuer YOUR_ISSUER"
    echo ""
}

log "Done! Version $VERSION_NAME+$NEW_BUILD_NUMBER"
