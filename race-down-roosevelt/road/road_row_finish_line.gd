class_name RoadRowFinishLine extends RoadRow

signal racer_crossed(racer:RacerVehicle)

@onready var _collision_area:Area3D = $Area3D
@onready var _collision_shape:CollisionShape3D = $Area3D/CollisionShape3D

func _on_collision_area_entered(area:Area3D) -> void:
	
	var parent:Node3D = area.get_parent_node_3d()
	if (parent is RacerVehicle):
		racer_crossed.emit(parent)
		_collision_shape.disabled = true

func _ready() -> void:
	
	_collision_area.area_entered.connect(_on_collision_area_entered)
