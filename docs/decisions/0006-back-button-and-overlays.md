# 0006 — Back button and game overlays

**Status:** accepted (2026-10-31)

## Context

Step 3.1 adds a pause screen and a game over screen. Until then, the Android back button went from a game straight to the home screen, so a tap by mistake left the game. The app also loses the focus during a game for many reasons (call, notification shade, screen lock).

## Decision

- The pause and the game over screens are **overlays of the game screen**, at most one at a time, freed with it. `Main` keeps one full screen at a time (home, game, later settings); overlays are never stacked as screens.
- `ScreenNavigation` decides, as pure logic, what the back button does; `Main` and `GameScreen` only apply it:

| Where | Back |
|-------|------|
| Home | quits the app |
| Game in progress | opens the pause |
| Pause | closes the pause, the game resumes |
| Game over screen | home |
| Tutorial | home, the saved game untouched |

- When the app becomes inactive during a game in progress (not the tutorial, not the game over screen), the game opens the pause after jumping the playback to its final state. The player resumes on purpose, and no turn is played by surprise. Ads (phase 4) only show outside a game in progress, so they never trigger it.
- Pause: Resume; Restart abandons the game (it counts for the record, as Play does) and starts a new one at once; Menu goes home and keeps the game for Continue.

## Consequences

- Leaving a game takes two taps (back, then Menu), on purpose.
- Nothing runs while paused: the playback was skipped and the board ignores input, so the tree is not paused; the music keeps playing.
