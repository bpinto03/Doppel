class_name SimulationScenario
extends RefCounted

## A name and balancing overrides, applied to a copy of the base config. Scenarios live in tools/simulation/scenarios.json.

## Not a BalancingConfig property: keeps only the spawn tiers whose threshold is at most this level.
const MAX_SPAWN_TIER_THRESHOLD_KEY: String = "max_spawn_tier_threshold"
const OVERRIDABLE_TYPES: Array[Variant.Type] = [TYPE_INT, TYPE_FLOAT, TYPE_BOOL]

var name: String
var overrides: Dictionary


func _init(scenario_name: String, scenario_overrides: Dictionary) -> void:
	name = scenario_name
	overrides = scenario_overrides


## Returns an empty list when the text is not a valid scenario file.
static func parse_scenarios(json_text: String) -> Array[SimulationScenario]:
	var scenarios: Array[SimulationScenario] = []
	var json := JSON.new()
	if json.parse(json_text) != OK:
		return scenarios
	var parsed: Variant = json.data
	if not parsed is Dictionary or not parsed.get("scenarios") is Array:
		return scenarios
	for entry: Variant in parsed["scenarios"]:
		if not entry is Dictionary or not entry.get("name") is String or not entry.get("overrides") is Dictionary:
			return []
		scenarios.append(SimulationScenario.new(entry["name"], entry["overrides"]))
	return scenarios


## Returns the first override key that the base config cannot take, or an empty string.
func find_invalid_override(base_config: BalancingConfig) -> String:
	for key: String in overrides:
		if key == MAX_SPAWN_TIER_THRESHOLD_KEY:
			if not _is_whole_number(overrides[key]):
				return key
		elif not key in base_config or not OVERRIDABLE_TYPES.has(typeof(base_config.get(key))):
			return key
		elif typeof(base_config.get(key)) == TYPE_INT and not _is_whole_number(overrides[key]):
			return key
	return ""


## Expects valid overrides (see find_invalid_override). The base config is never changed.
func create_config(base_config: BalancingConfig) -> BalancingConfig:
	var config: BalancingConfig = base_config.duplicate(true)
	for key: String in overrides:
		if key == MAX_SPAWN_TIER_THRESHOLD_KEY:
			config.spawn_weight_tiers = _filter_tiers(config.spawn_weight_tiers, int(overrides[key]))
		else:
			config.set(key, type_convert(overrides[key], typeof(base_config.get(key))))
	return config


static func _filter_tiers(tiers: Array[SpawnWeightTier], max_threshold: int) -> Array[SpawnWeightTier]:
	var kept_tiers: Array[SpawnWeightTier] = []
	for tier: SpawnWeightTier in tiers:
		if tier.min_highest_level <= max_threshold:
			kept_tiers.append(tier)
	return kept_tiers


## JSON reads every number as a float.
static func _is_whole_number(value: Variant) -> bool:
	return (value is float or value is int) and value == floorf(value)
