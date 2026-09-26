class_name Player extends CharacterBody2D

# --- Signals ---
signal level_finished()

# --- Export Variables ---
@export_category("Horizontal Movement")
@export var acceleration = 150
@export var max_speed = 290
@export var landing_acceleration = 2250.0
@export var gem_boost: float = 30000

@export_category("Gravity")
@export var up_gravity: float = 250
@export_category("horizontal movement")
@export var down_gravity: float = 500

@export_category("Jumping")
@export var jump_force = 180
@export var unjump_force = 25
@export var air_jump_speed_reduce = 1500
@export var coyote_time_amount: float = 0.20
@export var air_boost_amount: float = 600

@export_category("Friction")
@export var friction = 200
@export var air_friction = 60.0

@export_category("Camera")
@export var min_zoom_amount = 0.9
@export var max_zoom_amount = 1.5


@export_category("Death System")
@export var death_y_threshold: float = 800.0
var stuck_time: float = 0.0

# --- Node References ---
@onready var anchor = $Anchor
@onready var sprite_2d = $Anchor/Sprite2D
@onready var camera_2d = $Camera2D
@onready var ray_cast_2d = $RayCast2D
@onready var gpu_particles_2d = $GPUParticles2D
@onready var jump_sound = $JumpSound
@onready var double_jump = $DoubleJump

# --- Internal State Variables ---
var coyote_time = 0.0
var target_tilt: float = 0.0
var previous_velocity: Vector2 = Vector2.ZERO
var air_jump = true
var finish_X = -1
var is_dead: bool = false


func _ready() -> void:
	# Initialize camera properties on start
	camera_2d.zoom = Vector2.ONE * max_zoom_amount
	sprite_2d.show()
	$AudioStreamPlayer2D.play()
	#asign the globak player to thwe player
	Globals.player = self



func _physics_process(delta: float) -> void:
	# Handle the isolated death behavior if player has fallen out
	if is_dead:
		_process_death_sequence(delta)
		return
	air_boost(delta)
	# Enable snow particles under normal conditions
	gpu_particles_2d.emitting = true
	call_deferred("check_for_finish_line")
	
	coyote_time += delta
	
	# Evaluate environmental state and process corresponding physics
	if is_on_floor() or coyote_time <= coyote_time_amount:
		_handle_grounded_state(delta)
	else:
		_handle_airborne_state(delta)
	#boosted if colided with gem
	recive_gems(delta)
	# Cache tracking flags before physics execution
	var was_on_floor = is_on_floor()
	previous_velocity = velocity
	
	move_and_slide()
	
	if velocity.x < 5.0 and (is_on_wall() or is_on_floor()):
		stuck_time += delta
		if stuck_time > 0.15: # Snappy trigger when stopped cold
			trigger_wall_crash()
	else:
		stuck_time = 0.0

	# Post-movement structural updates
	_handle_coyote_time_triggers(was_on_floor)
	_handle_landing_impact(delta)
	_apply_visual_rotations_and_squash()
	_update_camera_tracking()
	_check_abyss_threshold()


# --- Physics & State Modules ---

func _handle_grounded_state(delta: float) -> void:
	air_jump = true
	target_tilt = 0
	
	# Execute ground jump
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = -jump_force
		jump_sound.play() 
	
	# Apply ground acceleration or friction based on current limits
	if velocity.x <= max_speed:
		velocity.x = move_toward(velocity.x, max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, max_speed, friction * delta)


func _handle_airborne_state(delta: float) -> void:
	gpu_particles_2d.emitting = false
	target_tilt = clamp(velocity.y / 4.0, -30.0, 30.0)
			
	# Apply standard horizontal drag in mid-air
	velocity.x = move_toward(velocity.x, 0, air_friction * delta)
	
	# Execute double jump / mid-air flip
	if Input.is_action_just_pressed("ui_accept") and air_jump:
		velocity.y = -jump_force
		velocity.x -= air_jump_speed_reduce * delta
		air_jump = false
		double_jump.play()
		
		var tween = create_tween()
		tween.tween_property(sprite_2d, "rotation_degrees", 0.0, 0.4).from(360 + sprite_2d.rotation_degrees)
	
	# Apply variable jump height mechanic
	if Input.is_action_just_released("ui_accept"):
		velocity.y = unjump_force
	
	# Apply downward or upward gravity scales based on trajectory
	if velocity.y > 0:
		velocity.y += down_gravity * delta
	else:
		velocity.y += up_gravity * delta


func _handle_coyote_time_triggers(was_on_floor: bool) -> void:
	var just_left_ledge = was_on_floor and not is_on_floor() and velocity.y >= 0
	if just_left_ledge:
		coyote_time = 0


