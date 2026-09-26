extends Node2D

@export var distance_to_trigger: float = 100

@onready var cpu_particles_2d = $CPUParticles2D
@onready var playerpos = Globals.player
func _process(_delta):
	if playerpos.global_position.x > position.x:
		queue_free()
	var distance = position.x - playerpos.global_position.x
	if distance <= distance_to_trigger :
		cpu_particles_2d.show()
		Globals.air_boost = true
		await get_tree().create_timer(1).timeout
		queue_free()
