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

# ─── 4. Upload dSYMs to Firebase Crashlytics ───
log "Uploading dSYMs to Firebase Crashlytics..."

DSYM_DIR="$PROJECT_DIR/build/ios/archive/Runner.xcarchive/dSYMs"
UPLOAD_SYMBOLS="$PROJECT_DIR/ios/Pods/FirebaseCrashlytics/upload-symbols"
GSERVICE_PLIST="$PROJECT_DIR/ios/Runner/GoogleService-Info.plist"

if [ -d "$DSYM_DIR" ] && [ -x "$UPLOAD_SYMBOLS" ]; then
  "$UPLOAD_SYMBOLS" -gsp "$GSERVICE_PLIST" -p ios "$DSYM_DIR" || {
    warn "dSYM upload failed — you can retry manually:"
    echo "  $UPLOAD_SYMBOLS -gsp $GSERVICE_PLIST -p ios $DSYM_DIR"
  }
  log "dSYMs uploaded to Firebase ✓"
else
  warn "dSYM dir or upload-symbols not found — skipping Crashlytics upload"
  [ ! -d "$DSYM_DIR" ] && warn "  Missing: $DSYM_DIR"
  [ ! -x "$UPLOAD_SYMBOLS" ] && warn "  Missing: $UPLOAD_SYMBOLS"
fi

# ─── 5. Find the IPA ───
IPA_FILE=$(find "$PROJECT_DIR/build/ios/ipa" -name "*.ipa" -type f | head -1)

if [ -z "$IPA_FILE" ]; then
  err "IPA file not found in build/ios/ipa/"
fi

log "IPA ready: $IPA_FILE"

# ─── 6. Upload to TestFlight ───
log "Uploading to TestFlight..."

# Apple'in hata mesaji tek teshis kaynagimiz — stderr'i YUTMA.
# (Bir kez "Failed to upload package." disinda hicbir sey gormeden saatler kaybedildi.)
xcrun altool --upload-app \
  --type ios \
  --file "$IPA_FILE" \
  --apiKey "${APP_STORE_API_KEY:-}" \
  --apiIssuer "${APP_STORE_API_ISSUER:-}" || {
    warn "altool upload failed — Apple'in yukaridaki hata mesajini oku"
    warn "Sik gorulenler: 90186/90062 = surum hatti kapali, pubspec'te version'i yukselt"
    warn "Manuel yukleme: Transporter.app'e su dosyayi surukle → $IPA_FILE"
    err "TestFlight yuklemesi basarisiz — build $NEW_BUILD_NUMBER gonderilmedi"
}

log "Done! Version $VERSION_NAME+$NEW_BUILD_NUMBER TestFlight'a yuklendi"
