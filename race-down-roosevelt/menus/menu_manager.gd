class_name MenuManager extends Node3D

signal ready_for_race

enum MenuType {
	NONE,
	MAIN_MENU,
	PLAYER_COUNT_SELECTION,
	VEHICLE_SELECTION,
	MANAGE_PROFILES,
	EDIT_PROFILE,
	TOURNAMENT_START,
	TOURNAMENT_SETUP,
	TOURNAMENT_MENU,
	TOURNAMENT_CONTINUE,
	SETTINGS,
}

@onready var _ui_parent:Control = $CanvasLayer/Control
@onready var _fade_player:AnimationPlayer = $FadePlayer
@onready var _garage:Node3D = $Garage
@onready var _garage_cam:Camera3D = $Camera3D

@onready var _main_menu_scene:PackedScene = preload("res://menus/main_menu.tscn")
@onready var _player_count_selection_scene:PackedScene = preload("res://menus/player_count_selection.tscn")
@onready var _vehicle_selection_1p_scene:PackedScene = preload("res://menus/vehicle_selection_1p.tscn")
@onready var _vehicle_selection_2p_scene:PackedScene = preload("res://menus/vehicle_selection_2p.tscn")
@onready var _vehicle_selection_3p_scene:PackedScene = preload("res://menus/vehicle_selection_3p.tscn")
@onready var _vehicle_selection_4p_scene:PackedScene = preload("res://menus/vehicle_selection_4p.tscn")
@onready var _manage_profiles_scene:PackedScene = preload("res://menus/manage_profiles.tscn")
@onready var _edit_profile_scene:PackedScene = preload("res://menus/edit_profile.tscn")
@onready var _tournament_start_scene:PackedScene = preload("res://menus/tournament_start.tscn")
@onready var _tournament_setup_scene:PackedScene = preload("res://menus/tournament_setup.tscn")
@onready var _tournament_menu_scene:PackedScene = preload("res://menus/tournament_menu.tscn")
@onready var _tournament_continue_scene:PackedScene = preload("res://menus/tournament_continue.tscn")
@onready var _settings_scene:PackedScene = preload("res://menus/settings.tscn")

var _main_menu:MainMenu = null
var _player_count_selection:PlayerCountSelection = null
var _vehicle_selection:VehicleSelection = null
var _manage_profiles:ManageProfiles = null
var _edit_profile:EditProfile = null
var _tournament_start:TournamentStart = null
var _tournament_setup:TournamentSetup = null
var _tournament_menu:TournamentMenu = null
var _tournament_continue:TournamentContinue = null
var _settings:Settings = null

var game_state:GameState = null

var _menu_type_stack:Array[MenuType] = []
var _current_menu:Control = null
var _menu_queued_for_cleanup:Control = null
var _next_menu_position:Vector2 = Vector2.ZERO
var _previous_menu_position:Vector2 = Vector2(-1920.0 * 2.0, 0.0)
var _ui_parent_target_position:Vector2 = Vector2(1920.0, 0.0)

# TODO: Cleanup old menu.
# TODO: Keep stack of old menu types to allow back navigation from any menu.
# TODO: Disable old input/input-navigation from previous menu IMMEDIATELY after the menu begins moving.
# Returns the newely created menu.
func _go_to_new_menu(type:MenuType, back_navigate:bool = false) -> Control:
	
	# Do not allow navigation to a menu we are already on.
	if (_menu_type_stack.size() > 0 && _menu_type_stack[_menu_type_stack.size() - 1] == type):
		return null
	
	# If we are going forward, append our new menu type to our stack.
	if (!back_navigate):
		_menu_type_stack.append(type)
	else:
		if (_menu_type_stack.size() < 2):
			return null
		# If we are going backwards, remove our current page from the front of the stack and navigate back to the previous page on the stack.
		else:
			_menu_type_stack.remove_at(_menu_type_stack.size() - 1)
			type = _menu_type_stack[_menu_type_stack.size() - 1]
	
	# Disable input navigation on the old menu so we can't get back to it during the transition.
	if (_current_menu != null):
		_current_menu.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
		_menu_queued_for_cleanup = _current_menu
	
	var new_menu:Control = null
	match (type):
		MenuType.NONE:
			return null
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
		MenuType.TOURNAMENT_START:
			new_menu = _setup_tournament_start()
		MenuType.TOURNAMENT_SETUP:
			new_menu = _setup_tournament_setup()
		MenuType.TOURNAMENT_MENU:
			new_menu = _setup_tournament_menu()
		MenuType.TOURNAMENT_CONTINUE:
			new_menu = _setup_tournament_continue()
		MenuType.SETTINGS:
			new_menu = _setup_settings()
			
	if (new_menu != null):
		_current_menu = new_menu
		_ui_parent.add_child(new_menu)
		if (!back_navigate):
			new_menu.position = _next_menu_position
			# UI has to move the opposite direction.
			_ui_parent_target_position.x -= 1920.0
			_next_menu_position.x += 1920.0
			_previous_menu_position.x += 1920.0
		else:
			new_menu.position = _previous_menu_position
			# UI has to move the opposite direction.
			_ui_parent_target_position.x += 1920.0
			_next_menu_position.x -= 1920.0
			_previous_menu_position.x -= 1920.0
	
	return new_menu

