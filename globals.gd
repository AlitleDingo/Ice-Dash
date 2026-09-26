extends Node

# Level 0 = Level 1, Level 1 = Level 2, etc.
var best_times: Array = [9999.0, 9999.0, 9999.0, 9999.0, 9999.0]
var boost: bool
var player: CharacterBody2D
@onready var air_boost: bool = false

const SAVE_PATH: String = "user://best_times.cfg"

func _ready():
	load_best_times()

func update_level_time(level_index: int, new_time: float) -> bool:
	if level_index >= 0 and level_index < best_times.size():
		if new_time < best_times[level_index]:
			best_times[level_index] = new_time
			save_best_times()
			return true 
	return false 

func save_best_times() -> void:
	var config = ConfigFile.new()
	config.set_value("Records", "best_times", best_times)
	config.save(SAVE_PATH)

func load_best_times() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		best_times = config.get_value("Records", "best_times", [9999.0, 9999.0, 9999.0, 9999.0, 9999.0])
