class_name TournamentStart extends Control

signal back_requested
signal new_tournament_requested
signal continue_tournament_requested

@onready var _new_tournament_button:Button = $MarginContainer/HBoxContainer/NewTournamentButton
@onready var _continue_tournament_button:Button = $MarginContainer/HBoxContainer/ContinueTournamentButton

var game_state:GameState = null

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects class to have a reference to GameState.")
		return
	
	_new_tournament_button.grab_focus()
	
	_new_tournament_button.pressed.connect(func() -> void:
		new_tournament_requested.emit())
	
	_continue_tournament_button.disabled = game_state.save_data.in_progress_tournaments.size() == 0
	_continue_tournament_button.pressed.connect(func() -> void:
		continue_tournament_requested.emit())

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
