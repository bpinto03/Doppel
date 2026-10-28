class_name GameFeedback
extends RefCounted

## Plays the sound of each game event. It only observes the playback and the board, like the animations.

var _config: AudioConfig


func _init(config: AudioConfig, playback: ResolutionPlayback, board_view: BoardView) -> void:
	_config = config
	playback.tiles_landed.connect(_on_tiles_landed)
	playback.chain_link_merged.connect(_on_chain_link_merged)
	board_view.unplayable_column_released.connect(_on_unplayable_column_released)


func play_game_over() -> void:
	AudioManager.play_effect(_config.game_over)


func play_ui_click() -> void:
	AudioManager.play_effect(_config.ui_click)


func _on_tiles_landed() -> void:
	AudioManager.play_effect(_config.placement)


## One sound per chain link, however many groups merge in it, so sounds never pile up.
func _on_chain_link_merged(chain_link: int) -> void:
	AudioManager.play_effect(_config.get_chain_link_effect(chain_link), _config.get_chain_pitch_scale(chain_link))


func _on_unplayable_column_released() -> void:
	AudioManager.play_effect(_config.unplayable_column)
