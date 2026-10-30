class_name SaveFixture
extends RefCounted

## Points the SaveManager autoload at a test file, so tests never read or write the player's save.

var _test_save_path: String
var _player_save_path: String


func _init(test_save_path: String) -> void:
	_test_save_path = test_save_path


func use_test_save() -> void:
	_player_save_path = SaveManager.save_path
	SaveManager.save_path = _test_save_path
	delete_save_files(_test_save_path)
	SaveManager.load_save()


## Reloading first drops the test changes still waiting to be written.
func restore_player_save() -> void:
	SaveManager.save_path = _player_save_path
	SaveManager.load_save()
	delete_save_files(_test_save_path)


static func delete_save_files(save_path: String) -> void:
	for path: String in [save_path, save_path + SaveManager.TEMPORARY_SUFFIX, save_path + SaveManager.BACKUP_SUFFIX]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
