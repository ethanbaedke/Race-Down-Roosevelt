class_name VehicleSelectionPanel extends Control

const VEHICLE_DATA:Array[RacerVehicleData] = [
	preload("res://vehicles/racer_vehicles/jeep_wrangler_data.tres"),
	preload("res://vehicles/racer_vehicles/subaru_forester_data.tres"),
	preload("res://vehicles/racer_vehicles/mini_cooper_data.tres"),
	preload("res://vehicles/racer_vehicles/honda_civic_data.tres"),
	preload("res://vehicles/racer_vehicles/cybertruck_data.tres")
]

enum PanelState {
	WAITING_FOR_DEVICE,
	PROFILE_SELECTION,
	VEHICLE_SELECTION,
	READY
}

signal player_ready
signal profile_selected(profile:Profile)
signal profile_freed(profile:Profile)

@export var text_scaling:float = 1.0

@export var _stat_bar_color_gradient:GradientTexture1D

@onready var _waiting_label:Label = $MarginContainer/VBoxContainer/Control2/WaitingForDevice/WaitingLabel
@onready var _profile_name_container:PanelContainer = $MarginContainer/VBoxContainer/Control3/ProfileNameContainer
@onready var _profile_name:Label = $MarginContainer/VBoxContainer/Control3/ProfileNameContainer/ProfileName
@onready var _vehicle_model_camera:Camera3D = $VehicleModelViewport/SubViewport/VehicleModelCamera
@onready var _speed_bar:ProgressBar = $MarginContainer/VBoxContainer/Control/VehicleStats/Speed/SpeedBar
@onready var _speed_label:Label = $MarginContainer/VBoxContainer/Control/VehicleStats/Speed/Label
@onready var _acceleration_bar:ProgressBar = $MarginContainer/VBoxContainer/Control/VehicleStats/Acceleration/AccelerationBar
@onready var _acceleration_label:Label = $MarginContainer/VBoxContainer/Control/VehicleStats/Acceleration/Label
@onready var _durability_bar:ProgressBar = $MarginContainer/VBoxContainer/Control/VehicleStats/Durability/DurabilityBar
@onready var _durability_label:Label = $MarginContainer/VBoxContainer/Control/VehicleStats/Durability/Label
@onready var _weight_bar:ProgressBar = $MarginContainer/VBoxContainer/Control/VehicleStats/Weight/WeightBar
@onready var _weight_label:Label = $MarginContainer/VBoxContainer/Control/VehicleStats/Weight/Label
@onready var _waiting_for_device_ui:Control = $MarginContainer/VBoxContainer/Control2/WaitingForDevice
@onready var _profile_selector:ProfileSelector = $MarginContainer/VBoxContainer/Control2/ProfileSelector
@onready var _vehicle_selection_ui:Control = $MarginContainer/VBoxContainer/Control/VehicleStats
@onready var _ready_ui:Control = $MarginContainer/VBoxContainer/Control2/ReadyContainer
@onready var _ready_label:Label = $MarginContainer/VBoxContainer/Control2/ReadyContainer/Label

var game_state:GameState = null

var state:PanelState = PanelState.WAITING_FOR_DEVICE
var racer:RacerObject = RacerObject.new()

var _vehicle_ind:int = 0
var _camera_target_pos:Vector3 = Vector3(4.5, 3.0, -15.0)

func transition_state(newstate:PanelState) -> void:
	
	if (state == newstate):
		return
	
	# Cleanup old state.
	match (state):
		
		PanelState.WAITING_FOR_DEVICE:
			_waiting_for_device_ui.visible = false
			
		PanelState.PROFILE_SELECTION:
			_profile_selector.visible = false
		
		PanelState.VEHICLE_SELECTION:
			_vehicle_selection_ui.visible = false
		
		PanelState.READY:
			_ready_ui.visible = false
			
	state = newstate
	
	# Setup new state.
	match (state):
		
		PanelState.WAITING_FOR_DEVICE:
			_waiting_for_device_ui.visible = true
			
		PanelState.PROFILE_SELECTION:
			_profile_selector.visible = true
			_profile_selector.device_ind = racer.device_index
			_profile_selector.give_fake_focus()
		
		PanelState.VEHICLE_SELECTION:
			_vehicle_selection_ui.visible = true
			update_vehicle()
		
		PanelState.READY:
			# Keep car stats visible when player readys up.
			_vehicle_selection_ui.visible = true
			_ready_ui.visible = true
			player_ready.emit()

func set_device(index:int) -> void:
	
	var previous:int = racer.device_index
	racer.device_index = index
	
	if (index == -2):
		transition_state(PanelState.WAITING_FOR_DEVICE)
	elif (previous == -2):
		transition_state(PanelState.PROFILE_SELECTION)

