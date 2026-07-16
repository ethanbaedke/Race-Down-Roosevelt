class_name RacerVehicle extends Node3D

# These must be set when a racer vehicle is instantiated.
var race:Race = null
var racer:RacerObject = null

# 1-indexed, initialized as 0 since its an invalid lane number.
var lane_number:int = 0

const MAX_TOP_SPEED:int = 30
const MIN_TOP_SPEED:int = 26
const MAX_ACCELERATION:int = 15
const MIN_ACCELERATION:int = 11
const MAX_DURABILITY:int = 5
const MIN_DURABILITY:int = 1
const MAX_WEIGHT:int = 5
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
# Set on ready since we have to search the tree for it.
var nameplate:Nameplate = null

var _hud:RacePlayerHud = null

# Reparents a world pickup above this object so it moves with it during its pickup animation.
func give_world_pickup(pickup:Node3D) -> void:
	
	pickup.reparent.call_deferred(_model_controller)
	# Must set global position here since it will not be a child of the model controller until the end of the frame.
	pickup.global_position = _model_controller.global_position + (Vector3.UP * 0.5)

func set_camera_controller(controller:CameraController) -> void:
	
	_model_controller.set_camera_controller(controller)

func set_hud(hud:RacePlayerHud) -> void:
	
	_hud = hud
	_hud.update_item(_held_item)
	_hud.update_name(racer.profile.name)
	_hud.update_device_type(Globals.device_type_from_index(racer.device_index))
	_hud.initialize_progress_tracker(race, self)

# Important for the camera initializing at the correct position.
func set_initial_position(global_pos:Vector3) -> void:
	
	self.global_position = global_pos
	_model_controller.global_position = global_pos

func calculate_speed(delta:float) -> float:
	
	if (speed < top_speed):
		speed = min(speed + (acceleration * delta), top_speed)
	elif (speed > top_speed):
		var new_speed:float = max(speed - (((((MAX_WEIGHT + 1) - weight) * 0.25) + 0.75) * (speed - top_speed) * delta), top_speed)
		if (_in_air):
			# Slow down 1/4 the regular amount in the air.
			speed = lerp(new_speed, speed, 0.75)
		else:
			speed = new_speed
	RdrLogger.spam_log(self, racer.profile.name + " speed: " + str(speed))
	
	return speed

func boost(force:float) -> void:
	
	speed += force

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
		speed = speed * ((durability as float) / (MAX_DURABILITY * 1.5))
		# Spin the racers nameplate.
		nameplate.spin()

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
const INVINCIBILITY_MAX_SPEED_INCREASE:float = 10.0
const AI_ITEM_TIME:float = 10.0
const AI_ITEM_MAX_SPEED_INCREASE:float = 20.0
const AI_ITEM_ACCELERATION_INCREASE:float = 80.0
const SPEED_ITEM_TIME:float = 7.5
const SPEED_ITEM_TOP_SPEED_INCREASE:float = 40.0
const SPEED_ITEM_ACCELERATION_INCREASE:float = 20.0

const MAX_GAS:int = 4
const JUMP_TIME:float = 2.0
const JUMP_HEIGHT:float = 5.0

@onready var _ai_item_activate_player:AudioStreamPlayer3D = $AIActivatePlayer
@onready var _invincibility_item_activate_player:AudioStreamPlayer3D = $InvincibilityActivatePlayer
@onready var _speed_item_activate_player:AudioStreamPlayer3D = $SpeedActivatePlayer
@onready var _boost_item_activate_player:AudioStreamPlayer3D = $BoostActivatePlayer
@onready var _jump_activate_player:AudioStreamPlayer3D = $JumpActivatePlayer

var _held_item:ItemData = null
var _total_item_time:float = 0.0
var _current_item_time:float = 0.0

var _invincible:bool = false

var _current_gas:int = 0
var _jump_initial_y:float = 0.0
var _current_jump_time:float = 0.0
var _in_air:bool = false

func try_give_item() -> bool:
	
	if (_held_item != null):
		return false
	
	var current_place:int = race.get_vehicle_place(self)
	var data:ItemData = Globals.get_item_for_place(current_place)
	_held_item = data
	if (_hud != null):
		_hud.update_item(data)
	return true
	
func try_use_item() -> bool:
	
	if (_held_item == null):
		return false
	
	# Don't let user refresh their timed item.
	if (_current_item_time != 0):
		return false
	
	if (_hud != null):
		_hud.display_item_name(_held_item)
	
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
	
	boost(45.0)
	_held_item = null
	AudioSystem3D.play_source(_boost_item_activate_player)

func _activate_invincibility_item() -> void:
	
	_invincible = true
	top_speed += INVINCIBILITY_MAX_SPEED_INCREASE
	_set_item_time(INVINCIBILITY_ITEM_TIME)
	AudioSystem3D.play_source(_invincibility_item_activate_player)

func _handle_invincibility_item_finished() -> void:
	
	_invincible = false
	top_speed -= INVINCIBILITY_MAX_SPEED_INCREASE

func _activate_ai_item() -> void:
	
	_set_item_time(AI_ITEM_TIME)
	top_speed += AI_ITEM_MAX_SPEED_INCREASE
	acceleration += AI_ITEM_ACCELERATION_INCREASE
	ai_controller.intelligence = AiRacerController.Intelligence.HIGH
	ai_controller.enabled = true
	AudioSystem3D.play_source(_ai_item_activate_player)

