class_name TournamentContinue extends Control

signal back_requested
signal continue_tournament_requested

@onready var _list:VBoxContainer = $MarginContainer/ScrollContainer/SavedTournamentList

var game_state:GameState = null

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects class to have a reference to GameState.")
		return
	
	for tournament_state:TournamentState in game_state.save_data.in_progress_tournaments:
		var button:Button = Button.new()
		button.text = tournament_state.tournament_name
		button.add_theme_font_size_override("font_size", 64)
		button.pressed.connect(func() -> void:
			game_state.active_tournament = tournament_state
			continue_tournament_requested.emit())
		_list.add_child(button)

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
