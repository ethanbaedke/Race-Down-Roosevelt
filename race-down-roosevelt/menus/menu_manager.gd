class_name MenuManager extends Control

signal ready_for_race

enum MenuType {
	NONE,
	MAIN_MENU,
	PLAYER_COUNT_SELECTION,
	VEHICLE_SELECTION,
}

const CAMERA_OFFSET:Vector2 = Vector2(1920.0 * 0.5, 1080.0 * 0.5)

@onready var _camera:Camera2D = $Camera2D

@onready var _main_menu_scene:PackedScene = preload("res://menus/main_menu.tscn")
@onready var _player_count_selection_scene:PackedScene = preload("res://menus/player_count_selection.tscn")
@onready var _vehicle_selection_1p_scene:PackedScene = preload("res://menus/vehicle_selection_1p.tscn")
@onready var _vehicle_selection_2p_scene:PackedScene = preload("res://menus/vehicle_selection_2p.tscn")
@onready var _vehicle_selection_3p_scene:PackedScene = preload("res://menus/vehicle_selection_3p.tscn")
@onready var _vehicle_selection_4p_scene:PackedScene = preload("res://menus/vehicle_selection_4p.tscn")

var _main_menu:MainMenu = null
var _player_count_selection:PlayerCountSelection = null
var _vehicle_selection:VehicleSelection = null

var game_state:GameState = null

var _next_menu_position:Vector2 = Vector2.ZERO

# TODO: Cleanup old menu.
# TODO: Keep stack of old menu types to allow back navigation from any menu.
# TODO: Disable old input/input-navigation from previous menu IMMEDIATELY after the menu begins moving.
func _go_to_new_menu(type:MenuType) -> void:
	
	var new_menu:Control = null
	match (type):
		MenuType.NONE:
			return
		MenuType.MAIN_MENU:
			new_menu = _setup_main_menu()
		MenuType.PLAYER_COUNT_SELECTION:
			new_menu = _setup_player_count_selection()
		MenuType.VEHICLE_SELECTION:
			new_menu = _setup_vehicle_selection()
			
	if (new_menu != null):
		self.add_child(new_menu)
		new_menu.position = _next_menu_position
		_camera.position = _next_menu_position + CAMERA_OFFSET
		_next_menu_position.x += 1920.0

#region Main Menu

func _setup_main_menu() -> Control:
	
	_main_menu = _main_menu_scene.instantiate()
	_main_menu.single_race_selected.connect(_on_main_menu_single_race_selected)
	return _main_menu
	
func _on_main_menu_single_race_selected() -> void:
	
	_go_to_new_menu(MenuType.PLAYER_COUNT_SELECTION)
	
#endregion

#region Player Count Selection

func _setup_player_count_selection() -> Control:
	
	_player_count_selection = _player_count_selection_scene.instantiate()
	_player_count_selection.count_chosen.connect(_on_player_count_selection_count_chosen)
	return _player_count_selection

func _on_player_count_selection_count_chosen(count:int) -> void:
	
	game_state.num_players = count
	_go_to_new_menu(MenuType.VEHICLE_SELECTION)

#endregion

#region Vehicle Selection

func _setup_vehicle_selection() -> Control:
	
	match (game_state.num_players):
		1:
			_vehicle_selection = _vehicle_selection_1p_scene.instantiate()
		2:
			_vehicle_selection = _vehicle_selection_2p_scene.instantiate()
		3:
			_vehicle_selection = _vehicle_selection_3p_scene.instantiate()
		4:
			_vehicle_selection = _vehicle_selection_4p_scene.instantiate()
		_:
			RdrLogger.fatal(self, _setup_vehicle_selection.get_method() + " expects num_players to be between 1-4 on GameState. num_players is " + str(game_state.num_players))
			return
	
	if (_vehicle_selection == null):
		RdrLogger.fatal(self, _setup_vehicle_selection.get_method() + " could not create the vehicle selection scene.")
		return
	
	_vehicle_selection.all_players_ready.connect(_on_vehicle_selection_all_players_ready)
	return _vehicle_selection

func _on_vehicle_selection_all_players_ready(racer_objects:Array[RacerObject]) -> void:
	
	game_state.racer_objects = racer_objects
	ready_for_race.emit()

#endregion

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects the class to have a GameState reference.")
		return
	
	_go_to_new_menu(MenuType.MAIN_MENU)
