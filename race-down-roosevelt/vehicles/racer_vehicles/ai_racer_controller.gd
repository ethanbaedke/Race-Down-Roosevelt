class_name AiRacerController extends Node3D

enum Intelligence {
	LOW,
	HIGH
}

@onready var _forward_raycast:RayCast3D = $CenterCast
@onready var _left_raycast:RayCast3D = $LeftCast
@onready var _right_raycast:RayCast3D = $RightCast

var racer_vehicle:RacerVehicle = null
var intelligence:Intelligence = Intelligence.LOW
var enabled:bool = false

# Gets how often the ai should be able to make a decision.
func _get_decision_cooldown() -> float:
	
	match (intelligence):
		Intelligence.LOW:
			return 0.5
		Intelligence.HIGH:
			return 0.025
		_:
			return 0.5

# Gets how far in front of the vehicle we should check for other vehicles.
func _get_raycast_distance() -> float:
	
	match (intelligence):
		Intelligence.LOW:
			return 20.0
		Intelligence.HIGH:
			return 10.0
		_:
			return 20.0

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
				if (_try_move()):
					continue

func _try_move() -> bool:
	
	var ray_dist:float = _get_raycast_distance() * 2.0
	_left_raycast.target_position.z = ray_dist
	_right_raycast.target_position.z = ray_dist
	
	var left_open:bool = racer_vehicle.is_left_lane_open()
	var right_open:bool = racer_vehicle.is_right_lane_open()
	
	if (left_open && right_open):
	
		var left_hit:Object = _left_raycast.get_collider()
		var left_vehicle:Node3D = null
		if (left_hit is Node):
			var object_hit:Node = left_hit.get_parent()
			if (object_hit is RacerVehicle || object_hit is TrafficVehicle):
				left_vehicle = object_hit
		
		var right_hit:Object = _right_raycast.get_collider()
		var right_vehicle:Node3D = null
		if (right_hit is Node):
			var object_hit:Node = right_hit.get_parent()
			if (object_hit is RacerVehicle || object_hit is TrafficVehicle):
				right_vehicle = object_hit
		
		if (left_vehicle != null && right_vehicle != null):
			var left_dist:float = (left_vehicle.global_position - self.global_position).length_squared()
			var right_dist:float = (right_vehicle.global_position - self.global_position).length_squared()
			if (left_dist < right_dist):
				racer_vehicle.switch_lanes_right()
				return true
			elif (right_dist < left_dist):
				racer_vehicle.switch_lanes_left()
				return true
			else:
				var rand_dir:int = randi_range(0, 1)
				if (rand_dir == 0):
					racer_vehicle.switch_lanes_left()
					return true
				else:
					racer_vehicle.switch_lanes_right()
					return true
		elif (left_vehicle != null):
			racer_vehicle.switch_lanes_right()
			return true
		elif (right_vehicle != null):
			racer_vehicle.switch_lanes_left()
			return true
		else:
			var rand_dir:int = randi_range(0, 1)
			if (rand_dir == 0):
				racer_vehicle.switch_lanes_left()
				return true
			else:
				racer_vehicle.switch_lanes_right()
				return true
	
	elif (left_open):
		racer_vehicle.switch_lanes_left()
		return true
	
	elif(right_open):
		racer_vehicle.switch_lanes_right()
		return true
	
	else:
		return false

func _ready() -> void:
	
	var parent:Node = self.get_parent()
	if (parent is RacerVehicle):
		racer_vehicle = parent
	else:
		RdrLogger.fatal(self, _ready.get_method() + " expects parent to be of type RacerVehicle.")
		return

	_start_decision_loop()
