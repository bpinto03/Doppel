class_name AudioConfig
extends Resource

## Sound effects of each game event, and how chains climb the scale. See docs/balancing.md.

const SEMITONES_PER_OCTAVE: int = 12

@export_group("Sounds")
@export var placement: SoundEffect
## Chain link 1; later links play the chain sound. Both start on the same note, so no pitch repeats between links 1 and 2.
@export var merge: SoundEffect
@export var chain: SoundEffect
@export var game_over: SoundEffect
@export var ui_click: SoundEffect
@export var unplayable_column: SoundEffect

@export_group("Key")
## Root of the scale, in semitones above C: 0, the game's key (docs/decisions/0004-audio-key.md). Tunes the merge, chain and game over sounds.
@export var scale_root_semitones: int
## Measured pitch of the merge sound file, in semitones above the C below it.
@export var merge_sound_semitones_above_c: float

@export_group("Chain")
## Semitones climbed at each new chain link, in order, then again from the start of the list.
@export var chain_scale_intervals: Array[int]
## Later links keep the pitch of this one.
@export var chain_max_pitch_link: int
## The pitch never climbs more than this many semitones above link 1.
@export var chain_max_semitones: int

@export_group("Players")
## Players created once and reused; when all are busy, the oldest started is taken.
@export var player_pool_size: int

@export_group("Music")
## Loaded only while the music is wanted, so a disabled music takes no memory.
@export_file("*.ogg") var music_path: String
## Volume of the music player, below the effects so chain sounds stay clear. The Music bus volume stays the player's setting.
@export var music_volume_db: float
@export var music_fade_in_seconds: float
@export var music_fade_out_seconds: float


## Returns null when the file is missing or is not audio: the game then plays without music.
func load_music() -> AudioStream:
	if not ResourceLoader.exists(music_path):
		push_warning("Music file not found: %s" % music_path)
		return null
	var stream := load(music_path) as AudioStream
	if stream == null:
		push_warning("Music file is not an audio stream: %s" % music_path)
	return stream


func get_chain_link_effect(chain_link: int) -> SoundEffect:
	return merge if chain_link == 1 else chain


## Link 1 is the root of the scale (0); link 2 adds the first interval, and so on.
func get_chain_semitones(chain_link: int) -> int:
	var semitones: int = 0
	for step: int in mini(chain_link, chain_max_pitch_link) - 1:
		semitones += chain_scale_intervals[step % chain_scale_intervals.size()]
	return mini(semitones, chain_max_semitones)


## Link 1 plays the merge sound on the scale root, in the octave of the sound file.
func get_chain_pitch_scale(chain_link: int) -> float:
	return _semitones_to_pitch_scale(scale_root_semitones - merge_sound_semitones_above_c + get_chain_semitones(chain_link))


## The game over sound is written in C; another key moves it down to its root below C.
func get_game_over_pitch_scale() -> float:
	var transposition: int = posmod(scale_root_semitones, SEMITONES_PER_OCTAVE)
	if transposition > 0:
		transposition -= SEMITONES_PER_OCTAVE
	return _semitones_to_pitch_scale(transposition)


func _semitones_to_pitch_scale(semitones: float) -> float:
	return pow(2.0, semitones / SEMITONES_PER_OCTAVE)
