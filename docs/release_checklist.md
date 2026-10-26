# Release checklist

## Identity

- Package ID: `com.rumble.doppel` (`package/unique_name` in `export_presets.cfg`). Final once published on Google Play: never change it.

## Signing

- Keystores and their passwords stay out of the repository (`.gitignore`). Godot stores export passwords in `.godot/export_credentials.cfg`, which is ignored.
