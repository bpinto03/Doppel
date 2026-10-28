# 0004 — Audio key

**Status:** accepted (2026-10-28)

## Context

Step 2.4 gives chains a rising pitch: every chain link replays the merge sound one step higher on a scale. The merge sound (`merge.wav`, Kenney `drop_003`) is a near-pure tone at 737.7 Hz (F#5), and the game over sound (three notes from a Kenney jingle) is written in C (E4 D4 C4). Both keys were compared on a phone speaker and on a PC: C, and F# with the game over moved down a tritone.

## Decision

**C major pentatonic**: C, D, E, G, A (`scale_root_semitones = 0`, `chain_scale_intervals = [2, 2, 3, 2, 3]`).

- Chain links play C5, D5, E5, G5, A5, C6... up to C7 at the 24-semitone cap: a comfortable range for a short percussive note.
- The game over sound plays as recorded, down to C4 (261.6 Hz), which a phone speaker reproduces well. In F#, it would have gone down to F#3 (185 Hz), too low for a phone speaker.
- A pentatonic scale has no half steps, so any two chain notes sound well together, even when they overlap.

## Alternative rejected

**F# major pentatonic** (`scale_root_semitones = 6`): the merge sound plays almost as recorded (pitch scale 1.004, 0.190 s), but the game over sound must be transposed a tritone: down to F#3 (too low for a phone speaker, 0.99 s) or up to A#4 G#4 F#4 (shorter and brighter, 0.50 s).

## Consequences

- `merge` and `chain` play `merge.wav` lowered by 5.95 semitones (pitch scale 0.709): link 1 lasts 0.269 s instead of 0.191 s.
- `merge_sound_semitones_above_c` (5.946) is the measured pitch of `merge.wav`: measure it again when the file changes. `scale_root_semitones` stays a setting, should the key change one day.
- The music (later in step 2.4) stays on these five notes: C major pentatonic, or its relative A minor pentatonic (A, C, D, E, G).
