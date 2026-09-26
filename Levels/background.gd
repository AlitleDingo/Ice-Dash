extends Node2D

@export var shift_time: float = 10.0      # Total time for a full day/night cycle
@export var fade_time: float = 2.0       # How long the fade transition takes
@export var night_time_color: Color = Color(0.1, 0.1, 0.2)
@export var day_time_color: Color = Color(1.0, 1.0, 1.0)

var time: float
var current_color: Color

func _ready():
	# Start the level matching the initial night color
	current_color = night_time_color
	update_color(current_color)

func _process(delta):
	time += delta
	
	# 1. Determine what the target color SHOULD be based on time
	var target_color: Color
	if time >= shift_time / 2.0:
		target_color = day_time_color
	else:
		target_color = night_time_color
		
	# 2. Smoothly move the current color toward the target color using lerp
	# Delta * (1.0 / fade_time) ensures the transition takes exactly 'fade_time' seconds
	var weight = delta * (1.0 / fade_time)
	current_color = current_color.lerp(target_color, weight)
	
	# 3. Apply the smoothly faded color to your backgrounds
	update_color(current_color)
	
	# Reset cycle
	if time > shift_time: 
		time = 0.0
	
func update_color(color):
	$sky/sky.self_modulate = color
	$clouds_bg/clouds_bg.self_modulate = color
	$clouds_mg_3/clouds_mg_3.self_modulate = color
	$clouds_mg_2/clounds_mg_2.self_modulate = color
	$clouds_mg_1/clounds_mg_1.self_modulate = color
	$mountains/glacial_mountains.self_modulate = color
	$"below themountains/glacial_mountains".self_modulate = color
