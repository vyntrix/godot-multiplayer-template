extends Node

var config = ConfigFile.new()
const SETTINGS_FILE_PATH = "user://settings.ini"

func _init() -> void:
	if !FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.set_value("settings", "microphone", "Default")
		config.save(SETTINGS_FILE_PATH)
	else:
		config.load(SETTINGS_FILE_PATH)

func save_microphone(mic: String) -> void:
	config.set_value("settings", "microphone", mic)
	config.save(SETTINGS_FILE_PATH)

func load_microphone() -> String:
	return config.get_value("settings", "microphone")