func _handle_landing_impact(delta: float) -> void:
	# Provide a speed burst and compression effect upon landing flat from a downward arc
	if velocity.y == 0 and previous_velocity.y > 5:
		velocity.x += landing_acceleration * delta
		anchor.scale = Vector2(1.3, 0.8)


# --- Visuals & Camera Modules ---

func _apply_visual_rotations_and_squash() -> void:
	# Smoothly interpolate rotation toward target tilt and return squash/stretch scale to default
	sprite_2d.rotation_degrees = lerp(sprite_2d.rotation_degrees, target_tilt, 0.2)
	anchor.scale = anchor.scale.lerp(Vector2.ONE, 0.05)


func _update_camera_tracking() -> void:
	# 1. Keep the camera node locked flat to the player
	camera_2d.position = Vector2.ZERO
	
	# 2. Track vertical offset relative to terrain layout via raycast measurements
	var y_offset_target: float = clamp(ray_cast_2d.get_collision_point().y - global_position.y, -16, 80)
	camera_2d.offset.y = lerp(camera_2d.offset.y, y_offset_target, 0.04)
	
	# 3. Adjust horizontal view ahead depending on forward velocity
	var x_offset_target: float = clamp(velocity.x, -125, 128)
	camera_2d.offset.x = lerp(camera_2d.offset.x, x_offset_target, 0.04)
	
	# 4. Dynamically pull back zoom as speed increases to broaden field of view
	var zoom_target_amount: float = clamp(max_zoom_amount - (velocity.x / 150), min_zoom_amount, max_zoom_amount)
	var zoom_target: Vector2 = Vector2(zoom_target_amount, zoom_target_amount)
	camera_2d.zoom = camera_2d.zoom.lerp(zoom_target, 0.02)

# --- Progression & Condition Systems ---

func check_for_finish_line() -> void:
	if global_position.x > finish_X and finish_X != -1:
		level_finished.emit()
		gpu_particles_2d.emitting = false
		gpu_particles_2d.hide()



# --- Death Sequence System ---

func _check_abyss_threshold() -> void:
	# Evaluate if player position drops past designated absolute lowest boundary line
	if global_position.y > death_y_threshold:
		trigger_death()
	


func trigger_death() -> void:
	if is_dead:
		return
	is_dead = true
	
	# Lock gameplay loop timing values on the parent level structure
	if get_parent().get("is_timer_running") != null:
		get_parent().is_timer_running = false
	
	# Detach the camera from player tree node hierarchy to lock its position in spatial coordinates
	if camera_2d:
		var current_camera_global_pos = camera_2d.global_position
		remove_child(camera_2d)
		get_parent().add_child(camera_2d)
		camera_2d.global_position = current_camera_global_pos

	# Initiate tumbling downward momentum vectors
	velocity.y = 200.0
	velocity.x = velocity.x * 0.2


func _process_death_sequence(delta: float) -> void:
	# Animate spin-out and apply baseline gravity acceleration downward
	sprite_2d.rotation_degrees += 720.0 * delta 
	velocity.y += 1200.0 * delta
	move_and_slide()
	
	# Track viewport boundary properties to evaluate when to run transition sequences
	if camera_2d:
		var viewport_height = get_viewport_rect().size.y
		var current_zoom = camera_2d.zoom.y
		
		# Compute physical boundary line location based on current camera position and zoom limits
		var screen_bottom = camera_2d.global_position.y + ((viewport_height / 2) / current_zoom)
		
		# Shift scenes once character clears the lower framing limits plus margin
		if global_position.y > screen_bottom + 64:
			get_tree().change_scene_to_file("res://UI/menu.tscn")
			
			
func recive_gems(delta):
	if Globals.boost == true:
		velocity.x += gem_boost * delta
		Globals.boost = false

func trigger_wall_crash() -> void:
	if is_dead:
		return
	is_dead = true

	# Stop the penguin from processing any more inputs or movement loops
	set_deferred("process_mode", PROCESS_MODE_DISABLED)
	
	# Stop the timer on the level UI
	if get_parent().get("is_timer_running") != null:
		get_parent().is_timer_running = false
		
	# Cleanly fade out the music exactly once
	
	# Optional: You can make the penguin flash red or play a crash animation here!
	sprite_2d.modulate = Color(1, 0, 0) 
	
	# Wait for the player to see the crash, then drop back to menu
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file("res://UI/menu.tscn")

func air_boost(delta):
	if Globals.air_boost:
		velocity.y -= air_boost_amount * delta
		velocity.x += air_boost_amount/1000
		Globals.air_boost = false
