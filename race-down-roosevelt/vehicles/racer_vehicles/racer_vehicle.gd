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

@onready var ai_controller:AiRacerController = $AiRacerController

@onready var _collision_area:Area3D = $Area3D
@onready var _collision_shape:CollisionShape3D = $Area3D/CollisionShape3D
@onready var _model_controller:VehicleModelController = $VehicleModelController

var top_speed:float = 0.0
var acceleration:float = 0.0
var durability:float = 0.0
var weight:float = 0.0

var speed:float = 0
var input_enabled:bool = false

var _hud:RacePlayerHud = null

func set_camera_controller(controller:CameraController) -> void:
	
	_model_controller.set_camera_controller(controller)

func set_hud(hud:RacePlayerHud) -> void:
	
	_hud = hud
	_hud.update_item(_held_item)

# Important for the camera initializing at the correct position.
func set_initial_position(global_pos:Vector3) -> void:
	
	self.global_position = global_pos
	_model_controller.global_position = global_pos

func calculate_speed(delta:float) -> float:
	
	if (speed < top_speed):
		speed = min(speed + (acceleration * delta), top_speed)
	elif (speed > top_speed):
		speed = max(speed - (((MAX_WEIGHT + 1) - weight) * delta), top_speed)
	RdrLogger.spam_log(self, racer.profile.name + " speed: " + str(speed))
	
	return speed

func boost() -> void:
	
	speed += 5.0

func try_switch_lanes(dir:int) -> bool:
	
	if (lane_number == 0):
		RdrLogger.error(self, "Lane number is not initialized for " + racer.profile.name + ".")
		return false
	
	# Moving right.
	if (dir > 0):
		if (is_right_lane_open()):
			switch_lanes_right()
			return true
		else:
			RdrLogger.log(self, racer.profile.name + " attempted to move right, but the lane was blocked.")
			_model_controller.pulse_right()
	# Moving left.
	else:
		if (is_left_lane_open()):
			switch_lanes_left()
			return true
		else:
			RdrLogger.log(self, racer.profile.name + " attempted to move left, but the lane was blocked.")
			_model_controller.pulse_left()
	return false

# Returns true if this vehicle can move left (nothing in the way).
func is_left_lane_open() -> bool:
	
	if (lane_number <= 1):
		return false
	
	var hits:Array[Node3D] = _cast_vehicle_shape_to_position(_collision_area.global_position + Vector3(race.LANE_SPACING, 0.0, 0.0))
	var num_obstructions:int = 0
	for node:Node3D in hits:
		var parent:Node = node.get_parent()
		if (parent is TrafficVehicle):
			if (_invincible):
				continue
		num_obstructions += 1
	return num_obstructions == 0

func switch_lanes_left() -> void:
	
	lane_number -= 1
	position.x += race.LANE_SPACING

# Returns true if this vehicle can move right (nothing in the way).
func is_right_lane_open() -> bool:
	
	if (lane_number >= race.NUM_LANES):
		return false
	
	var hits:Array[Node3D] = _cast_vehicle_shape_to_position(_collision_area.global_position - Vector3(race.LANE_SPACING, 0.0, 0.0))
	var num_obstructions:int = 0
	for node:Node3D in hits:
		var parent:Node = node.get_parent()
		if (parent is TrafficVehicle):
			if (_invincible):
				continue
		num_obstructions += 1
	return num_obstructions == 0

func switch_lanes_right() -> void:
	
	lane_number += 1
	position.x -= race.LANE_SPACING

# The input position should be in world space.
func _cast_vehicle_shape_to_position(world_pos:Vector3) -> Array[Node3D]:
	
	var space_state:PhysicsDirectSpaceState3D = self.get_world_3d().direct_space_state

	var shape_params:PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	shape_params.shape = _collision_shape.shape
	# Using identity here since the shape shouldn't ever be rotated anyways.
	# If the shape ends up being rotated, this may need to be changed.
	shape_params.transform = Transform3D(Basis.IDENTITY, world_pos)
	shape_params.collision_mask = 1
	shape_params.collide_with_areas = true
	shape_params.collide_with_bodies = false
	shape_params.exclude = [_collision_area.get_rid()]

	var results:Array[Dictionary] = space_state.intersect_shape(shape_params)

	var overlapping_nodes:Array[Node3D] = []
	for result in results:
		overlapping_nodes.append(result.collider)

	return overlapping_nodes

# Called when this racer bumps a racer in front of it.
func _handle_racer_bump(other:RacerVehicle) -> void:
	
	RdrLogger.log(self, self.racer.profile.name + " bumped " + other.racer.profile.name + ".")
	
	var m1:float = self.weight
	var m2:float = other.weight
	var s1:float = self.speed
	var s2:float = other.speed

	# v1' = ((m1 - m2) * v1 + 2 * m2 * v2) / (m1 + m2)
	# v2' = ((m2 - m1) * v2 + 2 * m1 * v1) / (m1 + m2)
	var total_weight:float = m1 + m2
	var new_s1:float = ((m1 - m2) * s1 + 2.0 * m2 * s2) / total_weight
	var new_s2:float = ((m2 - m1) * s2 + 2.0 * m1 * s1) / total_weight
	
	# The minimum amount of speed the reciever must have over the hitter after collision.
	# This removes sticking, which can cause vehicles to clip inside each other.
	const MIN_SPEED_DIFF:float = 3.0
	var diff:float = new_s2 - new_s1
	if (diff < MIN_SPEED_DIFF):
		# The speed that needs to be added/subtracted from each racers final speed to ensure the minimum speed difference.
		var half_dist_to_min:float = (MIN_SPEED_DIFF - diff) * 0.5
		new_s1 -= half_dist_to_min
		new_s2 += half_dist_to_min
		
	self.speed = new_s1
	other.speed = new_s2

