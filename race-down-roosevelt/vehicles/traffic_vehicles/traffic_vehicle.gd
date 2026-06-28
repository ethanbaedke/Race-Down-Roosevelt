class_name TrafficVehicle extends Node3D

@export var speed:int = 1

@export var _vehicle_model:Node3D = null

@onready var _explosion_effect_scene:PackedScene = preload("res://vehicles/traffic_vehicles/explosion_effect.tscn")

@onready var _collision_area:Area3D = $Area3D
@onready var _collision_shape:CollisionShape3D = $Area3D/CollisionShape3D

# Only set to false when vehicle in a state we don't want to cleanup during, such as exploding.
var available_for_cleanup:bool = true

# The actual speed used. This allows it to be modified without changing the original speed variable.
var _speed:float = speed

func explode() -> void:
	
	available_for_cleanup = false
	var effect:OneShotParticleEffect = _explosion_effect_scene.instantiate()
	effect.effect_finished.connect(func() -> void:
		available_for_cleanup = true)
	self.add_child(effect)
	
	# We don't destroy this object since the race will recycle it.
	disable_vehicle()

func disable_vehicle() -> void:
	
	# Stop the vehicle when disabled so it can fall behind quicker and be cleaned up sooner.
	_speed = 0
	_collision_shape.disabled = true
	_vehicle_model.visible = false

func enable_vehicle() -> void:
	
	_speed = speed
	_collision_shape.disabled = false
	_vehicle_model.visible = true

# Called when this racer bumps a racer in front of it.
func _handle_traffic_vehicle_bump(other:TrafficVehicle) -> void:
	
	RdrLogger.log(self, "Traffic vehicle rear ended another traffic vehicle. Set to tailgate.")

	# Simply set the behind vehicles speed equal to the bumped vehicles speed and let it tailgate.
	self._speed = other._speed
	
func _handle_racer_vehicle_bump(other:RacerVehicle) -> void:

	RdrLogger.log(self, "Traffic vehicle rear ended racer " + other.racer.name + ". Set to tailgate.")

	# Simply set the behind vehicles speed equal to the bumped vehicles speed and let it tailgate.
	self._speed = other.speed

func _collision_area_entered(area: Area3D) -> void:
	
	var parent:Node3D = area.get_parent_node_3d()
	# Handle hitting another traffic vehicle.
	if (parent is TrafficVehicle):
		# Ignore if this collision if this vehicle is in front of the vehicle it hit.
		# Traffic vehicle bumps are always handeled by the behind vehicle.
		if (area.global_position.z < _collision_area.global_position.z):
			return
		_handle_traffic_vehicle_bump(parent)
	if (parent is RacerVehicle):
		if (area.global_position.z < _collision_area.global_position.z):
			return
		_handle_racer_vehicle_bump(parent)
	# Handle hitting the finish line.
	elif (parent is RoadRowFinishLine):
		disable_vehicle()

func _ready() -> void:
	
	_collision_area.area_entered.connect(_collision_area_entered)

func _physics_process(delta: float) -> void:
	
	position.z += _speed * delta
