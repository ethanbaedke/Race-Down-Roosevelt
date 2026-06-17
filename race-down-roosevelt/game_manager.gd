class_name GameManager extends Node

@onready var _menu_manager_scene:PackedScene = preload("res://menus/menu_manager.tscn")
@onready var _race_scene:PackedScene = preload("res://race/race.tscn")

var _menu_manager:MenuManager = null
var _race:Race = null

var _game_state:GameState = null

func _ready() -> void:

	_game_state = GameState.new()

	while (true):
		# Create the menu manager.
		_menu_manager = _menu_manager_scene.instantiate()
		_menu_manager.game_state = _game_state
		self.add_child(_menu_manager)
		
		# Wait for menu manager to tell us to start a race.
		await _menu_manager.ready_for_race
		_menu_manager.queue_free()
		
		# Start the race.
		_race = _race_scene.instantiate()
		# TODO: Replace racer parameters with passing game state directly to the race.
		var params:RaceParameters = RaceParameters.new()
		params.racer_objects = _game_state.racer_objects
		_race.race_parameters = params
		self.add_child(_race)
		_race.setup_race()
		
		# Wait for the race to tell us its ready for cleanup.
		await _race.ready_for_cleanup
		_race.queue_free()
