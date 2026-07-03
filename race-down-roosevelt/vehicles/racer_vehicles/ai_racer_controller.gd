class_name AiRacerController extends Node3D

enum Intelligence {
	LOW,
	HIGH
}

@onready var _forward_raycast:RayCast3D = $RayCast3D

var racer_vehicle:RacerVehicle = null
var intelligence:Intelligence = Intelligence.LOW
var enabled:bool = false

# Gets how often the ai should be able to make a decision.
func _get_decision_cooldown() -> float:
	
	match (intelligence):
		Intelligence.LOW:
			return 0.5
		Intelligence.HIGH:
			return 0.1
		_:
			return 0.5

# Gets how far in front of the vehicle we should check for other vehicles.
func _get_raycast_distance() -> float:
	
	match (intelligence):
		Intelligence.LOW:
			return 10.0
		Intelligence.HIGH:
			return 5.0
		_:
			return 10.0

# Should only ever be called once.
func _start_decision_loop() -> void:
	
	while (true):
		
		await get_tree().create_timer(_get_decision_cooldown()).timeout
		
		if (!enabled):
			continue
		
		# Cannot make a decision if input is disabled.
		if (!racer_vehicle.input_enabled):
			continue
		
		# Try to avoid vehicles in front.
		_forward_raycast.target_position.z = _get_raycast_distance()
		var area_hit:Object = _forward_raycast.get_collider()
		if (area_hit is Node):
			var object_hit:Node = area_hit.get_parent()
			if (object_hit is RacerVehicle || object_hit is TrafficVehicle):
				if (racer_vehicle.is_left_lane_open()):
					racer_vehicle.switch_lanes_left()
				elif (racer_vehicle.is_right_lane_open()):
					racer_vehicle.switch_lanes_right()

func _ready() -> void:
	
	var parent:Node = self.get_parent()
	if (parent is RacerVehicle):
		racer_vehicle = parent
	else:
		RdrLogger.fatal(self, _ready.get_method() + " expects parent to be of type RacerVehicle.")
		return

	_start_decision_loop()
