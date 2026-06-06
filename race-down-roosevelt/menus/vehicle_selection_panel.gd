class_name VehicleSelectionPanel extends Control

const VEHICLE_DATA:Array[RacerVehicleData] = [
	preload("res://vehicles/racer_vehicles/ambulance_data.tres"),
	preload("res://vehicles/racer_vehicles/delivery_truck_flat_data.tres"),
	preload("res://vehicles/racer_vehicles/firetruck_data.tres"),
	preload("res://vehicles/racer_vehicles/race_car_data.tres"),
	preload("res://vehicles/racer_vehicles/sedan_data.tres"),
	preload("res://vehicles/racer_vehicles/sports_car_data.tres")
]

enum PanelState {
	WAITING_FOR_DEVICE,
	VEHICLE_SELECTION,
	READY
}

signal player_ready

@onready var _vehicle_model_viewport:SubViewportContainer = $VehicleModelViewport
@onready var _vehicle_model_camera:Camera3D = $VehicleModelViewport/SubViewport/VehicleModelCamera

@onready var _waiting_for_device_ui:Control = $WaitingForDevice
@onready var _vehicle_selection_ui:Control = $VehicleSelection
@onready var _ready_ui:Control = $Ready

var state:PanelState = PanelState.WAITING_FOR_DEVICE
var racer:RacerObject = RacerObject.new()

var _vehicle_ind:int = 4

func transition_state(newstate:PanelState) -> void:
	
	if (state == newstate):
		return
	
	# Cleanup old state.
	match (state):
		
		PanelState.WAITING_FOR_DEVICE:
			_waiting_for_device_ui.visible = false
		
		PanelState.VEHICLE_SELECTION:
			_vehicle_selection_ui.visible = false
			_vehicle_model_viewport.visible = false
		
		PanelState.READY:
			_ready_ui.visible = false
			_vehicle_model_viewport.visible = false
			
	state = newstate
	
	# Setup new state.
	match (state):
		
		PanelState.WAITING_FOR_DEVICE:
			_waiting_for_device_ui.visible = true
		
		PanelState.VEHICLE_SELECTION:
			_vehicle_selection_ui.visible = true
			_vehicle_model_viewport.visible = true
			update_vehicle()
		
		PanelState.READY:
			_ready_ui.visible = true
			_vehicle_model_viewport.visible = true
			player_ready.emit()

func set_device(index:int) -> void:
	
	var previous:int = racer.device_index
	racer.device_index = index
	
	if (index == -2):
		transition_state(PanelState.WAITING_FOR_DEVICE)
	elif (previous == -2):
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
	_vehicle_model_camera.position.x = 1.0 + (20.0 * _vehicle_ind)

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
			
			PanelState.VEHICLE_SELECTION:
				if (event.keycode == KEY_A || event.keycode == KEY_LEFT):
					move_vehicle_selection_left()
					get_viewport().set_input_as_handled()
				elif (event.keycode == KEY_D || event.keycode == KEY_RIGHT):
					move_vehicle_selection_right()
					get_viewport().set_input_as_handled()
				elif (event.keycode == KEY_ESCAPE):
					set_device(-2)
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
			
			PanelState.VEHICLE_SELECTION:
				if (event.button_index == JOY_BUTTON_DPAD_LEFT || event.button_index == JOY_BUTTON_LEFT_SHOULDER):
					move_vehicle_selection_left()
					get_viewport().set_input_as_handled()
				elif (event.button_index == JOY_BUTTON_DPAD_RIGHT || event.button_index == JOY_BUTTON_RIGHT_SHOULDER):
					move_vehicle_selection_right()
					get_viewport().set_input_as_handled()
				elif (event.button_index == JOY_BUTTON_B):
					set_device(-2)
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
