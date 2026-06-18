class_name EditProfile extends Control

signal back_requested

@onready var _profile_icon:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/Icon
@onready var _profile_name:Label = $MarginContainer/VBoxContainer/HBoxContainer/Name
@onready var _discard_changes_button:Button = $MarginContainer/VBoxContainer/MarginContainer/DefaultOptions/VBoxContainer/HBoxContainer/DiscardChangesButton
@onready var _save_changes_button:Button = $MarginContainer/VBoxContainer/MarginContainer/DefaultOptions/VBoxContainer/HBoxContainer/SaveChangesButton2

var game_state:GameState = null

# The profile selected for editing. This profile is not modified until the save button is pressed.
var _loaded_profile:Profile = null
# This is the profile that is edited.
# This profile is written back to the loaded profile when save is pressed, and discarded when discard changes is pressed.
var _profile_copy:Profile = null

func _load_profile(profile:Profile) -> void:
	
	_loaded_profile = profile
	_profile_copy = _loaded_profile.duplicate()
	_update_profile_ui()
	
func _update_profile_ui() -> void:

	_profile_icon.texture = _profile_copy.icon
	_profile_name.text = _profile_copy.name

func _on_save_changes_button_pressed() -> void:
	
	# Write data from our temporary copy to the actual profile.
	_loaded_profile.copy_profile(_profile_copy)
	
	# If this profile is new, it won't yet exist in our games profile list. Add it.
	if (game_state.profiles.find(_loaded_profile) == -1):
		game_state.profiles.append(_loaded_profile)
	
	back_requested.emit()

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects class to have a reference to GameState.")
	
	_discard_changes_button.pressed.connect(func() -> void:
		back_requested.emit())
	_save_changes_button.pressed.connect(_on_save_changes_button_pressed)

	if (game_state.profile_to_edit != null):
		_load_profile(game_state.profile_to_edit)
	else:
		_load_profile(Profile.new())

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