# DEPRECATED
#func _queue_menu_for_cleanup(menu:Control) -> void:
#	
#	# This is lazy, but is probably fine given our use case.
#	await get_tree().create_timer(0.25).timeout
#	menu.queue_free()

# Returns the newely created menu.
func _fade_to_new_menu(new_menu_type:MenuType, garage_enabled:bool, back_navigate:bool = false) -> Control:
	
	_current_menu.process_mode = Node.PROCESS_MODE_DISABLED
	_fade_player.play("fade_out")
	await _fade_player.animation_finished
	
	# Switch menus and disable the garage.
	var new_menu:Control = null
	if (!back_navigate):
		new_menu = _go_to_new_menu(new_menu_type)
	else:
		new_menu = _go_to_new_menu(MenuType.NONE, true)
	
	if (new_menu == null):
		return null
	
	_garage.visible = garage_enabled
	_garage_cam.current = garage_enabled
	
	# Fade in.
	_ui_parent.position = _ui_parent_target_position
	new_menu.process_mode = Node.PROCESS_MODE_DISABLED
	_fade_player.play("fade_in")
	await _fade_player.animation_finished
	new_menu.process_mode = Node.PROCESS_MODE_INHERIT
	
	return new_menu

#region Main Menu

func _setup_main_menu() -> Control:
	
	_main_menu = _main_menu_scene.instantiate()
	_main_menu.single_race_selected.connect(_on_main_menu_single_race_selected)
	_main_menu.manage_profiles_selected.connect(_on_main_menu_manage_profiles_selected)
	_main_menu.tournament_selected.connect(_on_tournament_selected)
	_main_menu.settings_selected.connect(_on_settings_selected)
	return _main_menu
	
func _on_main_menu_single_race_selected() -> void:
	
	_go_to_new_menu(MenuType.PLAYER_COUNT_SELECTION)
	
func _on_main_menu_manage_profiles_selected() -> void:
	
	_go_to_new_menu(MenuType.MANAGE_PROFILES)
	
func _on_tournament_selected() -> void:
	
	_go_to_new_menu(MenuType.TOURNAMENT_START)
	
func _on_settings_selected() -> void:
	
	_go_to_new_menu(MenuType.SETTINGS)

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
	await _fade_to_new_menu(MenuType.VEHICLE_SELECTION, false)

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
	
	await _fade_to_new_menu(MenuType.NONE, true, true)

func _on_vehicle_selection_all_players_ready(racer_objects:Array[RacerObject]) -> void:
	
	game_state.racer_objects = racer_objects
	
	_current_menu.process_mode = Node.PROCESS_MODE_DISABLED
	_fade_player.play("fade_out")
	await _fade_player.animation_finished
	
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

#region Tournament Start

func _setup_tournament_start() -> Control:
	
	_tournament_start = _tournament_start_scene.instantiate()
	_tournament_start.game_state = game_state
	_tournament_start.back_requested.connect(_on_tournament_start_back_requested)
	_tournament_start.new_tournament_requested.connect(_on_tournament_start_new_tournament_requested)
	_tournament_start.continue_tournament_requested.connect(_on_tournament_start_continue_tournament_requested)
	return _tournament_start

func _on_tournament_start_back_requested() -> void:
	
	_go_to_new_menu(MenuType.NONE, true)
	
func _on_tournament_start_new_tournament_requested() -> void:
	
	_go_to_new_menu(MenuType.TOURNAMENT_SETUP)

func _on_tournament_start_continue_tournament_requested() -> void:
	
	_go_to_new_menu(MenuType.TOURNAMENT_CONTINUE)

#endregion

#region Tournament Setup

