class_name MenuManager extends Control

signal ready_for_race

enum MenuType {
	NONE,
	MAIN_MENU,
	PLAYER_COUNT_SELECTION,
	VEHICLE_SELECTION,
	MANAGE_PROFILES,
	EDIT_PROFILE,
	TOURNEMENT_START,
	TOURNEMENT_SETUP,
	TOURNEMENT_MENU,
}

const CAMERA_OFFSET:Vector2 = Vector2(1920.0 * 0.5, 1080.0 * 0.5)

@onready var _camera:Camera2D = $Camera2D

@onready var _main_menu_scene:PackedScene = preload("res://menus/main_menu.tscn")
@onready var _player_count_selection_scene:PackedScene = preload("res://menus/player_count_selection.tscn")
@onready var _vehicle_selection_1p_scene:PackedScene = preload("res://menus/vehicle_selection_1p.tscn")
@onready var _vehicle_selection_2p_scene:PackedScene = preload("res://menus/vehicle_selection_2p.tscn")
@onready var _vehicle_selection_3p_scene:PackedScene = preload("res://menus/vehicle_selection_3p.tscn")
@onready var _vehicle_selection_4p_scene:PackedScene = preload("res://menus/vehicle_selection_4p.tscn")
@onready var _manage_profiles_scene:PackedScene = preload("res://menus/manage_profiles.tscn")
@onready var _edit_profile_scene:PackedScene = preload("res://menus/edit_profile.tscn")
@onready var _tournement_start_scene:PackedScene = preload("res://menus/tournement_start.tscn")
@onready var _tournement_setup_scene:PackedScene = preload("res://menus/tournement_setup.tscn")
@onready var _tournement_menu_scene:PackedScene = preload("res://menus/tournement_menu.tscn")

var _main_menu:MainMenu = null
var _player_count_selection:PlayerCountSelection = null
var _vehicle_selection:VehicleSelection = null
var _manage_profiles:ManageProfiles = null
var _edit_profile:EditProfile = null
var _tournement_start:TournementStart = null
var _tournement_setup:TournementSetup = null
var _tournement_menu:TournementMenu = null

var game_state:GameState = null

var _menu_type_stack:Array[MenuType] = []
var _current_menu:Control = null
var _next_menu_position:Vector2 = Vector2.ZERO
var _previous_menu_position:Vector2 = Vector2(-1920.0 * 2.0, 0.0)

# TODO: Cleanup old menu.
# TODO: Keep stack of old menu types to allow back navigation from any menu.
# TODO: Disable old input/input-navigation from previous menu IMMEDIATELY after the menu begins moving.
func _go_to_new_menu(type:MenuType, back_navigate:bool = false) -> void:
	
	# If we are going forward, append our new menu type to our stack.
	if (!back_navigate):
		_menu_type_stack.append(type)
	else:
		if (_menu_type_stack.size() < 2):
			return
		# If we are going backwards, remove our current page from the front of the stack and navigate back to the previous page on the stack.
		else:
			_menu_type_stack.remove_at(_menu_type_stack.size() - 1)
			type = _menu_type_stack[_menu_type_stack.size() - 1]
	
	# Disable input navigation on the old menu so we can't get back to it during the transition.
	if (_current_menu != null):
		_current_menu.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
		_queue_menu_for_cleanup(_current_menu)
	
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
		MenuType.MANAGE_PROFILES:
			new_menu = _setup_manage_profiles()
		MenuType.EDIT_PROFILE:
			new_menu = _setup_edit_profile()
		MenuType.TOURNEMENT_START:
			new_menu = _setup_tournement_start()
		MenuType.TOURNEMENT_SETUP:
			new_menu = _setup_tournement_setup()
		MenuType.TOURNEMENT_MENU:
			new_menu = _setup_tournement_menu()
			
	if (new_menu != null):
		_current_menu = new_menu
		self.add_child(new_menu)
		if (!back_navigate):
			new_menu.position = _next_menu_position
			_camera.position = _next_menu_position + CAMERA_OFFSET
			_next_menu_position.x += 1920.0
			_previous_menu_position.x += 1920.0
		else:
			new_menu.position = _previous_menu_position
			_camera.position = _previous_menu_position + CAMERA_OFFSET
			_next_menu_position.x -= 1920.0
			_previous_menu_position.x -= 1920.0

func _queue_menu_for_cleanup(menu:Control) -> void:
	
	# This is lazy, but is probably fine given our use case.
	await get_tree().create_timer(0.25).timeout
	menu.queue_free()

#region Main Menu

func _setup_main_menu() -> Control:
	
	_main_menu = _main_menu_scene.instantiate()
	_main_menu.single_race_selected.connect(_on_main_menu_single_race_selected)
	_main_menu.manage_profiles_selected.connect(_on_main_menu_manage_profiles_selected)
	_main_menu.tournement_selected.connect(_on_tournement_selected)
	return _main_menu
	
