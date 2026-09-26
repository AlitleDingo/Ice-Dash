extends Node

var high_score: int = 0
const SAVE_FILE_PATH: String = "user://highscore.cfg"

func _ready() -> void:
	load_high_score()

func check_and_update_score(new_score: int) -> void:
	if new_score > high_score:
		high_score = new_score
		save_high_score()

func save_high_score() -> void:
	var config = ConfigFile.new()
	config.set_value("PlayerStats", "high_score", high_score)
	config.save(SAVE_FILE_PATH)

func load_high_score() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_FILE_PATH)
	
	# If the file exists and loads fine, pull the score
	if err == OK:
		high_score = config.get_value("PlayerStats", "high_score", 0)
