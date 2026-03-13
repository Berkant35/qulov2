#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════
#  Qulo V2 — Unified Deploy Script
#  Usage:
#    ./deploy.sh dev          → env.dart'ı local IP'ye çevir
#    ./deploy.sh server       → Railway'e sunucu deploy
#    ./deploy.sh testflight   → iOS TestFlight build + upload
#    ./deploy.sh apk          → Android APK build
#    ./deploy.sh all          → server + testflight + apk
# ═══════════════════════════════════════════════════════════════

# ─── Paths ───
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
SERVER_DIR="$(dirname "$SCRIPT_DIR")/qulo-server"
ENV_DART="$PROJECT_DIR/lib/core/config/env.dart"
PUBSPEC="$PROJECT_DIR/pubspec.yaml"
EXPORT_PLIST="$PROJECT_DIR/ios/ExportOptions.plist"

# ─── URLs ───
PROD_URL="https://qulo-server-production.up.railway.app/api/v1"
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")
DEV_URL="http://${LOCAL_IP}:3001/api/v1"

# ─── Colors ───
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Helpers ───
log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[→]${NC} $1"; }
header() {
  echo ""
  echo -e "${CYAN}${BOLD}══════════════════════════════════════${NC}"
  echo -e "${CYAN}${BOLD}  $1${NC}"
  echo -e "${CYAN}${BOLD}══════════════════════════════════════${NC}"
  echo ""
}

# ─── Current env.dart URL ───
get_current_url() {
  grep "defaultValue:" "$ENV_DART" | head -1 | sed "s/.*'\(.*\)'.*/\1/"
}

is_prod_url() {
  local current=$(get_current_url)
  [[ "$current" == "$PROD_URL" ]]
}

is_dev_url() {
  local current=$(get_current_url)
  [[ "$current" != "$PROD_URL" ]]
}

# ═══════════════════════════════════════════════════════════════
#  PREFLIGHT CHECKS
# ═══════════════════════════════════════════════════════════════

check_env_is_prod() {
  local current=$(get_current_url)
  if ! is_prod_url; then
    echo ""
    warn "env.dart şu anda DEV URL'ine ayarlı:"
    echo -e "  ${RED}$current${NC}"
    echo -e "  Production URL: ${GREEN}$PROD_URL${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}"Production URL'e çevirip devam edeyim mi? (y/n): "${NC})" answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
      set_url "$PROD_URL"
    else
      err "Deploy iptal — env.dart production URL'de değil."
    fi
  else
    log "env.dart production URL'de ✓"
  fi
}

check_git_clean() {
  local dir="$1"
  local name="$2"
  cd "$dir"
  if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    warn "$name — commit edilmemiş değişiklikler var:"
    git status --short
    echo ""
    read -p "$(echo -e ${YELLOW}"Devam etmek istiyor musun? (y/n): "${NC})" answer
    [[ "$answer" != "y" && "$answer" != "Y" ]] && err "Deploy iptal."
  else
    log "$name — git temiz ✓"
  fi
}

check_server_builds() {
  info "Sunucu build test ediliyor..."
  cd "$SERVER_DIR"
  npm run build || err "Sunucu build BAŞARISIZ!"
  log "Sunucu build başarılı ✓"
}

check_flutter_analyze() {
  info "Flutter analyze çalıştırılıyor..."
  cd "$PROJECT_DIR"
  flutter analyze --no-fatal-infos || {
    warn "Flutter analyze uyarıları var, devam ediliyor..."
  }
  log "Flutter analyze tamamlandı ✓"
}

# ═══════════════════════════════════════════════════════════════
#  URL SWITCH
# ═══════════════════════════════════════════════════════════════

set_url() {
  local target_url="$1"
  local current=$(get_current_url)
  if [[ "$current" == "$target_url" ]]; then
    log "env.dart zaten doğru URL'de: $target_url"
    return
  fi
  sed -i '' "s|defaultValue: '${current}'|defaultValue: '${target_url}'|" "$ENV_DART"
  log "env.dart güncellendi: $target_url"
}

# ═══════════════════════════════════════════════════════════════
#  CMD: dev — Local geliştirme moduna geç
# ═══════════════════════════════════════════════════════════════

cmd_dev() {
  header "DEV MODE"
  info "Local IP: $LOCAL_IP"
  set_url "$DEV_URL"
  echo ""
  log "Artık flutter run ile local sunucuya bağlanabilirsin."
  log "Sunucuyu başlat: cd $SERVER_DIR && npm run dev"
}

