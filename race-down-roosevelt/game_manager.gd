class_name GameManager extends Node

@onready var _player_count_selection_scene:PackedScene = preload("res://menus/player_count_selection.tscn")
@onready var _vehicle_selection_1p_scene:PackedScene = preload("res://menus/vehicle_selection_1p.tscn")
@onready var _vehicle_selection_2p_scene:PackedScene = preload("res://menus/vehicle_selection_2p.tscn")
@onready var _vehicle_selection_3p_scene:PackedScene = preload("res://menus/vehicle_selection_3p.tscn")
@onready var _vehicle_selection_4p_scene:PackedScene = preload("res://menus/vehicle_selection_4p.tscn")
@onready var _race_scene:PackedScene = preload("res://race/race.tscn")

var _player_count_selection:PlayerCountSelection = null
var _vehicle_selection:VehicleSelection = null
var _race:Race = null

func _ready() -> void:

	while (true):
		await _start_single_race()
		await _race.ready_for_cleanup
		_race.queue_free()

func _start_single_race() -> void:
	
	RdrLogger.log(self, "Starting single race.")
	
	# Have the user select the number of players they want in the game.
	_player_count_selection = _player_count_selection_scene.instantiate()
	self.add_child(_player_count_selection)
	var player_count:int = await _player_count_selection.count_chosen
	if (player_count == 0):
		RdrLogger.fatal(self, _start_single_race.get_method() + " recieved invalid player count of " + str(player_count) + ". Must be 1-4.")
		return
	_player_count_selection.queue_free()
	
	# Have players select their vehicles.
	match (player_count):
		1:
			_vehicle_selection = _vehicle_selection_1p_scene.instantiate()
		2:
			_vehicle_selection = _vehicle_selection_2p_scene.instantiate()
		3:
			_vehicle_selection = _vehicle_selection_3p_scene.instantiate()
		4:
			_vehicle_selection = _vehicle_selection_4p_scene.instantiate()
		_:
			RdrLogger.fatal(self, _start_single_race.get_method() + " recieved invalid player count of " + str(player_count) + ". Must be 1-4.")
			return
	self.add_child(_vehicle_selection)
	var racers:Array[RacerObject] = await _vehicle_selection.all_players_ready
	_vehicle_selection.queue_free()
	
	# Start the race.
	var params:RaceParameters = RaceParameters.new()
	params.racer_objects = racers
	_race = _race_scene.instantiate()
	_race.race_parameters = params
	self.add_child(_race)
	_race.setup_race()
