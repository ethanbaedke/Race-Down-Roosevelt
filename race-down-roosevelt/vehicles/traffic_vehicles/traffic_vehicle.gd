class_name TrafficVehicle extends Node3D

@export var speed:int = 1

@onready var _collision_area:Area3D = $Area3D
@onready var _collision_shape:CollisionShape3D = $Area3D/CollisionShape3D

func explode() -> void:
	
	# We don't destroy this object since the race will recycle it.
	disable_vehicle()

func disable_vehicle() -> void:
	
	_collision_shape.disabled = true
	self.visible = false

func enable_vehicle() -> void:
	
	_collision_shape.disabled = false
	self.visible = true

# Called when this racer bumps a racer in front of it.
func _handle_traffic_vehicle_bump(other:TrafficVehicle) -> void:
	
	RdrLogger.log(self, "Traffic vehicle rear ended another traffic vehicle. Set to tailgate.")

	# Simply set the behind vehicles speed equal to the bumped vehicles speed and let it tailgate.
	self.speed = other.speed

func _collision_area_entered(area: Area3D) -> void:
	
	var parent:Node3D = area.get_parent_node_3d()
	if (parent is TrafficVehicle):
		# Ignore if this collision if this vehicle is in front of the vehicle it hit.
		# Traffic vehicle bumps are always handeled by the behind vehicle.
		if (area.global_position.z < _collision_area.global_position.z):
			return
		_handle_traffic_vehicle_bump(parent)

func _ready() -> void:
	
	_collision_area.area_entered.connect(_collision_area_entered)

func _process(delta: float) -> void:
	
	position.z -= speed * delta
