@abstract
class_name ResolutionEvent
extends RefCounted

## One step of a turn, in the order it happened.


## Replays this step on a board holding the state that preceded it.
@abstract func apply_to(board: BoardState) -> void
