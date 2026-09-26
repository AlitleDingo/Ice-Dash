extends Area2D


func _ready():
	$GPUParticles2D.emitting = false
	Globals.boost = false
	

func _on_body_entered(_body):
	Globals.boost = true
	$AudioStreamPlayer2D.play()
	$GPUParticles2D.emitting = true
	await get_tree().create_timer(0.5).timeout
	queue_free()
