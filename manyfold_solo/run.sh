#!/usr/bin/with-contenv bash
set -Eeuo pipefail

CONFIG_DIR="/config"
OPTIONS_JSON="/data/options.json"
SECRET_FILE="${CONFIG_DIR}/secret_key_base"
DEFAULT_LIBRARY_PATH="/share/manyfold/models"
DEFAULT_IMPORT_PATH="/share/manyfold/import"
DEFAULT_THUMBNAILS_PATH="/config/thumbnails"
DEFAULT_LOG_LEVEL="info"

log() {
  echo "[manyfold-addon] $*"
}

die() {
  echo "[manyfold-addon] ERROR: $*" >&2
  exit 1
}

read_opt() {
  local key="$1"
  jq -er --arg k "$key" '.[$k]' "$OPTIONS_JSON" 2>/dev/null || true
}

normalize_path() {
  local raw="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath -m "$raw"
    return
  fi

  case "$raw" in
    /*) printf '%s\n' "$raw" ;;
    *) printf '/%s\n' "$raw" ;;
  esac
}

is_allowed_path() {
  local resolved="$1"
  case "$resolved" in
    /share|/share/*|/media|/media/*|/config|/config/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

require_mapped_path() {
  local label="$1"
  local raw="$2"
  local resolved

  resolved="$(normalize_path "$raw")"
  if ! is_allowed_path "$resolved"; then
    die "${label} '${raw}' resolves to '${resolved}', which is outside /share, /media, and /config"
  fi

  printf '%s\n' "$resolved"
}

ensure_dir() {
  local dir="$1"
  mkdir -p "$dir"
}

generate_secret() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 64
    return
  fi

  head -c 64 /dev/urandom | od -An -tx1 | tr -d ' \n'
}

start_manyfold() {
  if [[ -x /usr/src/app/bin/docker-entrypoint.sh ]]; then
    log "Starting Manyfold via /usr/src/app/bin/docker-entrypoint.sh foreman start"
    cd /usr/src/app
    exec ./bin/docker-entrypoint.sh foreman start
  fi

  if [[ -x /app/bin/docker-entrypoint.sh ]]; then
    log "Starting Manyfold via /app/bin/docker-entrypoint.sh foreman start"
    cd /app
    exec ./bin/docker-entrypoint.sh foreman start
  fi

  local candidate
  for candidate in \
    /usr/local/bin/docker-entrypoint.sh \
    /usr/local/bin/docker-entrypoint \
    /docker-entrypoint.sh \
    /entrypoint.sh
  do
    if [[ -x "$candidate" ]]; then
      log "Starting Manyfold via ${candidate}"
      if [[ "$candidate" == *docker-entrypoint* ]]; then
        exec "$candidate" foreman start
      fi
      exec "$candidate"
    fi
  done

  if command -v docker-entrypoint >/dev/null 2>&1; then
    log "Starting Manyfold via docker-entrypoint"
    exec docker-entrypoint foreman start
  fi

  if [[ -d /usr/src/app ]]; then
    cd /usr/src/app
  elif [[ -d /app ]]; then
    cd /app
  fi

  if command -v bundle >/dev/null 2>&1; then
    log "Starting Manyfold via rails server fallback"
    exec bundle exec rails server -b 0.0.0.0 -p 3214
  fi

  die "Could not find a known Manyfold entrypoint"
}

[[ -f "$OPTIONS_JSON" ]] || die "Missing options file at ${OPTIONS_JSON}"

PUID="$(read_opt puid)"; PUID="${PUID:-0}"
PGID="$(read_opt pgid)"; PGID="${PGID:-0}"
MULTIUSER="$(read_opt multiuser)"; MULTIUSER="${MULTIUSER:-true}"
LIBRARY_PATH_RAW="$(read_opt library_path)"; LIBRARY_PATH_RAW="${LIBRARY_PATH_RAW:-$DEFAULT_LIBRARY_PATH}"
IMPORT_PATH_RAW="$(read_opt import_path)"; IMPORT_PATH_RAW="${IMPORT_PATH_RAW:-$DEFAULT_IMPORT_PATH}"
THUMBNAILS_PATH_RAW="$(read_opt thumbnails_path)"; THUMBNAILS_PATH_RAW="${THUMBNAILS_PATH_RAW:-$DEFAULT_THUMBNAILS_PATH}"
LOG_LEVEL="$(read_opt log_level)"; LOG_LEVEL="${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}"
SECRET_KEY_BASE="$(read_opt secret_key_base)"; SECRET_KEY_BASE="${SECRET_KEY_BASE:-}"

[[ "$PUID" =~ ^[0-9]+$ ]] || die "puid must be a non-negative integer"
[[ "$PGID" =~ ^[0-9]+$ ]] || die "pgid must be a non-negative integer"

LIBRARY_PATH="$(require_mapped_path "library_path" "$LIBRARY_PATH_RAW")"
IMPORT_PATH="$(require_mapped_path "import_path" "$IMPORT_PATH_RAW")"
THUMBNAILS_PATH="$(require_mapped_path "thumbnails_path" "$THUMBNAILS_PATH_RAW")"

case "$THUMBNAILS_PATH" in
  /config|/config/*) ;;
  *) die "thumbnails_path must resolve under /config for persistence" ;;
esac

ensure_dir "$CONFIG_DIR"
ensure_dir "$LIBRARY_PATH"
ensure_dir "$IMPORT_PATH"
ensure_dir "$THUMBNAILS_PATH"

if [[ -z "$SECRET_KEY_BASE" ]]; then
  if [[ -s "$SECRET_FILE" ]]; then
    SECRET_KEY_BASE="$(cat "$SECRET_FILE")"
    log "Loaded SECRET_KEY_BASE from ${SECRET_FILE}"
  else
    SECRET_KEY_BASE="$(generate_secret)"
    printf '%s' "$SECRET_KEY_BASE" > "$SECRET_FILE"
    chmod 600 "$SECRET_FILE"
    log "Generated and stored SECRET_KEY_BASE at ${SECRET_FILE}"
  fi
else
  printf '%s' "$SECRET_KEY_BASE" > "$SECRET_FILE"
  chmod 600 "$SECRET_FILE"
  log "Saved provided SECRET_KEY_BASE to ${SECRET_FILE}"
fi

export SECRET_KEY_BASE
export PUID
export PGID
export MULTIUSER
export MANYFOLD_MULTIUSER="$MULTIUSER"
export MANYFOLD_LIBRARY_PATH="$LIBRARY_PATH"
export MANYFOLD_IMPORT_PATH="$IMPORT_PATH"
export MANYFOLD_THUMBNAILS_PATH="$THUMBNAILS_PATH"
export RAILS_LOG_LEVEL="$LOG_LEVEL"
export PORT="3214"

chown "$PUID:$PGID" "$CONFIG_DIR" "$LIBRARY_PATH" "$IMPORT_PATH" "$THUMBNAILS_PATH" 2>/dev/null || \
  log "Skipping chown (insufficient permissions or unchanged ownership)"

log "Configuration summary:"
log "  library_path=${LIBRARY_PATH}"
log "  import_path=${IMPORT_PATH}"
log "  thumbnails_path=${THUMBNAILS_PATH}"
log "  multiuser=${MULTIUSER}"
log "  puid:pgid=${PUID}:${PGID}"

start_manyfold
