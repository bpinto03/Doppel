class_name HapticsConfig
extends Resource

## Vibration lengths in milliseconds. See docs/balancing.md.

@export var placement_duration_ms: int
@export var merge_duration_ms: int
## From this chain link on, a merge vibrates longer.
@export var big_chain_min_link: int
@export var big_chain_duration_ms: int
## Vibrations closer than this to the previous one are dropped, so they never blur together.
@export var min_interval_ms: int


func get_chain_link_duration_ms(chain_link: int) -> int:
	return big_chain_duration_ms if chain_link >= big_chain_min_link else merge_duration_ms
