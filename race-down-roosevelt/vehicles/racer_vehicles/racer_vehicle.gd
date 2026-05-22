class_name RacerVehicle extends Node3D

# These must be set when a racer vehicle is instantiated.
var race:Race = null
var racer:RacerObject = null

# 1-indexed, initialized as 0 since its an invalid lane number.
var lane_number:int = 0

const MAX_TOP_SPEED:int = 20
const MIN_TOP_SPEED:int = 15
const MAX_ACCELERATION:int = 10
const MIN_ACCELERATION:int = 5
const MAX_DURABILITY:int = 6
const MIN_DURABILITY:int = 1
const MAX_WEIGHT:int = 6
const MIN_WEIGHT:int = 1

@export_range(1, MAX_TOP_SPEED) var top_speed:int = 10
@export_range(1, MAX_ACCELERATION) var acceleration:int = 2
@export_range(1, MAX_DURABILITY) var durability:int = 1
@export_range(1, MAX_WEIGHT) var weight:int = 1

@onready var _collision_area:Area3D = $Area3D
@onready var _collision_shape:CollisionShape3D = $Area3D/CollisionShape3D

var speed:float = 0

# Just does a boost for now.
func use_powerup() -> void:
	
	speed += 5.0

func calculate_speed(delta:float) -> float:
	
	if (speed < top_speed):
		speed = min(speed + (acceleration * delta), top_speed)
	elif (speed > top_speed):
		speed = max(speed - (((MAX_WEIGHT + 1) - weight) * delta), top_speed)
	RdrLogger.spam_log(self, racer.name + " speed: " + str(speed))
	
	return speed

func try_switch_lanes(dir:int) -> bool:
	
	if (lane_number == 0):
		RdrLogger.error(self, "Lane number is not initialized for " + racer.name + ".")
		return false
	
	# Moving right.
	if (dir > 0):
		if (lane_number < race.NUM_LANES):
			if (is_right_lane_open()):
				lane_number += 1
				position.x -= race.LANE_SPACING
				return true
			else:
				RdrLogger.log(self, racer.name + " attempted to move right, but the lane was blocked.")
	# Moving left.
	else:
		if (lane_number > 1):
			if (is_left_lane_open()):
				lane_number -= 1
				position.x += race.LANE_SPACING
				return true
			else:
				RdrLogger.log(self, racer.name + " attempted to move left, but the lane was blocked.")
			
	return false

# Returns true if this vehicle can move left (nothing in the way).
func is_left_lane_open() -> bool:
	
	var hits:Array[Node3D] = _cast_vehicle_shape_to_position(_collision_area.global_position + Vector3(race.LANE_SPACING, 0.0, 0.0))
	return hits.size() == 0

# Returns true if this vehicle can move right (nothing in the way).
func is_right_lane_open() -> bool:
	
	var hits:Array[Node3D] = _cast_vehicle_shape_to_position(_collision_area.global_position - Vector3(race.LANE_SPACING, 0.0, 0.0))
	return hits.size() == 0

# The input position should be in world space.
func _cast_vehicle_shape_to_position(world_pos:Vector3) -> Array[Node3D]:
	
	var space_state:PhysicsDirectSpaceState3D = self.get_world_3d().direct_space_state

	var shape_params:PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	shape_params.shape = _collision_shape.shape
	# Using identity here since the shape shouldn't ever be rotated anyways.
	# If the shape ends up being rotated, this may need to be changed.
	shape_params.transform = Transform3D(Basis.IDENTITY, world_pos)
	shape_params.collision_mask = _collision_area.collision_mask
	shape_params.collide_with_areas = true
	shape_params.collide_with_bodies = false
	shape_params.exclude = [_collision_area.get_rid()]

	var results:Array[Dictionary] = space_state.intersect_shape(shape_params)

	var overlapping_nodes:Array[Node3D] = []
	for result in results:
		overlapping_nodes.append(result.collider)

	return overlapping_nodes

# Expects race to be set.
func _ready() -> void:
	
	if (race == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects race to be set.")
	if (racer == null):
		RdrLogger.warn(self, "Racer object not set. Creating default instance.")
		racer = RacerObject.new()

# These are used to get single inputs instead of a continuous stream.
var _left_key_active:bool = false
var _right_key_active:bool = false
var _powerup_key_active:bool = false
var _joystick_active:bool = false
var _powerup_button_active:bool = false

func _unhandled_input(event: InputEvent) -> void:
	
	if (event is InputEventKey):
		if (racer.device_index != -1):
			return
		# Keyboard movement.
		if (event.keycode == KEY_A || event.keycode == KEY_LEFT):
			if (!event.pressed):
				_left_key_active = false
			elif (!_left_key_active):
				_left_key_active = true
				try_switch_lanes(-1)
		elif (event.keycode == KEY_D || event.keycode == KEY_RIGHT):
			if (!event.pressed):
				_right_key_active = false
			elif (!_right_key_active):
				_right_key_active = true
				try_switch_lanes(1)
		# Keyboard powerup.
		elif (event.keycode == KEY_C || event.keycode == KEY_X):
			if (!event.pressed):
				_powerup_key_active = false
			elif (!_powerup_key_active):
				_powerup_key_active = true
				use_powerup()
				
	
	elif (event.device != racer.device_index):
		return
	
	# Gamepad movement.
	elif (event is InputEventJoypadMotion):
		if (event.axis != JOY_AXIS_LEFT_X):
			return
		var val:float = abs(event.axis_value)
		if (val >= 0.5 && !_joystick_active):
			try_switch_lanes(sign(event.axis_value))
			_joystick_active = true
		elif (val < 0.5):
			_joystick_active = false
	
	# Gamepad powerup.
	elif (event is InputEventJoypadButton):
		if (event.button_index == JOY_BUTTON_A || event.button_index == JOY_BUTTON_B || event.button_index == JOY_AXIS_LEFT_X || event.button_index == JOY_BUTTON_Y):
			if (!event.pressed):
				_powerup_button_active = false
			elif (!_powerup_button_active):
				_powerup_button_active = true
				use_powerup()
