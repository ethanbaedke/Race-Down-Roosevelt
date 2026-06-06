class_name VehicleSelection extends Control

signal all_players_ready(racer_objects:Array[RacerObject])

@export var _panels:Array[VehicleSelectionPanel] = []

func _on_player_ready() -> void:
	
	# Signal if all players are ready.
	var racers:Array[RacerObject] = []
	for panel:VehicleSelectionPanel in _panels:
		if (panel.state == panel.PanelState.READY):
			racers.append(panel.racer)
	if (racers.size() == _panels.size()):
		all_players_ready.emit(racers)

func _ready() -> void:
	
	for panel:VehicleSelectionPanel in _panels:
		panel.player_ready.connect(_on_player_ready)

func _unhandled_input(event: InputEvent) -> void:
	
	# Ignore holding and releases.
	if (event.is_echo() || !event.is_pressed()):
		return
	
	var device_ind:int = -2
	if (event is InputEventKey):
		device_ind = -1
	elif (event is InputEventJoypadButton):
		device_ind = event.device
		
	if (device_ind == -2):
		return
		
	# Try to find a panel using this device.
	var i:int = 0
	while (i < _panels.size() && _panels[i].racer.device_index != device_ind):
		i += 1
	
	# Device is being used by one of the panels, let it handle the input.
	if (i < _panels.size()):
		return
		
	# Device is not being used, try to find an available panel for the new device.
	i = 0
	while (i < _panels.size() && _panels[i].racer.device_index != -2):
		i += 1
		
	# Found an available panel.
	if (i < _panels.size()):
		_panels[i].set_device(device_ind)
		get_viewport().set_input_as_handled()
