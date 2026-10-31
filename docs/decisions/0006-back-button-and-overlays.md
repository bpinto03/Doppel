# 0006 — Back button and game overlays

**Status:** accepted (2026-10-31)

## Context

Step 3.1 adds a pause screen and a game over screen. Until then, the Android back button went from a game straight to the home screen, so a tap by mistake left the game. The app also loses the focus during a game for many reasons (call, notification shade, screen lock).

## Decision

- The tutorial opens only from the Tutorial button of the home screen, never by itself and never from a game (there is no "?" button in the HUD). It ends back on the home screen, on its last step or on Skip.
- The pause and the game over screens are **overlays of the game screen**, at most one at a time, freed with it. `Main` keeps one full screen at a time (home, game, settings); overlays are never stacked as screens.
- `ScreenNavigation` decides, as pure logic, what the back button does; `Main` and `GameScreen` only apply it:

| Where | Back |
|-------|------|
| Home | quits the app |
| Game in progress | opens the pause |
| Pause | closes the pause, the game resumes |
| Settings page of the pause | back to the main page of the pause |
| Game over screen | home |
| Tutorial | home, the saved game untouched |
| Settings screen (from home) | home |

- When the app becomes inactive during a game in progress (not the tutorial, not the game over screen), the game opens the pause after jumping the playback to its final state. The player resumes on purpose, and no turn is played by surprise. Ads (phase 4) only show outside a game in progress, so they never trigger it.
- Pause, in this order: Resume; Menu goes home and keeps the game for Continue; Restart abandons the game (it counts for the record, as Play does) and starts a new one at once; Settings switches the pause to its settings page.
- The settings page of the pause shows the sound, music, vibration and screen shake toggles of `SettingsRows`, saved and applied at once, then Back. It stays inside the pause overlay: the game screen is not freed and `Main` is not involved. Language and theme stay on the home settings screen, since a new theme would recolor the board mid-game.

## Consequences

- Leaving a game takes two taps (back, then Menu), on purpose.
- Nothing runs while paused: the playback was skipped and the board ignores input, so the tree is not paused; the music keeps playing.
