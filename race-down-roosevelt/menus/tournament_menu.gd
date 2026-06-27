class_name TournamentMenu extends Control

signal back_requested
signal start_match_requested
signal return_to_menu_requested

@export var winners_round_1:Array[TournamentMatch] = []
@export var winners_round_2:Array[TournamentMatch] = []
@export var winners_round_3:Array[TournamentMatch] = []
@export var winners_round_4:Array[TournamentMatch] = []
@export var losers_round_1:Array[TournamentMatch] = []
@export var losers_round_2:Array[TournamentMatch] = []
@export var losers_round_3:Array[TournamentMatch] = []
@export var losers_round_4:Array[TournamentMatch] = []
@export var losers_round_5:Array[TournamentMatch] = []
@export var final_round:Array[TournamentMatch] = []

@export var _winner_label:Label = null
@export var _start_match_button:Button = null
@export var _return_to_menu_button:Button = null

var game_state:GameState = null

func _get_all_rounds() -> Array[Array]:
	
	return [
		winners_round_1,
		winners_round_2,
		winners_round_3,
		winners_round_4,
		losers_round_1,
		losers_round_2,
		losers_round_3,
		losers_round_4,
		losers_round_5,
		final_round,
	]

# Should only be called once, to give the match data to the match ui.
func _set_match_data_references() -> void:
	
	var all_rounds:Array[Array] = _get_all_rounds()
	var all_round_data:Array[Array] = game_state.active_tournament.get_all_rounds()
	
	for i:int in range(all_round_data.size()):
		for f:int in range(all_round_data[i].size()):
			all_rounds[i][f].set_match_data(all_round_data[i][f])

func _on_start_match_button_pressed() -> void:
	
	game_state.num_players = game_state.active_tournament.next_match.player_profiles.size()
	start_match_requested.emit()

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects class to have a reference to GameState.")
		return
		
	if (game_state.active_tournament == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects an active tournament to be set on GameState.")
		return
	
	_start_match_button.pressed.connect(_on_start_match_button_pressed)
	_return_to_menu_button.pressed.connect(func() -> void:
		return_to_menu_requested.emit())
	
	_set_match_data_references()
	
	if (game_state.active_tournament.winner != null):
		_winner_label.text = "Winner: " + game_state.active_tournament.winner.name
		_start_match_button.visible = false
		_return_to_menu_button.visible = true

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