# ═══════════════════════════════════════════════════════════════
#  CMD: prod — Production URL'e geri dön
# ═══════════════════════════════════════════════════════════════

cmd_prod() {
  header "PRODUCTION MODE"
  set_url "$PROD_URL"
  log "env.dart production URL'e döndürüldü."
}

# ═══════════════════════════════════════════════════════════════
#  CMD: server — Railway deploy
# ═══════════════════════════════════════════════════════════════

cmd_server() {
  header "SERVER DEPLOY (Railway)"

  if [ ! -d "$SERVER_DIR" ]; then
    err "Server dizini bulunamadı: $SERVER_DIR"
  fi

  cd "$SERVER_DIR"

  # Git check
  check_git_clean "$SERVER_DIR" "qulo-server"

  # Build test
  check_server_builds

  # Push to trigger Railway auto-deploy
  info "Railway deploy tetikleniyor (git push)..."
  local branch=$(git branch --show-current)

  if [[ "$branch" != "main" ]]; then
    warn "Aktif branch: $branch (main değil)"
    read -p "$(echo -e ${YELLOW}"main'e push yerine $branch'e push yapılacak. OK? (y/n): "${NC})" answer
    [[ "$answer" != "y" && "$answer" != "Y" ]] && err "Deploy iptal."
  fi

  git push origin "$branch"
  log "Git push tamamlandı — Railway auto-deploy başlıyor."

  # Health check
  echo ""
  info "30 saniye bekleniyor (Railway build)..."
  sleep 30

  local retries=6
  for i in $(seq 1 $retries); do
    info "Health check deneme $i/$retries..."
    local response=$(curl -s -o /dev/null -w "%{http_code}" "https://qulo-server-production.up.railway.app/ping" 2>/dev/null || echo "000")
    if [[ "$response" == "200" ]]; then
      log "Sunucu çalışıyor! (HTTP 200) ✓"
      curl -s "https://qulo-server-production.up.railway.app/ping" | python3 -m json.tool 2>/dev/null || true
      return
    fi
    warn "HTTP $response — 15 saniye sonra tekrar denenecek..."
    sleep 15
  done
  warn "Health check başarısız oldu. Railway dashboard'u kontrol et."
}

# ═══════════════════════════════════════════════════════════════
#  CMD: testflight — iOS TestFlight build + upload
# ═══════════════════════════════════════════════════════════════

cmd_testflight() {
  header "iOS TESTFLIGHT BUILD"

  cd "$PROJECT_DIR"

  # Pre-checks
  check_env_is_prod
  check_flutter_analyze

  # Increment build number
  local current_line=$(grep '^version:' "$PUBSPEC")
  local version_name=$(echo "$current_line" | sed 's/version: //' | cut -d'+' -f1)
  local build_number=$(echo "$current_line" | cut -d'+' -f2)
  local new_build=$((build_number + 1))

  log "Version: $version_name+$build_number → $version_name+$new_build"
  sed -i '' "s/^version: ${version_name}+${build_number}/version: ${version_name}+${new_build}/" "$PUBSPEC"

  # Clean + build
  info "flutter clean + pub get..."
  flutter clean
  flutter pub get

  info "iOS IPA build başlıyor..."
  flutter build ipa \
    --release \
    --export-options-plist="$EXPORT_PLIST" \
    --dart-define=API_BASE_URL="$PROD_URL"

  # Find IPA
  local ipa_file=$(find "$PROJECT_DIR/build/ios/ipa" -name "*.ipa" -type f | head -1)
  if [ -z "$ipa_file" ]; then
    err "IPA dosyası bulunamadı!"
  fi
  log "IPA hazır: $ipa_file"

  # Upload
  info "TestFlight'a yükleniyor..."
  xcrun altool --upload-app \
    --type ios \
    --file "$ipa_file" \
    --apiKey "${APP_STORE_API_KEY:-}" \
    --apiIssuer "${APP_STORE_API_ISSUER:-}" \
    2>/dev/null || {
      warn "altool upload başarısız — manuel yükleme gerekebilir:"
      echo ""
      echo "  Transporter.app ile: $ipa_file"
      echo ""
  }

  log "TestFlight build tamamlandı! v$version_name+$new_build"
}

