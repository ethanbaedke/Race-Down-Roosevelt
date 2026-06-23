class_name EditProfile extends Control

signal back_requested

@onready var _profile_icon:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/Icon
@onready var _profile_name:LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/Name
@onready var _change_name_button:Button = $MarginContainer/VBoxContainer/MarginContainer/DefaultOptions/VBoxContainer/VBoxContainer/ChangeNameButton
@onready var _change_icon_button:Button = $MarginContainer/VBoxContainer/MarginContainer/DefaultOptions/VBoxContainer/VBoxContainer/ChangeIconButton
@onready var _discard_changes_button:Button = $MarginContainer/VBoxContainer/MarginContainer/DefaultOptions/VBoxContainer/HBoxContainer/DiscardChangesButton
@onready var _save_changes_button:Button = $MarginContainer/VBoxContainer/MarginContainer/DefaultOptions/VBoxContainer/HBoxContainer/SaveChangesButton2

@onready var _default_options:MarginContainer = $MarginContainer/VBoxContainer/MarginContainer/DefaultOptions
@onready var _icon_selection:CenterContainer = $MarginContainer/VBoxContainer/MarginContainer/IconSelection

@onready var _icon_buttons:Array[Button] = [
	$MarginContainer/VBoxContainer/MarginContainer/IconSelection/GridContainer/Icon1/Button,
	$MarginContainer/VBoxContainer/MarginContainer/IconSelection/GridContainer/Icon2/Button,
	$MarginContainer/VBoxContainer/MarginContainer/IconSelection/GridContainer/Icon3/Button,
]

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

func _go_back() -> void:
	
	# Store the profile we were editing so it can be selected if we go back to a menu that needs it.
	game_state.profile_to_edit = _loaded_profile
	back_requested.emit()

func _on_profile_name_text_submitted(new_text:String) -> void:
	
	_profile_name.editable = false
	_profile_copy.name = _profile_name.text
	_change_name_button.grab_focus.call_deferred()
	
func _on_profile_name_focus_exited() -> void:
	
	_profile_name.editable = false
	_profile_copy.name = _profile_name.text

func _on_change_name_button_pressed() -> void:
	
	_profile_name.editable = true
	_profile_name.caret_column = _profile_name.text.length()
	_profile_name.grab_focus()

func _on_change_icon_button_pressed() -> void:
	
	_default_options.visible = false
	_icon_selection.visible = true
	if (_icon_buttons.size() > 0):
		_icon_buttons[0].grab_focus()

func _handle_icon_button_pressed(index:int) -> void:
	
	var sbt:StyleBoxTexture = _icon_buttons[index].get_theme_stylebox("normal", "")
	_profile_copy.icon = sbt.texture
	_update_profile_ui()
	
	_icon_selection.visible = false
	_default_options.visible = true

func _on_save_changes_button_pressed() -> void:
	
	# Write data from our temporary copy to the actual profile.
	_loaded_profile.copy_profile(_profile_copy)
	
	# If this profile is new, it won't yet exist in our games profile list. Add it.
	if (game_state.save_data.profiles.find(_loaded_profile) == -1):
		game_state.save_data.profiles.append(_loaded_profile)
		game_state.save_data.save()
	
	_go_back()

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects class to have a reference to GameState.")
		return
	
	_profile_name.text_submitted.connect(_on_profile_name_text_submitted)
	_profile_name.focus_exited.connect(_on_profile_name_focus_exited)
	_change_name_button.pressed.connect(_on_change_name_button_pressed)
	_change_icon_button.pressed.connect(_on_change_icon_button_pressed)
	_discard_changes_button.pressed.connect(func() -> void:
		_go_back())
	_save_changes_button.pressed.connect(_on_save_changes_button_pressed)

	for i:int in range(_icon_buttons.size()):
		_icon_buttons[i].pressed.connect(func() -> void:
			_handle_icon_button_pressed(i))

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
			_go_back()
			get_viewport().set_input_as_handled()
			return
	elif (event is InputEventJoypadButton):
		if (event.button_index == JOY_BUTTON_B):
			_go_back()
			get_viewport().set_input_as_handled()
			return