func _setup_tournament_setup() -> Control:
	
	_tournament_setup = _tournament_setup_scene.instantiate()
	_tournament_setup.game_state = game_state
	_tournament_setup.back_requested.connect(_on_tournament_setup_back_requested)
	_tournament_setup.start_tournament_requested.connect(_on_tournament_setup_start_tournament_requested)
	return _tournament_setup

func _on_tournament_setup_back_requested() -> void:
	
	_go_to_new_menu(MenuType.NONE, true)

func _on_tournament_setup_start_tournament_requested() -> void:
	
	await _fade_to_new_menu(MenuType.TOURNAMENT_MENU, false)
	# It doesn't make sense to go back to tournament setup. Remove it from the stack after the tournament menu is created.
	_menu_type_stack.remove_at(_menu_type_stack.size() - 2)

#endregion

#region Tournament Menu

func _setup_tournament_menu() -> Control:
	
	_tournament_menu = _tournament_menu_scene.instantiate()
	_tournament_menu.game_state = game_state
	_tournament_menu.back_requested.connect(_on_tournament_menu_back_requested)
	_tournament_menu.start_match_requested.connect(_on_tournament_menu_start_match_requested)
	_tournament_menu.return_to_menu_requested.connect(_on_tournament_menu_return_to_menu_requested)
	return _tournament_menu

func _on_tournament_menu_back_requested() -> void:
	
	game_state.active_tournament = null
	await _fade_to_new_menu(MenuType.NONE, true, true)

func _on_tournament_menu_start_match_requested() -> void:
	
	_go_to_new_menu(MenuType.VEHICLE_SELECTION)

func _on_tournament_menu_return_to_menu_requested() -> void:
	
	# Replace menu stack to hold main menu and tournament menu so we can navigate straight back to the main menu.
	_menu_type_stack.clear()
	_menu_type_stack.append(MenuType.MAIN_MENU)
	_menu_type_stack.append(MenuType.TOURNAMENT_MENU)
	await _fade_to_new_menu(MenuType.NONE, true, true)

#endregion

#region Tournament Continue

func _setup_tournament_continue() -> Control:
	
	_tournament_continue = _tournament_continue_scene.instantiate()
	_tournament_continue.game_state = game_state
	_tournament_continue.back_requested.connect(_on_tournament_continue_back_requested)
	_tournament_continue.continue_tournament_requested.connect(_on_tournament_continue_continue_tournament_requested)
	return _tournament_continue

func _on_tournament_continue_back_requested() -> void:
	
	_go_to_new_menu(MenuType.NONE, true)

func _on_tournament_continue_continue_tournament_requested() -> void:
	
	await _fade_to_new_menu(MenuType.TOURNAMENT_MENU, false)

#endregion

#region Settings

func _setup_settings() -> Control:
	
	_settings = _settings_scene.instantiate()
	_settings.game_state = game_state
	_settings.back_requested.connect(_on_tournament_start_back_requested)
	return _settings

func _on_settings_back_requested() -> void:
	
	_go_to_new_menu(MenuType.NONE, true)

#endregion

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects the class to have a GameState reference.")
		return
	
	if (game_state.active_tournament == null):
		_garage.visible = true
		_garage_cam.current = true
		_go_to_new_menu(MenuType.MAIN_MENU)
	else:
		# If we are currently in a tournament, we should begin on the tournament menu, with our menu stack set accordingly.
		_garage.visible = false
		_garage_cam.current = false
		_menu_type_stack.append(MenuType.MAIN_MENU)
		_menu_type_stack.append(MenuType.TOURNAMENT_START)
		_go_to_new_menu(MenuType.TOURNAMENT_MENU)
	
	_current_menu.process_mode = Node.PROCESS_MODE_DISABLED
	_fade_player.play("fade_in")
	await _fade_player.animation_finished
	_current_menu.process_mode = Node.PROCESS_MODE_INHERIT

func _process(delta:float) -> void:
	
	var ui_move_dir:Vector2 = _ui_parent_target_position - _ui_parent.position
	var vel:float = ui_move_dir.length() * delta * 20.0
	vel = min(vel, 100.0)
	vel = max(vel, 1.0)
	var new_pos:Vector2 = _ui_parent.position + (ui_move_dir.normalized() * vel)
	if ((_ui_parent_target_position - new_pos).dot(ui_move_dir) <= 0):
		_ui_parent.position = _ui_parent_target_position
		if (_menu_queued_for_cleanup != null):
			_menu_queued_for_cleanup.queue_free()
	else:
		_ui_parent.position = new_pos
