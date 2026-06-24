class_name TournementStart extends Control

signal back_requested
signal new_tournement_requested

@onready var _new_tournement_button:Button = $MarginContainer/HBoxContainer/NewTournementButton
@onready var _continue_tournement_button:Button = $MarginContainer/HBoxContainer/ContinueTournementButton

var game_state:GameState = null

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects class to have a reference to GameState.")
		return
		
	_new_tournement_button.pressed.connect(func() -> void:
		new_tournement_requested.emit())
	
	_continue_tournement_button.disabled = game_state.save_data.in_progress_tournements.size() == 0

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
