extends Control

@onready var best_time_label = $Best_time
@onready var menu_options = $menu_options
@onready var sound_player = $curser_move

var current_selection : int = 0

func _ready():
	# Initialize the menu by highlighting the first item
	update_menu_display()
	$select.play()

func _input(event):
	if event.is_action_pressed("ui_down"):
		# Move down the list, loop back to 0 if we hit the end
		current_selection = (current_selection + 1) % menu_options.get_child_count()
		update_menu_display()
		if is_inside_tree() and sound_player:
			sound_player.play()
	elif event.is_action_pressed("ui_up"):
		# Move up the list, loop to the end if we go below 0
		current_selection = (current_selection - 1 + menu_options.get_child_count()) % menu_options.get_child_count()
		update_menu_display()
		if is_inside_tree() and sound_player:
			sound_player.play()
	elif event.is_action_pressed("ui_accept"): # Usually Enter or Space
		handle_selection()
		if is_inside_tree() and $select:
			$select.play()

func update_menu_display():
	# Loop through all labels and change their appearance
	for i in range(menu_options.get_child_count()):
		var label = menu_options.get_child(i)
		if i == current_selection:
			# Highlighted item style
			label.modulate = Color(1, 1, 0) # Yellow text
		else:
			# Normal item style
			label.modulate = Color(1, 1, 1) # White text
			
	# 1. Grab the raw float number from Globals based on selection (0, 1, or 2)
	var raw_time: float = Globals.best_times[current_selection]
	
	# 2. Extract minutes, whole seconds, and 2-digit milliseconds out of the raw float
	var minutes = float(raw_time) / 60
	var seconds: int = int(raw_time) % 60
	var milliseconds: int = int((raw_time - int(raw_time)) * 100)
	
	# 3. Format those numbers cleanly together into standard racing text
	best_time_label.text = "Best Time: %02d:%02d:%02d" % [minutes, seconds, milliseconds]

func handle_selection():
	match current_selection:
		0:
			get_tree().change_scene_to_file("res://level_1.tscn")
		1:
			get_tree().change_scene_to_file("res://level_2.tscn")
		2:
			get_tree().change_scene_to_file("res://level_3.tscn")
		3:
			get_tree().quit()
		4: 
			get_tree().change_scene_to_file("res://how_to_play.tscn")
