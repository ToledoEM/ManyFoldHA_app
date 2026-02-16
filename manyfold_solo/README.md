# Manyfold Home Assistant Add-on

This add-on wraps `ghcr.io/manyfold3d/manyfold-solo` for Home Assistant OS with persistent storage and configurable host-backed media paths.

## Features

- Runs Manyfold on port `3214`.
- Persists app data, database, cache, and settings under `/config` (`addon_config`).
- Uses configurable library and import paths on Home Assistant host storage.
- Refuses startup if configured paths resolve outside `/share`, `/media`, or `/config`.
- No external PostgreSQL or Redis required.
- Supports `amd64` and `aarch64`.

## Default paths

- Library path: `/share/manyfold/models`
- Import path: `/share/manyfold/import`
- Thumbnails path: `/config/thumbnails`

## Installation

1. In Home Assistant OS Add-on Store, open menu (`...`) -> `Repositories`.
2. Add the Git repository URL for this add-on repository root (the repo includes `repository.yaml` and `manyfold_solo/`).
3. Refresh Add-on Store and install **Manyfold**.
4. Configure options (defaults are safe for first run):
   - `library_path`: `/share/manyfold/models`
   - `import_path`: `/share/manyfold/import`
   - `secret_key_base`: leave blank to auto-generate
5. Start the add-on.
6. Open `http://<HA_IP>:3214`.

Local development alternative on the HA host:

1. Copy `manyfold_solo/` to `/addons/manyfold_solo`.
2. In Add-on Store menu (`...`), click `Check for updates`.
3. Install and run **Manyfold** from local add-ons.

## Library/index workflow

1. Drop STL/3MF/etc into `/share/manyfold/models` on the host.
2. In Manyfold UI, configure a library that points to the same container path.
3. Optionally use `/share/manyfold/import` as a staging area, then move curated files to the library path.
4. Thumbnails and indexing artifacts persist in `/config/thumbnails`.

## Options

- `secret_key_base`: App secret. Auto-generated and persisted at `/config/secret_key_base` when empty.
- `puid` / `pgid`: Ownership applied to mapped directories.
- `multiuser`: Toggle Manyfold multiuser mode.
- `library_path`: Scanned/indexed path.
- `import_path`: Staging/drop path.
- `thumbnails_path`: Persistent thumbnails/index artifacts (must be under `/config`).
- `log_level`: `info`, `debug`, `warn`, `error`.

## Validation behavior

- Startup fails if `library_path`, `import_path`, or `thumbnails_path` resolve outside mapped storage roots.
- `thumbnails_path` must resolve under `/config` to guarantee persistence.

## Notes

- This baseline avoids Home Assistant ingress and keeps direct port access.
- If `puid`/`pgid` change, restart the add-on to re-apply ownership to mapped directories.
