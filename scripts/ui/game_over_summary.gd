class_name GameOverSummary
extends RefCounted

## What the game over screen shows. Beating a record of 0, on the very first game, is not announced.

var score: int
var best_score: int
var highest_level: int
var is_new_record: bool


func _init(session: GameSession, best_score_before_game: int, current_best_score: int) -> void:
	score = session.score
	best_score = current_best_score
	highest_level = session.highest_level_reached
	is_new_record = best_score_before_game > 0 and session.score > best_score_before_game
