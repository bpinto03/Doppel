extends GutTest

## Paper and Night render as before shop theme changes: every value of tests/data/theme_snapshot_*.json is unchanged.
## New theme types or items may be added; none of the saved ones may change or disappear.

const SNAPSHOT_PALETTE_NAMES: Array[String] = ["paper", "night"]


func test_paper_and_night_keep_every_saved_value() -> void:
	for palette_name: String in SNAPSHOT_PALETTE_NAMES:
		var saved: Dictionary = ThemeSnapshotFixture.load_saved(palette_name)
		var current: Dictionary[String, String] = ThemeSnapshotFixture.build(Settings.THEME_CATALOG.find_entry(StringName(palette_name)).palette)
		assert_gt(saved.size(), 0, palette_name)
		var changed_keys: Array[String] = []
		for key: String in saved:
			if current.get(key, "<missing>") != saved[key]:
				changed_keys.append("%s: %s -> %s" % [key, saved[key], current.get(key, "<missing>")])
		assert_eq(changed_keys, [] as Array[String], palette_name)