func set_available_profiles(profiles:Array[Profile]) -> void:
	
	_profile_selector.set_profiles(profiles)

func set_profile(profile:Profile) -> void:
	
	if (racer.profile != null):
		profile_freed.emit(racer.profile)
		if (profile == null):
			_profile_selector.try_select_specific_profile(racer.profile)
	
	racer.profile = profile
	
	if (profile == null):
		_profile_name_container.visible = false
		_profile_name.text = ""
		transition_state(PanelState.PROFILE_SELECTION)
	else:
		profile_selected.emit(profile)
		_profile_name_container.visible = true
		_profile_name.text = profile.name
		transition_state(PanelState.VEHICLE_SELECTION)

func set_chosen_vehicle(data:RacerVehicleData) -> void:
	
	racer.vehicle_data = data
	
	if (data == null):
		transition_state(PanelState.VEHICLE_SELECTION)
	else:
		transition_state(PanelState.READY)

func move_vehicle_selection_left() -> void:
	_vehicle_ind = _vehicle_ind - 1
	if (_vehicle_ind < 0):
		_vehicle_ind = VEHICLE_DATA.size() - 1
	update_vehicle()
	
func move_vehicle_selection_right() -> void:
	_vehicle_ind = (_vehicle_ind + 1) % VEHICLE_DATA.size()
	update_vehicle()

func update_vehicle() -> void:
	
	# Show the new vehicle model.
	_camera_target_pos.z = -15.0 + (10.0 * _vehicle_ind)
	
	# Display stats.
	var data:RacerVehicleData = VEHICLE_DATA[_vehicle_ind]
	_speed_bar.max_value = (RacerVehicle.MAX_TOP_SPEED + 1) - RacerVehicle.MIN_TOP_SPEED
	_speed_bar.value = (data.top_speed + 1) - RacerVehicle.MIN_TOP_SPEED
	_acceleration_bar.max_value = (RacerVehicle.MAX_ACCELERATION + 1) - RacerVehicle.MIN_ACCELERATION
	_acceleration_bar.value = (data.acceleration + 1) - RacerVehicle.MIN_ACCELERATION
	_durability_bar.max_value = (RacerVehicle.MAX_DURABILITY + 1) - RacerVehicle.MIN_DURABILITY
	_durability_bar.value = (data.durability + 1) - RacerVehicle.MIN_DURABILITY
	_weight_bar.max_value = (RacerVehicle.MAX_WEIGHT + 1) - RacerVehicle.MIN_WEIGHT
	_weight_bar.value = (data.weight + 1) - RacerVehicle.MIN_WEIGHT
	
	# Set bar colors based on values.
	var speed_stylebox:StyleBoxFlat = _speed_bar.get_theme_stylebox("fill") as StyleBoxFlat
	speed_stylebox.bg_color = _stat_bar_color_gradient.gradient.sample(_speed_bar.value / _speed_bar.max_value)
	var acceleration_stylebox:StyleBoxFlat = _acceleration_bar.get_theme_stylebox("fill") as StyleBoxFlat
	acceleration_stylebox.bg_color = _stat_bar_color_gradient.gradient.sample(_acceleration_bar.value / _acceleration_bar.max_value)
	var _durability_stylebox:StyleBoxFlat = _durability_bar.get_theme_stylebox("fill") as StyleBoxFlat
	_durability_stylebox.bg_color = _stat_bar_color_gradient.gradient.sample(_durability_bar.value / _durability_bar.max_value)
	var weight_stylebox:StyleBoxFlat = _weight_bar.get_theme_stylebox("fill") as StyleBoxFlat
	weight_stylebox.bg_color = _stat_bar_color_gradient.gradient.sample(_weight_bar.value / _weight_bar.max_value)

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects class to have a reference to GameState.")
		return
		
	_profile_selector.profile_selected.connect(func(profile:Profile) -> void:
		set_profile(profile))
	
	_profile_name_container.visible = false
	_profile_name.text = ""
	
	_waiting_label.add_theme_font_size_override("font_size", (48.0 * text_scaling) as int)
	_profile_name.add_theme_font_size_override("font_size", (48.0 * text_scaling) as int)
	_speed_label.add_theme_font_size_override("font_size", (32.0 * text_scaling) as int)
	_acceleration_label.add_theme_font_size_override("font_size", (32.0 * text_scaling) as int)
	_durability_label.add_theme_font_size_override("font_size", (32.0 * text_scaling) as int)
	_weight_label.add_theme_font_size_override("font_size", (32.0 * text_scaling) as int)
	_ready_label.add_theme_font_size_override("font_size", (64.0 * text_scaling) as int)

