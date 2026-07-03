class_name AiRacerController extends Node3D

# How often this ai can make a decision.
const DECISION_COOLDOWN:float = 0.5

@onready var _forward_raycast:RayCast3D = $RayCast3D

var racer_vehicle:RacerVehicle = null

# Should only ever be called once.
func _start_decision_loop() -> void:
	
	while (true):
		
		return
		
		await get_tree().create_timer(DECISION_COOLDOWN).timeout
		
		# Cannot make a decision if input is disabled.
		if (!racer_vehicle.input_enabled):
			continue
		
		# Try to avoid vehicles in front.
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
