class_name BoostPad extends Node3D

@onready var _collision_area:Area3D = $Area3D
@onready var _boost_player:AudioStreamPlayer3D = $BoostPlayer

func _ready() -> void:
	
	_collision_area.area_entered.connect(_on_collision_area_entered)

func _on_collision_area_entered(area:Area3D) -> void:

	var parent:Node3D = area.get_parent()
	if (parent is RacerVehicle):
		parent.boost(15.0)
		AudioSystem3D.play_source(_boost_player)