func _process(delta: float) -> void:
	
	var cam_move_dir:Vector3 = _camera_target_pos - _vehicle_model_camera.position
	var vel:float = cam_move_dir.length() * delta * 20.0
	vel = min(vel, 0.5)
	vel = max(vel, 0.01)
	var new_pos:Vector3 = _vehicle_model_camera.position + (cam_move_dir.normalized() * vel)
	if ((_camera_target_pos - new_pos).dot(cam_move_dir) <= 0):
		_vehicle_model_camera.position = _camera_target_pos
	else:
		_vehicle_model_camera.position = new_pos

var _left_joystick_active:bool = false
var _right_joystick_active:bool = false
func _unhandled_input(event: InputEvent) -> void:
	
	# Ignore holding
	if (event.is_echo()):
		return
	
	var device_ind:int = -2
	if (event is InputEventKey):
		device_ind = -1
	elif (event is InputEventJoypadButton || event is InputEventJoypadMotion):
		device_ind = event.device
		
	if (racer.device_index == -2 || device_ind != racer.device_index):
		return
	
	if (event is InputEventKey):
		
		# Ignore releases.
		if (!event.is_pressed()):
			return
		
		match (state):
		
			PanelState.WAITING_FOR_DEVICE:
				pass
			
			PanelState.PROFILE_SELECTION:
				if (event.keycode == KEY_ESCAPE):
					set_device(-2)
					get_viewport().set_input_as_handled()
			
			PanelState.VEHICLE_SELECTION:
				if (event.keycode == KEY_A || event.keycode == KEY_LEFT):
					move_vehicle_selection_left()
					get_viewport().set_input_as_handled()
				elif (event.keycode == KEY_D || event.keycode == KEY_RIGHT):
					move_vehicle_selection_right()
					get_viewport().set_input_as_handled()
				elif (event.keycode == KEY_ESCAPE):
					set_profile(null)
					get_viewport().set_input_as_handled()
				elif (event.keycode == KEY_C):
					set_chosen_vehicle(VEHICLE_DATA[_vehicle_ind])
					get_viewport().set_input_as_handled()
			
			PanelState.READY:
				if (event.keycode == KEY_ESCAPE):
					set_chosen_vehicle(null)
					get_viewport().set_input_as_handled()
		
	elif (event is InputEventJoypadButton):
		
		# Ignore releases.
		if (!event.is_pressed()):
			return
		
		match (state):
		
			PanelState.WAITING_FOR_DEVICE:
				pass
			
			PanelState.PROFILE_SELECTION:
				if (event.button_index == JOY_BUTTON_B):
					set_device(-2)
					get_viewport().set_input_as_handled()
			
			PanelState.VEHICLE_SELECTION:
				if (event.button_index == JOY_BUTTON_DPAD_LEFT || event.button_index == JOY_BUTTON_LEFT_SHOULDER):
					move_vehicle_selection_left()
					get_viewport().set_input_as_handled()
				elif (event.button_index == JOY_BUTTON_DPAD_RIGHT || event.button_index == JOY_BUTTON_RIGHT_SHOULDER):
					move_vehicle_selection_right()
					get_viewport().set_input_as_handled()
				elif (event.button_index == JOY_BUTTON_B):
					set_profile(null)
					get_viewport().set_input_as_handled()
				elif (event.button_index == JOY_BUTTON_A):
					set_chosen_vehicle(VEHICLE_DATA[_vehicle_ind])
					get_viewport().set_input_as_handled()
			
			PanelState.READY:
				if (event.button_index == JOY_BUTTON_B):
					set_chosen_vehicle(null)
					get_viewport().set_input_as_handled()
		
	elif (event is InputEventJoypadMotion):
		
		match (state):
		
			PanelState.WAITING_FOR_DEVICE:
				pass
			
			PanelState.VEHICLE_SELECTION:
				if (event.axis == JOY_AXIS_LEFT_X):
					if (_left_joystick_active):
						if (abs(event.axis_value) < 0.5):
							_left_joystick_active = false
					else:
						if (event.axis_value < -0.5):
							move_vehicle_selection_left()
							get_viewport().set_input_as_handled()
							_left_joystick_active = true
						elif (event.axis_value > 0.5):
							move_vehicle_selection_right()
							get_viewport().set_input_as_handled()
							_left_joystick_active = true
				elif (event.axis == JOY_AXIS_RIGHT_X):
					if (_right_joystick_active):
						if (abs(event.axis_value) < 0.5):
							_right_joystick_active = false
					else:
						if (event.axis_value < -0.5):
							move_vehicle_selection_left()
							get_viewport().set_input_as_handled()
							_right_joystick_active = true
						elif (event.axis_value > 0.5):
							move_vehicle_selection_right()
							get_viewport().set_input_as_handled()
							_right_joystick_active = true
			
			PanelState.READY:
				pass