func _handle_ai_item_finished() -> void:
	
	# Only disable the ai racer if we are a player. This keeps ai racers from having their ai turned off after using this item.
	if (racer.device_index != -2):
		ai_controller.enabled = false
	
	ai_controller.intelligence = AiRacerController.Intelligence.LOW
	top_speed -= AI_ITEM_MAX_SPEED_INCREASE
	acceleration -= AI_ITEM_ACCELERATION_INCREASE

func _activate_speed_item() -> void:
	
	_set_item_time(SPEED_ITEM_TIME)
	top_speed += SPEED_ITEM_TOP_SPEED_INCREASE
	acceleration += SPEED_ITEM_ACCELERATION_INCREASE
	AudioSystem3D.play_source(_speed_item_activate_player)

func _handle_speed_item_finished() -> void:
	
	top_speed -= SPEED_ITEM_TOP_SPEED_INCREASE
	acceleration -= SPEED_ITEM_ACCELERATION_INCREASE

func try_give_gas() -> bool:
	
	if (_current_gas == MAX_GAS):
		return false
	
	_current_gas += 1
	if (_hud != null):
		_hud.update_gas(_current_gas, MAX_GAS)
	return true

func try_use_gas() -> bool:
	
	if (_current_gas < MAX_GAS):
		return false
	
	if (_current_item_time > 0):
		return false
	
	_jump_initial_y = self.position.y
	_current_jump_time = JUMP_TIME
	_in_air = true
	ai_controller.enabled = false
	boost(15.0)
	_current_gas = 0
	if (_hud):
		_hud.update_gas(_current_gas, MAX_GAS)
	AudioSystem3D.play_source(_jump_activate_player)
	return true

func _tick_jump() -> void:
	
	var time_p:float = _current_jump_time / JUMP_TIME
	var height_time:float = -pow((time_p * 2.0) - 1.0, 2.0) + 1.0
	self.position.y = lerpf(_jump_initial_y, _jump_initial_y + JUMP_HEIGHT, height_time)

func _handle_jump_finished() -> void:
	
	self.position.y = _jump_initial_y
	_in_air = false
	if (racer.device_index == -2):
		ai_controller.enabled = true

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
	
	nameplate = _model_controller.find_child("Nameplate", true, false)
	nameplate.set_display_name(racer.profile.name)

func _process(delta: float) -> void:
	
	if (_current_item_time > 0):
		_current_item_time -= delta
		if (_current_item_time <= 0):
			_current_item_time = 0
			_handle_timed_item_finished()
	
	if (_current_jump_time > 0):
		_current_jump_time -= delta
		_tick_jump()
		if (_current_jump_time <= 0):
			_current_jump_time = 0
			_handle_jump_finished()
	
	if (_hud != null):
		_hud.update_item_time(_current_item_time, _total_item_time)
		_hud.update_item_usable_state(!_in_air)
		_hud.update_gas_usable_state(_current_item_time == 0)

# These are used to get single inputs instead of a continuous stream.
var _left_key_active:bool = false
var _right_key_active:bool = false
var _powerup_key_active:bool = false
var _jump_key_active:bool = false
var _joystick_active:bool = false
var _powerup_button_active:bool = false
var _jump_button_active:bool = false

func _unhandled_input(event: InputEvent) -> void:
	
	# Always listen for key/button releases so we have the correct states, regardless of our current input allowance.
	if (event is InputEventKey):
		if (event.keycode == KEY_A || event.keycode == KEY_LEFT):
			if (!event.pressed):
				_left_key_active = false
				return
		elif (event.keycode == KEY_D || event.keycode == KEY_RIGHT):
			if (!event.pressed):
				_right_key_active = false
				return
		elif (event.keycode == KEY_X):
			if (!event.pressed):
				_powerup_key_active = false
				return
		elif (event.keycode == KEY_C):
			if (!event.pressed):
				_jump_key_active = false
				return
	elif (event is InputEventJoypadButton):
		if (event.button_index == JOY_BUTTON_X || event.button_index == JOY_BUTTON_Y):
			if (!event.pressed):
				_powerup_button_active = false
		elif (event.button_index == JOY_BUTTON_A || event.button_index == JOY_BUTTON_B):
			if (!event.pressed):
				_jump_button_active = false
	
	if (ai_controller.enabled):
		return
	
	if (!input_enabled):
		return
	
	if (_in_air):
		return
	
	if (event is InputEventKey):
		if (racer.device_index != -1):
			return
		# Keyboard movement.
		if (event.keycode == KEY_A || event.keycode == KEY_LEFT):
			if (!_left_key_active):
				_left_key_active = true
				try_switch_lanes(-1)
		elif (event.keycode == KEY_D || event.keycode == KEY_RIGHT):
			if (!_right_key_active):
				_right_key_active = true
				try_switch_lanes(1)
		# Keyboard powerup.
		elif (event.keycode == KEY_X):
			if (!_powerup_key_active):
				_powerup_key_active = true
				try_use_item()
		# Keyboard jump.
		elif (event.keycode == KEY_C):
			if (!_jump_key_active):
				_jump_key_active = true
				try_use_gas()
	
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
	
	elif (event is InputEventJoypadButton):
		# Gamepad powerup.
		if (event.button_index == JOY_BUTTON_X || event.button_index == JOY_BUTTON_Y):
			if (!_powerup_button_active):
				_powerup_button_active = true
				try_use_item()
		# Gamepad jump.
		elif (event.button_index == JOY_BUTTON_A || event.button_index == JOY_BUTTON_A):
			if (!_jump_button_active):
				_jump_button_active = true
				try_use_gas()
