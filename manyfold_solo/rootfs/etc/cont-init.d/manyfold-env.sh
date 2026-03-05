#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Runs before s6 services start. Reads addon options and injects env vars
# into the s6 container environment so with-contenv picks them up.
set -e

OPTIONS_FILE=/data/options.json
S6_ENV=/var/run/s6/container_environment

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

# Write env vars into s6 container environment
mkdir -p "$S6_ENV"
printf '%s' "$SECRET_KEY"                    > "$S6_ENV/SECRET_KEY_BASE"
printf '%s' "$PUID"                          > "$S6_ENV/PUID"
printf '%s' "$PGID"                          > "$S6_ENV/PGID"
printf '%s' "$MULTIUSER"                     > "$S6_ENV/MULTIUSER"
printf '%s' "$LIBRARY_PATH"                  > "$S6_ENV/LIBRARY_PATH"
printf '%s' "$THUMBNAILS_PATH"               > "$S6_ENV/CACHE_PATH"
printf '%s' "$LOG_LEVEL"                     > "$S6_ENV/LOG_LEVEL"
printf '%s' "$WEB_CONCURRENCY"               > "$S6_ENV/WEB_CONCURRENCY"
printf '%s' "$RAILS_MAX_THREADS"             > "$S6_ENV/RAILS_MAX_THREADS"
printf '%s' "$DEFAULT_WORKER_CONCURRENCY"    > "$S6_ENV/DEFAULT_WORKER_CONCURRENCY"
printf '%s' "$PERFORMANCE_WORKER_CONCURRENCY" > "$S6_ENV/PERFORMANCE_WORKER_CONCURRENCY"
printf '%s' "$MAX_FILE_UPLOAD_SIZE"          > "$S6_ENV/MAX_FILE_UPLOAD_SIZE"
printf '%s' "$MAX_FILE_EXTRACT_SIZE"         > "$S6_ENV/MAX_FILE_EXTRACT_SIZE"
printf '%s' "production"                     > "$S6_ENV/RAILS_ENV"
printf '%s' "3214"                           > "$S6_ENV/PORT"
