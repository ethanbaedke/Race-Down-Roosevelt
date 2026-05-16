class_name RacerVehicle extends Node3D

const LANE_SWITCH_DIST:float = 3.0

# This must be set when a racer vehicle is instantiated.
var racer:RacerObject = null

var speed:float = 0

func calculate_speed() -> float:
	
	return speed

func try_switch_lanes(dir:int) -> bool:
	
	position.x += dir * -1 * LANE_SWITCH_DIST
	return true

func _ready() -> void:
	
	if (racer == null):
		RdrLogger.warn(self, "Racer object not set. Creating default instance.")
		racer = RacerObject.new()
		
	# NOTE: Testing only.
	speed = randi_range(1, 4)

# These are used to get single inputs instead of a continuous stream.
var _left_key_active:bool = false
var _right_key_active:bool = false
var _joystick_active:bool = false

func _unhandled_input(event: InputEvent) -> void:
	
	if (event is InputEventKey):
		if (racer.device_index != -1):
			return
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
		
	elif (event.device != racer.device_index):
		return
	
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
		pass
