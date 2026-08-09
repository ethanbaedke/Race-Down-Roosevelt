class_name ProfileSelector extends Control

signal profile_selected(profile:Profile)

@onready var _center_container:PanelContainer = $MarginContainer/Control/Center
@onready var _center_label:Label = $MarginContainer/Control/Center/Label
@onready var _left_container:PanelContainer = $MarginContainer/Control/Left
@onready var _left_label:Label = $MarginContainer/Control/Left/Label
@onready var _right_container:PanelContainer = $MarginContainer/Control/Right
@onready var _right_label:Label = $MarginContainer/Control/Right/Label
@onready var _no_profiles_container:PanelContainer = $MarginContainer/NoProfilesContainer

@export var profiles:Array[Profile] = []
var _profile_ind:int = 0

# This is the device that is controlling the profile selector.
var device_ind:int = -2

func set_profiles(new_profiles:Array[Profile], starting_profile:Profile = null) -> void:
	
	profiles = new_profiles
	
	if (profiles.size() == 0):
		RdrLogger.warn(self, "No profiles could be displayed since the profiles list on this class is empty.")
		
	if (starting_profile != null):
		var profile_ind:int = new_profiles.find(starting_profile)
		if (profile_ind == -1):
			RdrLogger.warn(self, "Starting profile not found in profile list.")
		else:
			_profile_ind = profile_ind
	
	# Setting profiles may bring the profile index out of bounds. Ensure its clamped.
	if (profiles.size() != 0):
		if (_profile_ind < 0):
			_profile_ind = profiles.size() - 1
		_profile_ind = _profile_ind % profiles.size()
	
	_update_container_visibilities()
	_update_container_text()

func get_selected_profile() -> Profile:
	
	return profiles[_profile_ind]

func try_select_specific_profile(profile:Profile) -> void:
	
	var profile_ind:int = profiles.find(profile)
	if (profile_ind != -1):
		_profile_ind = profile_ind
		_update_container_visibilities()
		_update_container_text()

func _update_container_visibilities() -> void:
	
	match (profiles.size()):
		0:
			_no_profiles_container.visible = true
			_center_container.visible = false
			_left_container.visible = false
			_right_container.visible = false
		1:
			_no_profiles_container.visible = false
			_center_container.visible = true
			_left_container.visible = false
			_right_container.visible = false
		2:
			_no_profiles_container.visible = false
			_center_container.visible = true
			if (_profile_ind == 0):
				_left_container.visible = false
				_right_container.visible = true
			else:
				_left_container.visible = true
				_right_container.visible = false
		_:
			_no_profiles_container.visible = false
			_center_container.visible = true
			_left_container.visible = true
			_right_container.visible = true

func _update_container_text() -> void:
	
	match (profiles.size()):
		0:
			pass
		1:
			_center_label.text = profiles[0].name
		2:
			if (_profile_ind == 0):
				_center_label.text = profiles[0].name
				_right_label.text = profiles[1].name
			else:
				_center_label.text = profiles[1].name
				_left_label.text = profiles[0].name
		_:
			var left_ind:int = _profile_ind - 1
			if (left_ind < 0):
				left_ind = profiles.size() - 1
			var right_ind:int = (_profile_ind + 1) % profiles.size()
			_center_label.text = profiles[_profile_ind].name
			_left_label.text = profiles[left_ind].name
			_right_label.text = profiles[right_ind].name

func _navigate_left() -> void:
	
	if (profiles.size() < 2):
		return
	elif (profiles.size() == 2 && _profile_ind == 0):
		return
	
	_profile_ind -= 1
	if (_profile_ind < 0):
		_profile_ind = profiles.size() - 1
	_update_container_visibilities()
	_update_container_text()
	
func _navigate_right() -> void:
	
	if (profiles.size() < 2):
		return
	elif (profiles.size() == 2 && _profile_ind == 1):
		return
	
	_profile_ind = (_profile_ind + 1) % profiles.size()
	_update_container_visibilities()
	_update_container_text()

func _ready() -> void:
	
	self.focus_entered.connect(_focus_entered)
	self.focus_exited.connect(_focus_exited)

func _focus_entered() -> void:
	
	(_center_container.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color.GOLDENROD
	_center_container.scale = Vector2(1.3, 1.3)

func _focus_exited() -> void:
	
	(_center_container.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color("bfbfbf")
	_center_container.scale = Vector2(1.2, 1.2)

var _left_joystick_active:bool = false
var _right_joystick_active:bool = false
func _unhandled_input(event: InputEvent) -> void:
	
	if (!self.has_focus()):
		return
	
	if (!self.visible):
		return
	
	var input_device_ind:int = -2
	if (event is InputEventKey):
		input_device_ind = -1
	elif (event is InputEventJoypadButton || event is InputEventJoypadMotion):
		input_device_ind = event.device
	
	# Only allow input from the device controlling this profile selector.
	# For the purpose of this selector, a device index of -2 implies that any device can control it.
	if (device_ind != -2 && input_device_ind != device_ind):
		return
	
	# Ignore holding.
	if (event.is_echo()):
		return

	if (event is InputEventKey):
		
		# Ignore releases
		if (!event.is_pressed()):
			return
		
		if (event.keycode == KEY_LEFT || event.keycode == KEY_A):
			_navigate_left()
			get_viewport().set_input_as_handled()
			return
		elif (event.keycode == KEY_RIGHT || event.keycode == KEY_D):
			_navigate_right()
			get_viewport().set_input_as_handled()
			return
		elif (event.keycode == KEY_C):
			if (profiles.size() > 0):
				profile_selected.emit(profiles[_profile_ind])
				get_viewport().set_input_as_handled()
				return
	elif (event is InputEventJoypadButton):
		
		# Ignore releases
		if (!event.is_pressed()):
			return
		
		if (event.button_index == JOY_BUTTON_DPAD_LEFT):
			_navigate_left()
			get_viewport().set_input_as_handled()
			return
		elif (event.button_index == JOY_BUTTON_DPAD_RIGHT):
			_navigate_right()
			get_viewport().set_input_as_handled()
			return
		elif (event.button_index == JOY_BUTTON_A):
			if (profiles.size() > 0):
				profile_selected.emit(profiles[_profile_ind])
				get_viewport().set_input_as_handled()
				return
	elif (event is InputEventJoypadMotion):
		if (event.axis == JOY_AXIS_LEFT_X):
			if (_left_joystick_active):
				if (abs(event.axis_value) < 0.5):
					_left_joystick_active = false
			else:
				if (event.axis_value < -0.5):
					_navigate_left()
					get_viewport().set_input_as_handled()
					_left_joystick_active = true
				elif (event.axis_value > 0.5):
					_navigate_right()
					get_viewport().set_input_as_handled()
					_left_joystick_active = true
		elif (event.axis == JOY_AXIS_RIGHT_X):
			if (_right_joystick_active):
				if (abs(event.axis_value) < 0.5):
					_right_joystick_active = false
			else:
				if (event.axis_value < -0.5):
					_navigate_left()
					get_viewport().set_input_as_handled()
					_right_joystick_active = true
				elif (event.axis_value > 0.5):
					_navigate_right()
					get_viewport().set_input_as_handled()
					_right_joystick_active = true
