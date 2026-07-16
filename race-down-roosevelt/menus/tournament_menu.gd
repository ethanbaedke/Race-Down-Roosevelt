class_name TournamentMenu extends Control

signal back_requested
signal start_match_requested
signal return_to_menu_requested

@onready var _top_label:Label = $MarginContainer/Control/TopLabel
@onready var _bottom_button:Button = $MarginContainer/Control/BottomButton
@onready var _first_round:TournamentMenuRound = $MarginContainer/FirstRound
@onready var _winners_1:TournamentMenuRound = $MarginContainer/Winners1
@onready var _winners_2:TournamentMenuRound = $MarginContainer/Winners2
@onready var _winners_3:TournamentMenuRound = $MarginContainer/Winners3
@onready var _losers_1:TournamentMenuRound = $MarginContainer/Losers1
@onready var _losers_2:TournamentMenuRound = $MarginContainer/Losers2
@onready var _losers_3:TournamentMenuRound = $MarginContainer/Losers3
@onready var _losers_4:TournamentMenuRound = $MarginContainer/Losers4
@onready var _losers_5:TournamentMenuRound = $MarginContainer/Losers5
@onready var _final_race:TournamentMenuRound = $MarginContainer/FinalRace
@onready var _winner:Control = $MarginContainer/Winner
@onready var _winner_label:Label = $MarginContainer/Winner/WinnerLabel

var game_state:GameState = null

func _on_start_match_button_pressed() -> void:
	
	game_state.num_players = game_state.active_tournament.get_next_match().player_profiles.size()
	start_match_requested.emit()

func _on_return_to_menu_button_pressed() -> void:
	
	return_to_menu_requested.emit()

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects class to have a reference to GameState.")
		return
		
	if (game_state.active_tournament == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects an active tournament to be set on GameState.")
		return
	
	_bottom_button.grab_focus()
	
	if (game_state.active_tournament.winner != null):
		_top_label.text = "WINNER"
		_bottom_button.text = "Return to Main Menu"
		_bottom_button.pressed.connect(_on_return_to_menu_button_pressed)
		_winner_label.text = game_state.active_tournament.winner.name.to_upper() + " WINS!"
		_winner.visible = true
		return
	
	match (game_state.active_tournament.round_index):
		-1:
			pass
		0:
			_top_label.text = "FIRST ROUND"
			_bottom_button.text = "START MATCH"
			_bottom_button.pressed.connect(_on_start_match_button_pressed)
			_first_round.show_round(game_state.active_tournament)
		1:
			_top_label.text = "LOSERS DIVISION 1"
			_bottom_button.text = "START MATCH"
			_bottom_button.pressed.connect(_on_start_match_button_pressed)
			_losers_1.show_round(game_state.active_tournament)
		2:
			_top_label.text = "WINNERS DIVISION 1"
			_bottom_button.text = "START MATCH"
			_bottom_button.pressed.connect(_on_start_match_button_pressed)
			_winners_1.show_round(game_state.active_tournament)
		3:
			_top_label.text = "LOSERS DIVISION 2"
			_bottom_button.text = "START MATCH"
			_bottom_button.pressed.connect(_on_start_match_button_pressed)
			_losers_2.show_round(game_state.active_tournament)
		4:
			_top_label.text = "WINNERS DIVISION 2"
			_bottom_button.text = "START MATCH"
			_bottom_button.pressed.connect(_on_start_match_button_pressed)
			_winners_2.show_round(game_state.active_tournament)
		5:
			_top_label.text = "LOSERS DIVISION 3"
			_bottom_button.text = "START MATCH"
			_bottom_button.pressed.connect(_on_start_match_button_pressed)
			_losers_3.show_round(game_state.active_tournament)
		6:
			_top_label.text = "WINNERS DIVISION 3"
			_bottom_button.text = "START MATCH"
			_bottom_button.pressed.connect(_on_start_match_button_pressed)
			_winners_3.show_round(game_state.active_tournament)
		7:
			_top_label.text = "LOSERS DIVISION 4"
			_bottom_button.text = "START MATCH"
			_bottom_button.pressed.connect(_on_start_match_button_pressed)
			_losers_4.show_round(game_state.active_tournament)
		8:
			_top_label.text = "LOSERS DIVISION 5"
			_bottom_button.text = "START MATCH"
			_bottom_button.pressed.connect(_on_start_match_button_pressed)
			_losers_5.show_round(game_state.active_tournament)
		9:
			_top_label.text = "FINAL RACE"
			_bottom_button.text = "START MATCH"
			_bottom_button.pressed.connect(_on_start_match_button_pressed)
			_final_race.show_round(game_state.active_tournament)
		_:
			pass

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
