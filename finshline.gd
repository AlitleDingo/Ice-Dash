extends TextureRect

@export var player: Player 

func _ready():
	player.finish_X = global_position.x 
	
