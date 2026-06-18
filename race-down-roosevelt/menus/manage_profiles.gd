class_name ManageProfiles extends Control

signal back_requested
signal add_new_requested
signal edit_profile_requested()

@onready var _add_new_button:Button = $MarginContainer/VBoxContainer/AddNewButton
@onready var _profile_selector:ProfileSelector = $MarginContainer/VBoxContainer/ProfileSelector
@onready var _edit_profile_button:Button = $MarginContainer/VBoxContainer/EditProfileButton
@onready var _delete_profile_button:Button = $MarginContainer/VBoxContainer/DeleteProfileButton

var game_state:GameState = null

func _update_profile_option_disabled_states() -> void:

	_edit_profile_button.disabled = game_state.profiles.size() == 0
	_delete_profile_button.disabled = game_state.profiles.size() == 0

func _on_profile_selector_profile_selected() -> void:
	
	_edit_profile_button.grab_focus()

func _on_edit_profile_button_pressed() -> void:
	
	game_state.profile_to_edit = _profile_selector.get_selected_profile()
	edit_profile_requested.emit()

func _on_delete_profile_button_pressed() -> void:
	
	var profile_ind:int = game_state.profiles.find(_profile_selector.get_selected_profile())
	if (profile_ind == -1):
		RdrLogger.error(self, "Could not find profile to delete.")
		return
	game_state.profiles.remove_at(profile_ind)
	_profile_selector.set_profiles(game_state.profiles)
	_update_profile_option_disabled_states()

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects class to have a reference to GameState.")
	
	_add_new_button.grab_focus()
	
	_add_new_button.pressed.connect(func() -> void:
		add_new_requested.emit())
	
	_profile_selector.profile_selected.connect(_on_profile_selector_profile_selected)
	_profile_selector.set_profiles(game_state.profiles)
	
	_edit_profile_button.pressed.connect(_on_edit_profile_button_pressed)
	_delete_profile_button.pressed.connect(_on_delete_profile_button_pressed)
	
	_update_profile_option_disabled_states()

func _unhandled_input(event: InputEvent) -> void:

	# Ignore holding and releases.
	if (event.is_echo() || !event.is_pressed()):
		return

	if (event is InputEventKey):
		if (event.keycode == KEY_ESCAPE):
			back_requested.emit()
			get_viewport().set_input_as_handled()
			return
	elif (event is InputEventJoypadButton):
		if (event.button_index == JOY_BUTTON_B):
			back_requested.emit()
			get_viewport().set_input_as_handled()
			return
