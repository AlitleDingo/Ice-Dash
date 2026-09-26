extends StaticBody2D

@export var fall_speed: float = 100.0

var is_falling: bool = false

func _ready() -> void:
	# Clean up signal connections via code
	$detector.body_entered.connect(_on_detector_body_entered)
	$"is on floor".body_entered.connect(_on_floor_collider_body_entered)

func _physics_process(delta: float) -> void:
	if is_falling:
		position.y += fall_speed * delta

func _on_detector_body_entered(body: Node2D) -> void:
	# This 'is Player' check relies on 'class_name Player' being at the top of player.gd!
	if body is Player and not is_falling:
		is_falling = true

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