func _on_main_menu_single_race_selected() -> void:
	
	_go_to_new_menu(MenuType.PLAYER_COUNT_SELECTION)
	
func _on_main_menu_manage_profiles_selected() -> void:
	
	_go_to_new_menu(MenuType.MANAGE_PROFILES)
	
func _on_tournement_selected() -> void:
	
	_go_to_new_menu(MenuType.TOURNEMENT_START)
	
#endregion

#region Player Count Selection

func _setup_player_count_selection() -> Control:
	
	_player_count_selection = _player_count_selection_scene.instantiate()
	_player_count_selection.back_requested.connect(_on_player_count_selection_back_requested)
	_player_count_selection.count_chosen.connect(_on_player_count_selection_count_chosen)
	return _player_count_selection

func _on_player_count_selection_back_requested() -> void:
	
	_go_to_new_menu(MenuType.NONE, true)

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
	
	_vehicle_selection.set_game_state(game_state)
	# TODO: Make "back requested" an interface between all menus
	_vehicle_selection.back_requested.connect(_on_vehicle_selection_back_requested)
	_vehicle_selection.all_players_ready.connect(_on_vehicle_selection_all_players_ready)
	return _vehicle_selection

func _on_vehicle_selection_back_requested() -> void:
	
	_go_to_new_menu(MenuType.NONE, true)

func _on_vehicle_selection_all_players_ready(racer_objects:Array[RacerObject]) -> void:
	
	game_state.racer_objects = racer_objects
	ready_for_race.emit()

#endregion

#region Manage Profiles

func _setup_manage_profiles() -> Control:
	
	_manage_profiles = _manage_profiles_scene.instantiate()
	_manage_profiles.game_state = game_state
	_manage_profiles.back_requested.connect(_on_manage_profiles_back_requested)
	_manage_profiles.add_new_requested.connect(_on_manage_profiles_add_new_requested)
	_manage_profiles.edit_profile_requested.connect(_on_manage_profiles_edit_profile_requested)
	return _manage_profiles

func _on_manage_profiles_back_requested() -> void:
	
	_go_to_new_menu(MenuType.NONE, true)

func _on_manage_profiles_add_new_requested() -> void:
	
	_go_to_new_menu(MenuType.EDIT_PROFILE)
	
func _on_manage_profiles_edit_profile_requested() -> void:
	
	_go_to_new_menu(MenuType.EDIT_PROFILE)

#endregion

#region Edit Profile

func _setup_edit_profile() -> Control:
	
	_edit_profile = _edit_profile_scene.instantiate()
	_edit_profile.game_state = game_state
	_edit_profile.back_requested.connect(_on_add_profile_back_requested)
	return _edit_profile

func _on_add_profile_back_requested() -> void:
	
	_go_to_new_menu(MenuType.NONE, true)

#endregion

#region Tournement Start

func _setup_tournement_start() -> Control:
	
	_tournement_start = _tournement_start_scene.instantiate()
	_tournement_start.game_state = game_state
	_tournement_start.back_requested.connect(_on_tournement_start_back_requested)
	_tournement_start.new_tournement_requested.connect(_on_tournement_start_new_tournement_requested)
	return _tournement_start

func _on_tournement_start_back_requested() -> void:
	
	_go_to_new_menu(MenuType.NONE, true)
	
func _on_tournement_start_new_tournement_requested() -> void:
	
	_go_to_new_menu(MenuType.TOURNEMENT_SETUP)

#endregion

#region Tournement Setup

func _setup_tournement_setup() -> Control:
	
	_tournement_setup = _tournement_setup_scene.instantiate()
	_tournement_setup.game_state = game_state
	_tournement_setup.back_requested.connect(_on_tournement_setup_back_requested)
	_tournement_setup.start_tournement_requested.connect(_on_tournement_setup_start_tournement_requested)
	return _tournement_setup

func _on_tournement_setup_back_requested() -> void:
	
	_go_to_new_menu(MenuType.NONE, true)

func _on_tournement_setup_start_tournement_requested() -> void:
	
	_go_to_new_menu(MenuType.TOURNEMENT_MENU)
	# It doesn't make sense to go back to tournement setup. Remove it from the stack after the tournement menu is created.
	_menu_type_stack.remove_at(_menu_type_stack.size() - 2)

#endregion

#region Tournement Menu

func _setup_tournement_menu() -> Control:
	
	_tournement_menu = _tournement_menu_scene.instantiate()
	_tournement_menu.game_state = game_state
	_tournement_menu.back_requested.connect(_on_tournement_menu_back_requested)
	return _tournement_menu

func _on_tournement_menu_back_requested() -> void:
	
	_go_to_new_menu(MenuType.NONE, true)

#endregion

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects the class to have a GameState reference.")
		return
	
	_go_to_new_menu(MenuType.MAIN_MENU)
