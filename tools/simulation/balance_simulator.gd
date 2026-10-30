class_name BalanceSimulator
extends RefCounted

## Plays whole games on the core with a strategy. The same config, strategy and seed always give the same game.

## Far above any real game, so only a game that never ends reaches it.
const MAX_PLACEMENTS_PER_GAME: int = 10000
## Keeps the strategy's random draws apart from the game's, which use the game seed itself.
const TIE_BREAKER_SEED_OFFSET: int = 7919


static func play_game(config: BalancingConfig, strategy: PlayStrategy, game_seed: int, max_placements: int = MAX_PLACEMENTS_PER_GAME) -> GameRecord:
	var session := GameSession.new(config, _create_seeded_rng(game_seed))
	var tie_breaker: RandomNumberGenerator = _create_seeded_rng(game_seed + TIE_BREAKER_SEED_OFFSET)
	var record := GameRecord.new(config.column_count_per_side)
	while not session.is_game_over and record.placement_count < max_placements:
		var column: int = strategy.choose_column(session, tie_breaker)
		record.register_turn(column, session.play_column(column))
	record.is_capped = not session.is_game_over
	record.score = session.score
	record.highest_level = session.highest_level_reached
	return record


## Game i uses the seed first_seed + i, so every scenario and strategy plays the same tile sequences.
## on_game_played, if valid, receives the number of games played so far.
static func play_games(
	config: BalancingConfig, strategy: PlayStrategy, first_seed: int, game_count: int, on_game_played: Callable = Callable()
) -> Array[GameRecord]:
	var records: Array[GameRecord] = []
	for game_index: int in game_count:
		records.append(play_game(config, strategy, first_seed + game_index))
		if on_game_played.is_valid():
			on_game_played.call(records.size())
	return records


static func _create_seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
