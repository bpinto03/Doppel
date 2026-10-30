# 0005 — Save writing

**Status:** accepted (2026-10-30)

## Context

Android can kill the app in the background without warning, so nothing is saved "on exit". The save is written often (every turn, every settings change, when the app leaves the foreground) and must survive a kill in the middle of a write. Writes must stay cheap: no write per frame, no burst of identical writes.

## Decision

- `SaveManager.set_value()` changes the save in memory and asks for one write at the end of the frame (`flush.call_deferred()`): changes made in the same frame make one write.
- `SaveManager.flush()` writes the waiting changes at once. It is called when the app leaves the foreground or loses focus.
- A write whose content equals the last written content is skipped.
- A write goes through three steps:
  1. save to `save.cfg.tmp`, then read it back and compare it with the expected content;
  2. rename the current `save.cfg` to `save.cfg.bak`;
  3. rename `save.cfg.tmp` to `save.cfg`.
- Loading reads `save.cfg`, else `save.cfg.bak`, else starts empty.
  - A missing file is normal (first launch) and silent.
  - A file that exists but is empty, unreadable, or from a newer save version is ignored with a `push_warning`.
- `SaveManager.load_save()` drops the changes not yet written.
- Tests point `SaveManager.save_path` at their own file (`SaveFixture`), never at `user://save.cfg`.

## Consequences

- A kill during step 1 leaves `save.cfg` untouched. A kill between steps 2 and 3 leaves the previous save in `save.cfg.bak`: at most the last write is lost.
- A save from a newer version (after a downgrade) is ignored, then overwritten by the next write.
- Code that needs the file on disk at once (tests, app going to the background) calls `flush()`.
