extends Node3D

@onready var _race:Race = $Race

func _ready() -> void:
	
	var game_state:GameState = GameState.new()
	game_state.num_players = 1
	var racer_1:RacerObject = RacerObject.new()
	racer_1.vehicle_data = load("res://vehicles/racer_vehicles/honda_civic_data.tres")
	racer_1.device_index = -1
	game_state.racer_objects = [
		racer_1,
	]
	_race.game_state = game_state
	_race.setup_race()
