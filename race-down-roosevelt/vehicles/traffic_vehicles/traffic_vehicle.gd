class_name TrafficVehicle extends Node3D

@onready var collision_shape:CollisionShape3D = $Area3D/CollisionShape3D

func explode() -> void:
	
	# We don't destroy this object since the race will recycle it.
	disable_vehicle()

func disable_vehicle() -> void:
	
	collision_shape.disabled = true
	self.visible = false

func enable_vehicle() -> void:
	
	collision_shape.disabled = false
	self.visible = true
