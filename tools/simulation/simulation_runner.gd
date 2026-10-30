extends SceneTree

## Entry point of ./run_simulation.sh: plays every selected scenario with every strategy, prints a table and writes a CSV.
## Options, after "--": --games N (default DEFAULT_GAME_COUNT), --scenarios name,name (default: all).
## The player's save is never written: SaveManager is pointed at a temporary file, and the real save is checked unchanged.

const BASE_CONFIG_PATH: String = "res://data/balancing.tres"
const SCENARIOS_PATH: String = "res://tools/simulation/scenarios.json"
const OUTPUT_DIRECTORY: String = "res://simulation_results"
## Keeps Godot from importing the CSV files as translations.
const GODOT_IGNORE_FILE: String = ".gdignore"
const TEMPORARY_SAVE_PATH: String = "user://simulation_save.cfg"
## Autoload names are not known when this script compiles, before the autoloads exist: the node is looked up instead.
const SAVE_MANAGER_NODE_PATH: NodePath = ^"/root/SaveManager"
const DEFAULT_GAME_COUNT: int = 1000
const FIRST_SEED: int = 1
const PROGRESS_LOG_COUNT: int = 10
const GAMES_OPTION: String = "--games"
const SCENARIOS_OPTION: String = "--scenarios"
const NAME_SEPARATOR: String = ","
const ALL_SCENARIOS_LABEL: String = "all"
const MILLISECONDS_PER_SECOND: float = 1000.0
const EXIT_SUCCESS: int = 0
const EXIT_FAILURE: int = 1


## Autoloads are only ready once the first frame starts.
func _initialize() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var save_manager: Node = root.get_node(SAVE_MANAGER_NODE_PATH)
	var player_save_path: String = save_manager.save_path
	var player_save_fingerprint: String = FileAccess.get_md5(player_save_path)
	save_manager.save_path = TEMPORARY_SAVE_PATH
	save_manager.load_save()
	var exit_code: int = _run_simulation()
	if FileAccess.get_md5(player_save_path) != player_save_fingerprint:
		printerr("The player's save changed during the simulation: %s" % ProjectSettings.globalize_path(player_save_path))
		exit_code = EXIT_FAILURE
	quit(exit_code)


func _run_simulation() -> int:
	var options: Dictionary[String, String] = _read_options(OS.get_cmdline_user_args())
	var game_count: int = int(options.get(GAMES_OPTION, str(DEFAULT_GAME_COUNT)))
	var base_config: BalancingConfig = load(BASE_CONFIG_PATH)
	var scenarios: Array[SimulationScenario] = _select_scenarios(options.get(SCENARIOS_OPTION, ""))
	if game_count <= 0 or scenarios.is_empty() or not _are_scenarios_valid(scenarios, base_config):
		return EXIT_FAILURE
	print("Base config %s, %d games per scenario and strategy, seeds %d to %d." % [BASE_CONFIG_PATH, game_count, FIRST_SEED, FIRST_SEED + game_count - 1])
	print("Estimated minutes use SECONDS_PER_PLACEMENT = %.1f s, still to calibrate on real games." % SimulationReport.SECONDS_PER_PLACEMENT)
	var report := SimulationReport.new()
	var started_msec: int = Time.get_ticks_msec()
	for scenario: SimulationScenario in scenarios:
		var config: BalancingConfig = scenario.create_config(base_config)
		print("%s: %s" % [scenario.name, SimulationReport.describe_config(config)])
		for strategy: PlayStrategy in _create_strategies(config):
			var on_game_played: Callable = _log_progress.bind(scenario.name, strategy.get_strategy_name(), game_count, started_msec)
			var records: Array[GameRecord] = BalanceSimulator.play_games(config, strategy, FIRST_SEED, game_count, on_game_played)
			report.add_row(scenario.name, strategy.get_strategy_name(), config, SimulationStats.from_records(records))
	print(report.build_console_text())
	print("Total time: %.1f s" % _get_elapsed_seconds(started_msec))
	return _write_csv(report.build_csv_text(), options.get(SCENARIOS_OPTION, ALL_SCENARIOS_LABEL))


func _create_strategies(config: BalancingConfig) -> Array[PlayStrategy]:
	return [RandomStrategy.new(), GreedyStrategy.new(config), HeuristicStrategy.new(config)]


## Reads "--name value" pairs.
func _read_options(arguments: PackedStringArray) -> Dictionary[String, String]:
	var options: Dictionary[String, String] = {}
	for index: int in range(0, arguments.size() - 1, 2):
		options[arguments[index]] = arguments[index + 1]
	return options


func _select_scenarios(selected_names: String) -> Array[SimulationScenario]:
	var scenarios: Array[SimulationScenario] = SimulationScenario.parse_scenarios(FileAccess.get_file_as_string(SCENARIOS_PATH))
	if scenarios.is_empty():
		printerr("No valid scenario in %s" % SCENARIOS_PATH)
		return scenarios
	if selected_names.is_empty():
		return scenarios
	var selected: Array[SimulationScenario] = []
	for scenario_name: String in selected_names.split(NAME_SEPARATOR, false):
		var scenario: SimulationScenario = _find_scenario(scenarios, scenario_name)
		if scenario == null:
			printerr("Unknown scenario: %s" % scenario_name)
			return []
		selected.append(scenario)
	return selected


func _find_scenario(scenarios: Array[SimulationScenario], scenario_name: String) -> SimulationScenario:
	for scenario: SimulationScenario in scenarios:
		if scenario.name == scenario_name:
			return scenario
	return null


func _are_scenarios_valid(scenarios: Array[SimulationScenario], base_config: BalancingConfig) -> bool:
	for scenario: SimulationScenario in scenarios:
		var invalid_key: String = scenario.find_invalid_override(base_config)
		if not invalid_key.is_empty():
			printerr("Scenario %s: invalid override %s" % [scenario.name, invalid_key])
			return false
	return true


func _log_progress(played_count: int, scenario_name: String, strategy_name: String, game_count: int, started_msec: int) -> void:
	if played_count % maxi(game_count / PROGRESS_LOG_COUNT, 1) == 0 or played_count == game_count:
		print("  %s / %s: %d/%d games, %.1f s elapsed" % [scenario_name, strategy_name, played_count, game_count, _get_elapsed_seconds(started_msec)])


func _get_elapsed_seconds(started_msec: int) -> float:
	return (Time.get_ticks_msec() - started_msec) / MILLISECONDS_PER_SECOND


## The process id and time make the name unique, so runs in parallel never overwrite each other.
func _write_csv(csv_text: String, scenario_label: String) -> int:
	var directory: String = ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	var ignore_path: String = directory.path_join(GODOT_IGNORE_FILE)
	if not FileAccess.file_exists(ignore_path):
		FileAccess.open(ignore_path, FileAccess.WRITE).close()
	var timestamp: String = Time.get_datetime_string_from_system().replace(":", "").replace("T", "-")
	var file_name: String = "simulation_%s_%d_%s.csv" % [timestamp, OS.get_process_id(), scenario_label.replace(NAME_SEPARATOR, "+")]
	var file := FileAccess.open(directory.path_join(file_name), FileAccess.WRITE)
	if file == null:
		printerr("Cannot write %s: %s" % [file_name, error_string(FileAccess.get_open_error())])
		return EXIT_FAILURE
	file.store_string(csv_text)
	file.close()
	print("CSV written: %s" % directory.path_join(file_name))
	return EXIT_SUCCESS
