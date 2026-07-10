class_name StreetLightRow extends Node3D

@onready var _left_light:Node3D = $StreetLightLeft
@onready var _right_light:Node3D = $StreetLightRight

func _ready() -> void:
	
	_right_light.position.x = randf_range(-16.0, -14.0)
	_left_light.position.x = randf_range(14.0, 16.0)
	
	var rand_disable:int = randi_range(0, 2)
	match (rand_disable):
		0:
			pass
		1:
			_left_light.visible = false
		2:
			_right_light.visible = false
