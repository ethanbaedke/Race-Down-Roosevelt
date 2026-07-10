class_name StreetLightRow extends Node3D

@onready var _left_light:Node3D = $StreetLightLeft
@onready var _left_light_light:SpotLight3D = $StreetLightLeft/SpotLight3D
@onready var _right_light:Node3D = $StreetLightRight
@onready var _right_light_light:SpotLight3D = $StreetLightRight/SpotLight3D

func set_lit(value:bool) -> void:
	
	if (value):
		if (_left_light.visible && _right_light.visible):
			_left_light_light.light_energy = 1.0
			await get_tree().create_timer(0.05).timeout
			_right_light_light.light_energy = 1.0
		elif (_left_light.visible):
			_left_light_light.light_energy = 1.0
		elif (_right_light.visible):
			_right_light_light.light_energy = 1.0
	else:
		if (_left_light.visible && _right_light.visible):
			_left_light_light.light_energy = 0.0
			await get_tree().create_timer(0.05).timeout
			_right_light_light.light_energy = 0.0
		elif (_left_light.visible):
			_left_light_light.light_energy = 0.0
		elif (_right_light.visible):
			_right_light_light.light_energy = 0.0

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
