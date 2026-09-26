extends Node2D

# --- EXPORT VARIABLES (Configurable in the Godot Inspector per Level) ---
# Allows you to browse and select an audio file path uniquely for each level scene
@export_file("*.wav", "*.mp3", "*.ogg") var level_music_path: String

# Keeps track of which level this is for the leaderboard array (Level 1 = 0, Level 2 = 1, etc.)
@export var level_index: int = 0 

# --- ONREADY VARIABLES (Automatically links to layout nodes when scene loads) ---
@onready var timer_label = $Tiemr/Label
@onready var player = $Player
@onready var speed_bar = $Tiemr/SpeedUI/SpeedBar 
@onready var victory_screen = $VictoryScreen
@onready var victory_title = $VictoryScreen/CenterContainer/VBoxContainer/VictoryTitale
@onready var time_label = $VictoryScreen/CenterContainer/VBoxContainer/Timelabel
@onready var continue_button = $VictoryScreen/CenterContainer/VBoxContainer/ContinueButton

# --- GAMEPLAY VARIABLES ---
var time: float = 0.0
var is_timer_running: bool = true

func _ready() -> void:
	player.level_finished.connect(finish_level)
	
	print("Current Level Index: ", level_index, " | Loading Track: ", level_music_path)
	
	if level_music_path != "" and level_music_path != null:
		Globals.play_level_music(level_music_path)

func _process(_delta: float) -> void:
	# Tick the speedrun timer upward every frame while the level is active
	if is_timer_running:
		time += _delta
		
		# Sync the custom Speed UI bar to the current forward velocity of the player
		if player:
			speed_bar.value = player.velocity.x
			
	# Render the raw float value cleanly to 2 decimal places (e.g., "14.52")
	timer_label.text = "%.2f" % time
	


func finish_level() -> void:
	print("you win")
	is_timer_running = false
	
	# Freeze physics processing on the player so they stop moving during the victory screen
	player.set_deferred("process_mode", PROCESS_MODE_DISABLED)
	
	# Pass the final time score to Globals to check if it beats the previous low score record
	var is_new_record: bool = Globals.update_level_time(level_index, time)
	
	# --- TIME DISPLAY FORMATTING ---
	# Convert the running time float into standard Minute:Second:Millisecond format
	var minutes : int = int(time / 60.0)
	var seconds: int = int(time) % 60
	var milliseconds: int = int((time - int(time)) * 100)
	var formatted_time: String = "%02d:%02d:%02d" % [minutes, seconds, milliseconds]
	time_label.text = "TIME: " + formatted_time
	
	# --- VICTORY STATE HANDLING ---
	# Dynamically adjust the victory menu title depending on whether a highscore was set
	if is_new_record:
		victory_title.text = "NEW PERSONAL BEST!!"
		
		# Set the scale origin to the center of the text boundaries for the juice animation
		victory_title.pivot_offset = victory_title.size / 2.0
		
		# Create an infinite bouncing loop tween to make the "NEW PERSONAL BEST!!" text pop out visually
		var tween = create_tween().set_loops()
		tween.tween_property(victory_title, "scale", Vector2(1.15, 1.15), 0.25)
		tween.tween_property(victory_title, "scale", Vector2(1.0, 1.0), 0.25)
		
	else:
		# Fallback text if they completed the level but didn't beat their record
		victory_title.text = "LEVEL COMPLETED!"
		
	# Reveal the victory popup screen. The player can now review their score or hit continue!
	victory_screen.show()

func _input(event):
	if $VictoryScreen.visible and Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://menu.tscn")
		Globals.stop_music()