# ═══════════════════════════════════════════════════════════════
#  CMD: apk — Android APK build
# ═══════════════════════════════════════════════════════════════

cmd_apk() {
  header "ANDROID APK BUILD"

  cd "$PROJECT_DIR"

  # Pre-checks
  check_env_is_prod
  check_flutter_analyze

  # Increment build number
  local current_line=$(grep '^version:' "$PUBSPEC")
  local version_name=$(echo "$current_line" | sed 's/version: //' | cut -d'+' -f1)
  local build_number=$(echo "$current_line" | cut -d'+' -f2)
  local new_build=$((build_number + 1))

  log "Version: $version_name+$build_number → $version_name+$new_build"
  sed -i '' "s/^version: ${version_name}+${build_number}/version: ${version_name}+${new_build}/" "$PUBSPEC"

  # Clean + build
  info "flutter clean + pub get..."
  flutter clean
  flutter pub get

  info "APK build başlıyor..."
  flutter build apk \
    --release \
    --dart-define=API_BASE_URL="$PROD_URL"

  local apk_file="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
  if [ -f "$apk_file" ]; then
    local size=$(du -h "$apk_file" | cut -f1)
    log "APK hazır ($size): $apk_file"
  else
    err "APK dosyası bulunamadı!"
  fi

  log "Android APK build tamamlandı! v$version_name+$new_build"
}

# ═══════════════════════════════════════════════════════════════
#  CMD: all — Her şeyi deploy et
# ═══════════════════════════════════════════════════════════════

cmd_all() {
  header "FULL DEPLOY (Server + TestFlight + APK)"

  check_env_is_prod
  check_git_clean "$SERVER_DIR" "qulo-server"
  check_git_clean "$PROJECT_DIR" "qulov2"

  cmd_server
  cmd_testflight
  cmd_apk

  echo ""
  header "DEPLOY TAMAMLANDI"
}

# ═══════════════════════════════════════════════════════════════
#  CMD: status — Mevcut durumu göster
# ═══════════════════════════════════════════════════════════════

cmd_status() {
  header "QULO DURUM"

  local current_url=$(get_current_url)
  local version_line=$(grep '^version:' "$PUBSPEC")

  echo -e "  ${BOLD}Flutter Version:${NC}  $version_line"
  echo -e "  ${BOLD}API URL:${NC}          $current_url"

  if is_prod_url; then
    echo -e "  ${BOLD}Mod:${NC}              ${GREEN}PRODUCTION${NC}"
  else
    echo -e "  ${BOLD}Mod:${NC}              ${YELLOW}DEVELOPMENT${NC}"
  fi

  echo -e "  ${BOLD}Local IP:${NC}         $LOCAL_IP"
  echo -e "  ${BOLD}Server Dir:${NC}       $SERVER_DIR"
  echo ""

  # Server health
  info "Railway sunucu durumu kontrol ediliyor..."
  local response=$(curl -s -o /dev/null -w "%{http_code}" "https://qulo-server-production.up.railway.app/ping" 2>/dev/null || echo "000")
  if [[ "$response" == "200" ]]; then
    log "Railway sunucu: ${GREEN}ONLINE${NC}"
  else
    warn "Railway sunucu: HTTP $response"
  fi
}

# ═══════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════

show_usage() {
  echo ""
  echo -e "${BOLD}Qulo V2 Deploy Script${NC}"
  echo ""
  echo -e "  ${CYAN}./deploy.sh dev${NC}          Local geliştirme moduna geç"
  echo -e "  ${CYAN}./deploy.sh prod${NC}         Production URL'e geri dön"
  echo -e "  ${CYAN}./deploy.sh server${NC}       Railway'e sunucu deploy"
  echo -e "  ${CYAN}./deploy.sh testflight${NC}   iOS TestFlight build + upload"
  echo -e "  ${CYAN}./deploy.sh apk${NC}          Android APK build"
  echo -e "  ${CYAN}./deploy.sh all${NC}          server + testflight + apk"
  echo -e "  ${CYAN}./deploy.sh status${NC}       Mevcut durumu göster"
  echo ""
}

case "${1:-}" in
  dev)        cmd_dev ;;
  prod)       cmd_prod ;;
  server)     cmd_server ;;
  testflight) cmd_testflight ;;
  apk)        cmd_apk ;;
  all)        cmd_all ;;
  status)     cmd_status ;;
  *)          show_usage ;;
esac
