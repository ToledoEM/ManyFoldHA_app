# Changelog

## 1.0.1

### Added

- New resource tuning options for smaller HAOS hosts:
  - `web_concurrency`
  - `rails_max_threads`
  - `default_worker_concurrency`
  - `performance_worker_concurrency`
  - `max_file_upload_size`
  - `max_file_extract_size`
- Baseline AppArmor support:
  - `apparmor: true` in add-on metadata
  - `manyfold_solo/apparmor.txt` profile

### Changed

- Removed `import_path` option and runtime wiring to reduce confusion (it was not a web import endpoint).
- Kept ingress disabled and documented direct access on port `3214`.
- Host media mappings (`/share`, `/media`) are writable to support writable library paths like `/media/manyfold/models`.

### Fixed

- Home Assistant ingress/panel 404 issue by moving to direct web UI access model.
- Startup/runtime setup improvements:
  - Better path validation for configured library and thumbnails paths
  - Clearer startup logs and configuration summary
  - More robust secret/bootstrap handling and ownership setup

### Notes

- Recommended small-server baseline (see README):
  - `web_concurrency: 1`
  - `rails_max_threads: 5`
  - `default_worker_concurrency: 2`
  - `performance_worker_concurrency: 1`

## 1.0.0

### Initial release

- First Home Assistant add-on packaging for Manyfold (`manyfold_solo`).
- Runs `ghcr.io/manyfold3d/manyfold-solo` with persistent data under `/config`.
- Sidebar/web UI integration on port `3214`.
- Configurable storage paths and startup path safety checks.
- Non-root runtime defaults (`puid`/`pgid`) and startup ownership handling.
