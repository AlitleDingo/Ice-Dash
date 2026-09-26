extends Node

# Level 0 = Level 1, Level 1 = Level 2, etc.
var best_times: Array = [9999.0, 9999.0, 9999.0, 9999.0, 9999.0]
var music_player: AudioStreamPlayer
var boost: bool
var fade_tween: Tween # Track the active tween globally
var player: CharacterBody2D
@onready var air_boost: bool = false

const SAVE_PATH: String = "user://best_times.cfg"

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.volume_db = -5.0
	
	# Load saved times every time the game launches
	load_best_times()


func update_level_time(level_index: int, new_time: float) -> bool:
	if level_index >= 0 and level_index < best_times.size():
		if new_time < best_times[level_index]:
			best_times[level_index] = new_time
			save_best_times() # Save to file whenever a new best time is set!
			return true 
			
	return false 


func save_best_times() -> void:
	var config = ConfigFile.new()
	config.set_value("Records", "best_times", best_times)
	config.save(SAVE_PATH)


func load_best_times() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	# Only overwrite array if a valid save file exists
	if err == OK:
		best_times = config.get_value("Records", "best_times", [9999.0, 9999.0, 9999.0, 9999.0, 9999.0])


func play_level_music(music_file_path: String):
	# Kill any running fade out tweens instantly
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	# FIX: If Godot passes a secret 'uid://' path, convert it to a readable 'res://' path!
	if music_file_path.begins_with("uid://"):
		music_file_path = ResourceUID.get_id_path(ResourceUID.text_to_id(music_file_path))
	
	var new_song = load(music_file_path)
	
	# Now the comparison works perfectly because both sides are readable paths!
	if music_player.stream != new_song:
		print("Stopping old music and switching to: ", music_file_path)
		music_player.stop() 
		music_player.stream = new_song
		music_player.volume_db = -5.0
		music_player.play()
	elif not music_player.is_playing() or music_player.volume_db < -20.0:
		music_player.volume_db = -5.0
		music_player.play()


func stop_music():
	if music_player and music_player.is_playing():
		# Kill any lingering tweens before making a new one
		if fade_tween and fade_tween.is_valid():
			fade_tween.kill()
			
		fade_tween = create_tween()
		fade_tween.tween_property(music_player, "volume_db", -80.0, 1.5)
		fade_tween.tween_callback(_on_fade_completed)


func _on_fade_completed():
	if music_player and not fade_tween.is_valid():
		music_player.stop()
		music_player.stream = null
		music_player.volume_db = -5.0
