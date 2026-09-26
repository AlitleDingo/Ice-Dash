extends AnimatableBody2D

@export var fall_speed: float = 1000.0

var is_falling: bool = false


func _physics_process(delta: float) -> void:
	if is_falling:
		position.y += fall_speed * delta

func _on_detector_body_entered(body: CharacterBody2D) -> void:
	# This 'is Player' check relies on 'class_name Player' being at the top of player.gd!
	if body is Player:
		$image.hide()
		$AnimatedSprite2D.show()
		$AnimatedSprite2D.play("default")
		await get_tree().create_timer(0.5).timeout

func _on_floor_collider_body_entered(body: Node2D) -> void:
	# 1. SAFETY: If the area is detecting its own parent body, do nothing!
	if body == self:
		return
		
	# 2. SAFETY: Ignore the player completely
	if body is Player:
		return
		
	# If it hits any other structural body (like TileMap or CollisionPolygon2D), delete it
	print("Ice platform safely hit the ground: ", body.name)
	queue_free()
