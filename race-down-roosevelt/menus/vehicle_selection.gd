class_name VehicleSelection extends Control

# Fired when no users have joined and a back button is pressed.
signal back_requested
signal all_players_ready(racer_objects:Array[RacerObject])

@export var _panels:Array[VehicleSelectionPanel] = []

var _game_state:GameState = null

var _available_profiles:Array[Profile] = []
var _selected_profiles:Array[Profile] = []

func set_game_state(game_state:GameState) -> void:
	
	_game_state = game_state
	for panel:VehicleSelectionPanel in _panels:
		panel.game_state = game_state

func _update_available_profiles_on_selection_panels() -> void:
	
	for panel:VehicleSelectionPanel in _panels:
		panel.set_available_profiles(_available_profiles)

func _on_profile_selected(profile:Profile) -> void:
	
	var profile_ind:int = _available_profiles.find(profile)
	
	if (profile_ind == -1):
		RdrLogger.error(self, "Profile selected by panel that doesn't exist in the vehicle selections available profiles.")
		return
	
	_available_profiles.remove_at(profile_ind)
	_selected_profiles.append(profile)
	
	_update_available_profiles_on_selection_panels()

func _on_profile_freed(profile:Profile) -> void:
	
	var profile_ind:int = _selected_profiles.find(profile)
	
	if (profile_ind == -1):
		RdrLogger.error(self, "Profile freed by panel doesn't exist in the vehicle selections selected profiles.")
		return
	
	_selected_profiles.remove_at(profile_ind)
	_available_profiles.append(profile)
	
	_update_available_profiles_on_selection_panels()

func _on_player_ready() -> void:
	
	# Signal if all players are ready.
	var racers:Array[RacerObject] = []
	for panel:VehicleSelectionPanel in _panels:
		if (panel.state == panel.PanelState.READY):
			racers.append(panel.racer)
	# All players are in the ready state
	if (racers.size() == _panels.size()):
		# If we are in a tournament, add racer vehicles for the ai racers.
		if (_game_state.active_tournament != null):
			for profile:Profile in _game_state.active_tournament.get_next_match().ai_profiles:
				var ai_racer:RacerObject = RacerObject.new()
				ai_racer.profile = profile
				racers.append(ai_racer)
		all_players_ready.emit(racers)

# Exits selection if no panels are being used.
func _try_exit_selection() -> bool:
	
	var all_panels_unused:bool = true
	for panel:VehicleSelectionPanel in _panels:
		if (panel.racer.device_index != -2):
			all_panels_unused = false
			break
	if (all_panels_unused):
		back_requested.emit()
		return true
	else:
		return false

func _ready() -> void:
	
	if (_game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects class to have a reference to GameState.")
		return
	
	for panel:VehicleSelectionPanel in _panels:
		panel.player_ready.connect(_on_player_ready)
		panel.profile_selected.connect(_on_profile_selected)
		panel.profile_freed.connect(_on_profile_freed)
	
	if (_game_state.active_tournament == null):
		_available_profiles = _game_state.save_data.profiles
	else:
		_available_profiles = _game_state.active_tournament.get_next_match().get_all_profiles()
	
	_update_available_profiles_on_selection_panels()

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
	
	# Device in not being used, if back was pressed and no panels are being used, exit selection.
	if (event is InputEventKey):
		if (event.keycode == KEY_ESCAPE):
			_try_exit_selection()
			get_viewport().set_input_as_handled()
			return
	elif (event is InputEventJoypadButton):
		if (event.button_index == JOY_BUTTON_B):
			_try_exit_selection()
			get_viewport().set_input_as_handled()
			return
	
	# Device is not being used, try to find an available panel for the new device.
	i = 0
	while (i < _panels.size() && _panels[i].racer.device_index != -2):
		i += 1
		
	# Found an available panel.
	if (i < _panels.size()):
		_panels[i].set_device(device_ind)
		get_viewport().set_input_as_handled()
