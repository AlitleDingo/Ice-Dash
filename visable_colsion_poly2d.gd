class_name Visable_collision_polygon_2d extends CollisionPolygon2D

@export var color: Color = Color.WHITE
# Called when the node enters the scene tree for the first time.
func _ready():
	var sprite = Polygon2D.new()
	add_child(sprite)
	sprite.polygon = polygon
	sprite.color = color
