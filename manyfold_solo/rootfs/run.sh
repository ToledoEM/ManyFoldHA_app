#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -e

OPTIONS_FILE=/data/options.json

# Read options
SECRET_KEY=$(jq -r '.secret_key_base // empty' "$OPTIONS_FILE")
PUID=$(jq -r '.puid // 1000' "$OPTIONS_FILE")
PGID=$(jq -r '.pgid // 1000' "$OPTIONS_FILE")
MULTIUSER=$(jq -r '.multiuser // true' "$OPTIONS_FILE")
LIBRARY_PATH=$(jq -r '.library_path // "/share/manyfold/models"' "$OPTIONS_FILE")
THUMBNAILS_PATH=$(jq -r '.thumbnails_path // "/config/thumbnails"' "$OPTIONS_FILE")
LOG_LEVEL=$(jq -r '.log_level // "info"' "$OPTIONS_FILE")
WEB_CONCURRENCY=$(jq -r '.web_concurrency // 4' "$OPTIONS_FILE")
RAILS_MAX_THREADS=$(jq -r '.rails_max_threads // 16' "$OPTIONS_FILE")
DEFAULT_WORKER_CONCURRENCY=$(jq -r '.default_worker_concurrency // 4' "$OPTIONS_FILE")
PERFORMANCE_WORKER_CONCURRENCY=$(jq -r '.performance_worker_concurrency // 1' "$OPTIONS_FILE")
MAX_FILE_UPLOAD_SIZE=$(jq -r '.max_file_upload_size // 1073741824' "$OPTIONS_FILE")
MAX_FILE_EXTRACT_SIZE=$(jq -r '.max_file_extract_size // 1073741824' "$OPTIONS_FILE")

# Auto-generate and persist secret_key_base if blank.
# The persisted value survives addon updates so sessions and encrypted data are not lost.
# If the user manually sets secret_key_base in the addon options, that value takes priority.
SECRET_PERSIST=/config/secret_key_base
if [ -z "$SECRET_KEY" ]; then
  if [ -f "$SECRET_PERSIST" ]; then
    SECRET_KEY=$(cat "$SECRET_PERSIST")
  else
    SECRET_KEY=$(openssl rand -hex 64)
    echo "$SECRET_KEY" > "$SECRET_PERSIST"
    chmod 600 "$SECRET_PERSIST"
  fi
fi

# Export env vars expected by manyfold-solo
export SECRET_KEY_BASE="$SECRET_KEY"
export PUID="$PUID"
export PGID="$PGID"
export MULTIUSER="$MULTIUSER"
export LIBRARY_PATH="$LIBRARY_PATH"
export CACHE_PATH="$THUMBNAILS_PATH"
export LOG_LEVEL="$LOG_LEVEL"
export WEB_CONCURRENCY="$WEB_CONCURRENCY"
export RAILS_MAX_THREADS="$RAILS_MAX_THREADS"
export DEFAULT_WORKER_CONCURRENCY="$DEFAULT_WORKER_CONCURRENCY"
export PERFORMANCE_WORKER_CONCURRENCY="$PERFORMANCE_WORKER_CONCURRENCY"
export MAX_FILE_UPLOAD_SIZE="$MAX_FILE_UPLOAD_SIZE"
export MAX_FILE_EXTRACT_SIZE="$MAX_FILE_EXTRACT_SIZE"
export RAILS_ENV=production
export PORT=3214

# Hand off to upstream entrypoint
cd /usr/src/app
exec /usr/src/app/bin/docker-entrypoint.sh foreman start
