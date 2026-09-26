extends CanvasLayer

var current_pause_selection : int = 0

# Grabs your exact VBoxContainer node child
@onready var pause_options = $pause_menu_ui/VBoxContainer
@onready var sound_player = $move_curser

func _ready():
	# Ensure the entire panel starts hidden when the game runs
	visible = false

func _input(event):
	# 1. Listen for Escape key to freeze/unfreeze
	if event.is_action_pressed("ui_cancel"):
		# Set input as handled so the escape command doesn't bleed through layouts
		get_viewport().set_input_as_handled()
		toggle_pause()
		if is_inside_tree() and $enter_menu:
			$enter_menu.play()
		return
	
	# 2. Only check for arrow key navigation if the menu is open
	if visible:
		if event.is_action_pressed("ui_down"):
			get_viewport().set_input_as_handled()
			current_pause_selection = (current_pause_selection + 1) % pause_options.get_child_count()
			update_pause_display()
			if is_inside_tree() and sound_player:
				sound_player.play() # Nesting inside the down-press prevents ghost playing!
				
		elif event.is_action_pressed("ui_up"):
			get_viewport().set_input_as_handled()
			current_pause_selection = (current_pause_selection - 1 + pause_options.get_child_count()) % pause_options.get_child_count()
			update_pause_display()
			if is_inside_tree() and sound_player:
				sound_player.play() # Nesting inside the up-press fixes your freezing up-key!
				
		elif event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			handle_pause_selection()
			if is_inside_tree() and $enter_menu:
				$enter_menu.play() # Plays the selection choice click sound cleanly!

func toggle_pause():
	get_tree().paused = !get_tree().paused
	visible = get_tree().paused # This hides/shows the entire CanvasLayer
	
	if visible:
		# Force the options container and its child labels to be visible
		pause_options.visible = true
		for child in pause_options.get_children():
			child.visible = true
			
		current_pause_selection = 0
		update_pause_display()

func update_pause_display():
	# Cleaned up into a single, cohesive optimization loop
	for i in range(pause_options.get_child_count()):
		var label = pause_options.get_child(i)
		
		if i == current_pause_selection:
			# Highlighted selection state properties
			label.scale = Vector2(1.3, 1.3)
			label.modulate = Color(1, 1, 1, 0.6) 
			label.set("theme_override_colors/font_color", Color(0.6, 0.6, 0.6))
		else:
			# Clear/Reset baseline option properties
			label.scale = Vector2(1.0, 1.0)
			label.modulate = Color(1, 1, 1, 1.0)
			label.set("theme_override_colors/font_color", Color(0, 0, 0))

func handle_pause_selection():
	match current_pause_selection:
		0: # "back"
			toggle_pause()
		1: # "Restart"
			get_tree().paused = false 
			get_tree().reload_current_scene()
		2: # "Exit_to_menu"
			get_tree().paused = false
			Globals.stop_music()
			await get_tree().create_timer(1.5).timeout
			get_tree().change_scene_to_file("res://UI/menu.tscn")
