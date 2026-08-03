class_name GameManager extends Node

const SKIP_OPENING_ANIMATION:bool = false

@onready var _menu_manager_scene:PackedScene = preload("res://menus/menu_manager.tscn")
@onready var _race_scene:PackedScene = preload("res://race/race.tscn")
@onready var _opening_cutscene_scene:PackedScene = preload("res://opening_cutscene.tscn")

var _menu_manager:MenuManager = null
var _race:Race = null

var _game_state:GameState = null

func _play_opening_animation() -> void:
	
	var cut:OpeningCutscene = _opening_cutscene_scene.instantiate()
	self.add_child(cut)
	await cut.finished
	cut.queue_free()

func _ready() -> void:

	# Try and load save data.
	var save_data:SaveData = null
	if (ResourceLoader.exists(Globals.SAVE_DATA_PATH)):
		save_data = ResourceLoader.load(Globals.SAVE_DATA_PATH)
		if (save_data == null):
			save_data = SaveData.new()
	else:
		save_data = SaveData.new()
		
	_game_state = GameState.new()
	_game_state.save_data = save_data
	
	if (!SKIP_OPENING_ANIMATION):
		await _play_opening_animation()
	
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
		_race.game_state = _game_state
		self.add_child(_race)
		_race.setup_race()
		await _race.play_opening_animation()
		_race.start_race()
		
		# Wait for the race to tell us its ready for cleanup.
		await _race.ready_for_cleanup
		
		# Must clear listeners from previous race to avoid null references in future races.
		AudioSystem3D.clear_listeners()
		
		# Save the order the profiles finished in. May need this below.
		var profile_finish_order:Array[Profile] = []
		for racer:RacerObject in _race.leaderboard_data:
			profile_finish_order.append(racer.profile)
		_race.queue_free()
		
		# If we are in a tournament, report results and go to the next match.
		if (_game_state.active_tournament != null):
			# At this point, next match still references the match we just finished.
			_game_state.active_tournament.get_next_match().finish_order = profile_finish_order
			# Now next match is updated.
			_game_state.active_tournament.go_to_next_match()
			# Now that the next match is set up, save the tournaments state.
			_game_state.save_data.save()
