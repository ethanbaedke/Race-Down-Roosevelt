class_name TournementSetup extends Control

signal back_requested

@onready var _included_profile_button_scene:PackedScene = preload("res://menus/tournement_setup_included_profile_button.tscn")

@onready var _profile_selector:ProfileSelector = $MarginContainer/HBoxContainer/ProfileSelector
@onready var _included_profiles:VBoxContainer = $MarginContainer/HBoxContainer/ScrollContainer/IncludedProfiles

var game_state:GameState = null

var _available_profiles:Array[Profile] = []

func _on_profile_selected(profile:Profile) -> void:
	
	# Remove the profile from the selector.
	var profile_ind:int = _available_profiles.find(profile)
	_available_profiles.remove_at(profile_ind)
	_profile_selector.set_profiles(_available_profiles)
	
	# Add the profile to the list of included profiles.
	var button:Button = _included_profile_button_scene.instantiate()
	button.text = profile.name
	button.pressed.connect(func() -> void:
		_remove_included_profile(profile, button))
	_included_profiles.add_child(button)

func _remove_included_profile(profile:Profile, profile_button:Button) -> void:
	
	# Remove the profile from the list of included profiles.
	_included_profiles.remove_child(profile_button)
	
	# Add the profile back to the selector.
	_available_profiles.append(profile)
	_profile_selector.set_profiles(_available_profiles)

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects class to have a reference to GameState.")
		return
	
	_available_profiles = game_state.save_data.profiles.duplicate()
	
	_profile_selector.set_profiles(_available_profiles)
	_profile_selector.profile_selected.connect(_on_profile_selected)

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
