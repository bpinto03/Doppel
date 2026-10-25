class_name TilesFellEvent
extends ResolutionEvent

## Gravity only runs after the merges of a chain link, so chain_link starts at 1.
var chain_link: int
var falls: Array[TileFall]


func _init(link: int, tile_falls: Array[TileFall]) -> void:
	chain_link = link
	falls = tile_falls


## Every origin is emptied before any landing so falls in the same column never overwrite each other.
func apply_to(board: BoardState) -> void:
	for fall: TileFall in falls:
		board.set_level(fall.from_cell, BoardState.EMPTY_CELL)
	for fall: TileFall in falls:
		board.set_level(fall.to_cell, fall.level)
