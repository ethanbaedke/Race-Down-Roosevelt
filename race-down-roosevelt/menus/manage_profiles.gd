class_name ManageProfiles extends Control

signal back_requested
signal add_new_requested

@onready var _add_new_button:Button = $MarginContainer/VBoxContainer/AddNewButton
@onready var _profile_selector:ProfileSelector = $MarginContainer/VBoxContainer/ProfileSelector

var game_state:GameState = null

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects class to have a reference to GameState.")
	
	_add_new_button.grab_focus()
	
	_add_new_button.pressed.connect(func() -> void:
		add_new_requested.emit())
		
	_profile_selector.set_profiles(game_state.profiles)
		
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