func _handle_traffic_vehicle_hit(vehicle:TrafficVehicle) -> void:
	
	if (vehicle.global_position.z < self.global_position.z):
		return
	
	RdrLogger.log(self, racer.profile.name + " hit a traffic vehicle.")
	
	vehicle.explode()
	
	# Only reduce our speed if we are not invincible.
	if (!_invincible):
		# Reduce speed based on durability (higher = more maintained).
		# Add one to max durability here to ensure vehicles with max durability still slow down some.
		speed = speed * ((durability as float) / (MAX_DURABILITY + 1))

func _collision_area_entered(area: Area3D) -> void:
	
	# Grab the parent of the area 2d, and handle collision based on its type.
	var parent:Node3D = area.get_parent_node_3d()
	
	# Handle bumping other racers.
	if (parent is RacerVehicle):
		# Ignore if this racer is in front of the racer is hit.
		# Racer bumps are always handeled by the behind vehicle.
		if (area.global_position.z < _collision_area.global_position.z):
			return
		_handle_racer_bump(parent)
		
	# Handle collision with traffic vehicles.
	elif (parent is TrafficVehicle):
		_handle_traffic_vehicle_hit(parent)

#region Items

const INVINCIBILITY_ITEM_TIME:float = 5.0
const AI_ITEM_TIME:float = 5.0
const AI_ITEM_MAX_SPEED_INCREASE:float = 10.0
const SPEED_ITEM_TIME:float = 5.0
const SPEED_ITEM_TOP_SPEED_INCREASE:float = 30.0
const SPEED_ITEM_ACCELERATION_INCREASE:float = 10.0

var _held_item:ItemData = null
var _total_item_time:float = 0.0
var _current_item_time:float = 0.0

var _invincible:bool = false

func try_give_item(data:ItemData) -> bool:
	
	if (_held_item != null):
		return false
		
	_held_item = data
	if (_hud != null):
		_hud.update_item(data)
	return true
	
func try_use_item() -> bool:
	
	if (_held_item == null):
		return false
	
	match (_held_item.item_type):
		ItemData.ItemType.BOOST:
			_activate_boost_item()
		ItemData.ItemType.INVINCIBILITY:
			_activate_invincibility_item()
		ItemData.ItemType.AI:
			_activate_ai_item()
		ItemData.ItemType.SPEED:
			_activate_speed_item()
	
	if (_hud != null):
		_hud.update_item(_held_item)
	return true

func _set_item_time(time:float) -> void:
	
	_total_item_time = time
	_current_item_time = time

func _handle_timed_item_finished() -> void:
	
	if (_held_item == null):
		RdrLogger.error(self, "timed item finished but held item is null.")
		return
	
	match (_held_item.item_type):
		ItemData.ItemType.BOOST:
			pass
		ItemData.ItemType.INVINCIBILITY:
			_handle_invincibility_item_finished()
		ItemData.ItemType.AI:
			_handle_ai_item_finished()
		ItemData.ItemType.SPEED:
			_handle_speed_item_finished()
	
	_held_item = null
	if (_hud != null):
		_hud.update_item(_held_item)

func _activate_boost_item() -> void:
	
	boost()
	boost()
	boost()
	_held_item = null

func _activate_invincibility_item() -> void:
	
	_invincible = true
	_set_item_time(INVINCIBILITY_ITEM_TIME)

func _handle_invincibility_item_finished() -> void:
	
	_invincible = false

func _activate_ai_item() -> void:
	
	_set_item_time(AI_ITEM_TIME)
	top_speed += AI_ITEM_MAX_SPEED_INCREASE
	boost()
	ai_controller.intelligence = AiRacerController.Intelligence.HIGH
	ai_controller.enabled = true

func _handle_ai_item_finished() -> void:
	
	# Only disable the ai racer if we are a player. This keeps ai racers from having their ai turned off after using this item.
	if (racer.device_index != -2):
		ai_controller.enabled = false
	
	ai_controller.intelligence = AiRacerController.Intelligence.LOW
	top_speed -= AI_ITEM_MAX_SPEED_INCREASE

func _activate_speed_item() -> void:
	
	_set_item_time(SPEED_ITEM_TIME)
	top_speed += SPEED_ITEM_TOP_SPEED_INCREASE
	acceleration += SPEED_ITEM_ACCELERATION_INCREASE

func _handle_speed_item_finished() -> void:
	
	top_speed -= SPEED_ITEM_TOP_SPEED_INCREASE
	acceleration -= SPEED_ITEM_ACCELERATION_INCREASE

#endregion

# Expects race to be set.
func _ready() -> void:
	
	if (race == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects race to be set.")
	if (racer == null):
		RdrLogger.warn(self, "Racer object not set. Creating default instance.")
		racer = RacerObject.new()
	
	top_speed = racer.vehicle_data.top_speed
	acceleration = racer.vehicle_data.acceleration
	durability = racer.vehicle_data.durability
	weight = racer.vehicle_data.weight
	
	_collision_area.area_entered.connect(_collision_area_entered)

func _process(delta: float) -> void:
	
	if (_current_item_time > 0):
		_current_item_time -= delta
		if (_current_item_time <= 0):
			_current_item_time = 0
			_handle_timed_item_finished()
	if (_hud != null):
		_hud.update_item_time(_current_item_time, _total_item_time)

# These are used to get single inputs instead of a continuous stream.
var _left_key_active:bool = false
var _right_key_active:bool = false
var _powerup_key_active:bool = false
var _joystick_active:bool = false
var _powerup_button_active:bool = false

func _unhandled_input(event: InputEvent) -> void:
	
	if (ai_controller.enabled):
		return
	
	if (!input_enabled):
		return
	
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
				try_use_item()
	
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
				try_use_item()
