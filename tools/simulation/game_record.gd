class_name GameRecord
extends RefCounted

## What one simulated game did.

var placement_count: int
var highest_level: int
var score: int
var max_chain_length: int
var merge_placement_count: int
var cross_axis_placement_count: int
## Placements per left column, G1 first.
var column_placement_counts: Array[int] = []
## True when the game hit the placement cap before its end.
var is_capped: bool


func _init(column_count_per_side: int) -> void:
	column_placement_counts.resize(column_count_per_side)
	column_placement_counts.fill(0)


func register_turn(column: int, chain_result: ChainResult) -> void:
	placement_count += 1
	column_placement_counts[column] += 1
	max_chain_length = maxi(max_chain_length, chain_result.chain_length)
	if chain_result.chain_length > 0:
		merge_placement_count += 1
	if _has_cross_axis_merge(chain_result):
		cross_axis_placement_count += 1


func _has_cross_axis_merge(chain_result: ChainResult) -> bool:
	for event: ResolutionEvent in chain_result.events:
		var merge := event as GroupMergedEvent
		if merge != null and merge.is_crossing_axis:
			return true
	return false
