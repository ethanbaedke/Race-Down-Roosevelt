class_name TournamentSetup extends Control

signal back_requested
signal start_tournament_requested

@onready var _included_profile_button_scene:PackedScene = preload("res://menus/tournament_setup_included_profile_button.tscn")

@onready var _profile_selector:ProfileSelector = $MarginContainer/HBoxContainer/VBoxContainer/ProfileSelector
@onready var _included_profiles_container:VBoxContainer = $MarginContainer/HBoxContainer/ScrollContainer/IncludedProfiles
@onready var _start_tournament_button:Button = $MarginContainer/HBoxContainer/VBoxContainer/StartTournamentButton

var game_state:GameState = null

var _available_profiles:Array[Profile] = []
var _included_profiles:Array[Profile] = []

func _on_profile_selected(profile:Profile) -> void:
	
	# Remove the profile from the selector.
	var profile_ind:int = _available_profiles.find(profile)
	_available_profiles.remove_at(profile_ind)
	_profile_selector.set_profiles(_available_profiles)
	
	# Add the profile to the list of included profiles.
	_included_profiles.append(profile)
	var button:Button = _included_profile_button_scene.instantiate()
	button.text = profile.name
	button.pressed.connect(func() -> void:
		_remove_included_profile(profile, button))
	_included_profiles_container.add_child(button)
	
	_update_start_tournament_button_disabled_state();

func _remove_included_profile(profile:Profile, profile_button:Button) -> void:
	
	# Remove the profile from the list of included profiles.
	var profile_ind:int = _included_profiles.find(profile)
	_included_profiles.remove_at(profile_ind)
	_included_profiles_container.remove_child(profile_button)
	
	# Add the profile back to the selector.
	_available_profiles.append(profile)
	_profile_selector.set_profiles(_available_profiles)
	
	_update_start_tournament_button_disabled_state();

func _on_start_tournament_button_pressed() -> void:
	
	var tournament_state:TournamentState = TournamentState.new()
	tournament_state.build_tournament(_included_profiles)
	game_state.save_data.in_progress_tournaments.append(tournament_state)
	game_state.save_data.save()
	game_state.active_tournament = tournament_state
	start_tournament_requested.emit()

func _update_start_tournament_button_disabled_state() -> void:
	
	_start_tournament_button.disabled = _included_profiles.size() == 0

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects class to have a reference to GameState.")
		return
	
	_available_profiles = game_state.save_data.profiles.duplicate()
	
	_profile_selector.set_profiles(_available_profiles)
	_profile_selector.profile_selected.connect(_on_profile_selected)
	
	_update_start_tournament_button_disabled_state();
	_start_tournament_button.pressed.connect(_on_start_tournament_button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	
	# Ignore holding and releases.
	if (event.is_echo() || !event.is_pressed()):
		return
		
	if (event is InputEventKey):
		
		if (event.keycode == KEY_ESCAPE):
			back_requested.emit()
			get_viewport().set_input_as_handled()
			
	elif (event is InputEventJoypadButton):
		
		if (event.button_index == JOY_BUTTON_B):
			back_requested.emit()
			get_viewport().set_input_as_handled()
