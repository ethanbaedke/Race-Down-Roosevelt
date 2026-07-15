class_name Race extends Node3D

# Called when the race is ready to be cleaned up.
signal ready_for_cleanup

const NUM_LANES:int = 9
const LANE_SPACING:float = 3.0
# Number of road rows to be placed before the finish line.
const RACE_LENGTH:int = 150
const LEADERBOARD_DISPLAY_TIME:float = 5.0

var game_state:GameState = null

@onready var _leaderboard:Leaderboard = $Leaderboard
@onready var _race_theme_player:AudioStreamPlayer3D = $RaceThemePlayer
@onready var _race_intro_player:AudioStreamPlayer3D = $RaceIntroPlayer
@onready var _day_night_player:AnimationPlayer = $DayNightAnimationPlayer
@onready var _opening_anim_lights:Node3D = $OpeningAnimationPlayer/OpeningAnimLights

var leaderboard_data:Array[RacerObject] = []
var _race_in_progress:bool = false
var _racer_vehicles:Array[RacerVehicle] = []
var _finish_line_placed:bool = false

# Returns all racer vehicles in order of 1st place -> 4th place.
func get_racer_order() -> Array[RacerVehicle]:
	
	var _ordered_vehicles:Array[RacerVehicle] = _racer_vehicles.duplicate()
	_ordered_vehicles.sort_custom(func(v1:RacerVehicle, v2:RacerVehicle) -> bool:
		return v1.position.z > v2.position.z)
	return _ordered_vehicles

# Expects at least one racer vehicle to exist.
func _move_racers(delta:float) -> void:
	
	if (_racer_vehicles.size() == 0):
		RdrLogger.fatal(self, _move_racers.get_method() + " expects at least one racer vehicle to exist.")
	
	# Have each racer vehicle calculate its speed and move them accordingly.
	for vehicle:RacerVehicle in _racer_vehicles:
		var speed:float = vehicle.calculate_speed(delta)
		vehicle.position.z += speed * delta
	
	# Move all racers and world back to keep racers centered around z=0.
	var order:Array[RacerVehicle] = get_racer_order()
	var to_move_back:float = order[0].position.z
	if (order.size() > 1):
		var z_first:float = order[0].position.z
		var z_last:float = order[order.size() - 1].position.z
		var diff:float = z_first - z_last
		to_move_back = z_last + (diff * 0.5)
	for vehicle:RacerVehicle in _racer_vehicles:
		vehicle.position.z -= to_move_back
	
	_move_world_back(to_move_back)
		
	# Debugging
	for vehicle:RacerVehicle in order:
		RdrLogger.spam_log(self, vehicle.racer.profile.name + " z-pos: " + str(vehicle.position.z))

func _on_finish_line_crossed(racer:RacerVehicle) -> void:
	
	# If this racer somehow crossed twice, ignore them.
	if (leaderboard_data.has(racer.racer)):
		return
	
	racer.input_enabled = false
	
	leaderboard_data.append(racer.racer)
	
	# All but one racer have finished, append the missing racer and end the race.
	if (leaderboard_data.size() == _racer_vehicles.size() - 1):
		var last_place:RacerObject = null
		for vehicle:RacerVehicle in _racer_vehicles:
			if (!leaderboard_data.has(vehicle.racer)):
				last_place = vehicle.racer
				break
		if (last_place == null):
			RdrLogger.warn(self, "Race ending since one racer remains but no racer can be found that isn't already on the leaderboard.")
		else:
			leaderboard_data.append(last_place)
		_finish_race()
		
	# At least two racers are left.
	else:
		# If all remaining racers are AI, add them to the leaderboard based on position and end the race.
		var all_ai:bool = true
		for vehicle:RacerVehicle in _racer_vehicles:
			if (!leaderboard_data.has(vehicle.racer) && vehicle.racer.device_index != -2):
				all_ai = false
				break
		if (all_ai):
			var remaining:Array[RacerVehicle] = []
			for vehicle:RacerVehicle in _racer_vehicles:
				if (!leaderboard_data.has(vehicle.racer)):
					# Keep remaining in order of distance to finish line while adding vehicles.
					var i:int = 0
					while (i < remaining.size() && remaining[i].position.z < vehicle.position.z):
						i += 1
					remaining.insert(i, vehicle)
			for vehicle:RacerVehicle in remaining:
				leaderboard_data.append(vehicle.racer)
			_finish_race()
	
# Expects leaderboard to be filled out correctly.
func _finish_race() -> void:
	
	RdrLogger.log(self, "Race finished.")
	for i:int in range(leaderboard_data.size()):
		RdrLogger.log(self, "Position " + str(i + 1) + ": " + leaderboard_data[i].profile.name + ".")
	
	if (_race_theme_player.get_playback_position() < 188.30):
		_race_theme_player.seek(188.30)
	
	_leaderboard.load_data(leaderboard_data)
	
	await get_tree().create_timer(LEADERBOARD_DISPLAY_TIME).timeout
	ready_for_cleanup.emit()

#region Road/Traffic Management

# Distance in front of the 1st place racer road should be placed up to.
const ROAD_PLACE_DIST:int = 200
# Distance behind the last place racer road needs to be to be cleaned up.
const ROAD_CLEANUP_DIST:int = 20
# Z-distance between road rows.
const ROAD_ROW_SPACING:float = 3.0

const TRAFFIC_SPAWN_COOLDOWN:int = 10

@export var traffic_vehicle_pool:RandomNodePool = null
@export var road_object_pool:RandomNodePool = null

@onready var _road_parent:Node3D = $Road
@onready var _traffic_parent:Node3D = $Traffic

@onready var _road_asphalt:MeshInstance3D = $Road/Asphalt
@onready var _road_left_barrier:MeshInstance3D = $Road/LeftBarrier
@onready var _road_right_barrier:MeshInstance3D = $Road/RightBarrier

var traffic_spawn_chance:float = 0.2
var road_object_spawn_chance:float = 1.0

var _finish_line_scene:PackedScene = preload("res://road/road_row_finish_line.tscn")

# Tracks how many road rows need to be placed before a lane is allowed to spawn another traffic vehicle.
# Lanes with a value of 0 at their index are allowed to spawn a vehicle.
var _traffic_spawn_cooldowns:Array[int] = []
# Ensure two road objects are not spawned back-to-back.
var _road_object_spawned_last_row:bool = false

# What z-coordinate the next road row should be spawned at.
var _next_road_row_z:float = ROAD_ROW_SPACING
var _road_rows_placed:int = 0

var _street_lights_on:bool = false

func set_street_lights_lit(value:bool) -> void:
	
	_street_lights_on = value
	
	var light_rows:Array[StreetLightRow] = []
	for child:Node3D in _road_parent.get_children():
		if (child is StreetLightRow):
			light_rows.append(child)
	
	for row:StreetLightRow in light_rows:
		await row.set_lit(value)
		await get_tree().create_timer(0.05).timeout

func _move_world_back(amount:float) -> void:
	
	for node:Node3D in _road_parent.get_children():
		node.position.z -= amount
	for node:Node3D in _traffic_parent.get_children():
		node.position.z -= amount
	_next_road_row_z -= amount

# Expects traffic spawn cooldowns array to have size equal to the number of lanes.
func _handle_traffic_vehicle_placement(z_pos:float) -> void:
	
	if (_finish_line_placed):
		return
	if (_traffic_spawn_cooldowns.size() != NUM_LANES):
		RdrLogger.fatal(self, _handle_traffic_vehicle_placement.get_method() + " expects traffic spawn cooldowns array to have size equal to number of lanes.")
		return
	if (!_race_in_progress):
		return
	
	# Spawn traffic.
	for i:int in range(NUM_LANES):
		if (_traffic_spawn_cooldowns[i] == 0):
			# Lane is off cooldown, roll to spawn.
			if (randf_range(0.0, 1.0) <= traffic_spawn_chance):
				var vehicle:TrafficVehicle = traffic_vehicle_pool.get_node()
				if (vehicle == null):
					return
				_traffic_spawn_cooldowns[i] = TRAFFIC_SPAWN_COOLDOWN
				_traffic_parent.add_child(vehicle)
				vehicle.position.x = ((NUM_LANES - 1 - i) * LANE_SPACING) - (NUM_LANES * LANE_SPACING * 0.5) + (LANE_SPACING * 0.5)
				vehicle.position.z = z_pos
				vehicle.enable_vehicle()
		else:
			# Lane is on cooldown, decrement.
			_traffic_spawn_cooldowns[i] -= 1

func _handle_road_object_placement(z_pos:float) -> void:
	
	if (_finish_line_placed):
		return
	
	if (_road_object_spawned_last_row):
		_road_object_spawned_last_row = false
		return
	
	# During setup, don't spawn objects in the first 5 rows.
	if (!_race_in_progress && z_pos <= 30.0):
		return
	
	if (randf_range(0.0, 1.0) > road_object_spawn_chance):
		return
	
	var obj:Node3D = road_object_pool.get_node()
	if (obj == null):
		return
	_road_parent.add_child(obj)
	obj.position.z = z_pos
	_road_object_spawned_last_row = true
	
	if (obj is StreetLightRow):
		obj.set_lit(_street_lights_on)

# Preferably, amount is a multiple of the road row spacing to avoid partial rows.
# Extends in the +z direction (adds road to the front).
func _extend_road(amount:float) -> void:
	_road_asphalt.position.z += amount / 2
	var asphalt_mesh:PlaneMesh = _road_asphalt.mesh
	asphalt_mesh.size.y += amount
	var asphalt_material:StandardMaterial3D = asphalt_mesh.material
	asphalt_material.uv1_scale.y = asphalt_mesh.size.y / 3
	_road_left_barrier.position.z += amount / 2
	var left_barrier_mesh:BoxMesh = _road_left_barrier.mesh
	left_barrier_mesh.size.z += amount
	_road_right_barrier.position.z += amount / 2
	var right_barrier_mesh:BoxMesh = _road_right_barrier.mesh
	right_barrier_mesh.size.z += amount

# Preferably, amount is a multiple of the road row spacing to avoid partial rows.
# Shrinks in the +z direction (removes road from the back).
func _shrink_road(amount:float) -> void:
	_road_asphalt.position.z += amount / 2
	var asphalt_mesh:PlaneMesh = _road_asphalt.mesh
	asphalt_mesh.size.y -= amount
	var asphalt_material:StandardMaterial3D = asphalt_mesh.material
	asphalt_material.uv1_scale.y = asphalt_mesh.size.y / 3
	_road_left_barrier.position.z += amount / 2
	var left_barrier_mesh:BoxMesh = _road_left_barrier.mesh
	left_barrier_mesh.size.z -= amount
	_road_right_barrier.position.z += amount / 2
	var right_barrier_mesh:BoxMesh = _road_right_barrier.mesh
	right_barrier_mesh.size.z -= amount

func _handle_road_placement() -> void:
	
	var order:Array[RacerVehicle] = get_racer_order()
	
	# Place road in front of first place racer.
	var first_place_z:float = order[0].position.z
	while (_next_road_row_z - first_place_z < ROAD_PLACE_DIST):
		if (_road_rows_placed != RACE_LENGTH):
			_extend_road(ROAD_ROW_SPACING)
			_handle_traffic_vehicle_placement(_next_road_row_z)
			_handle_road_object_placement(_next_road_row_z)
			_next_road_row_z += ROAD_ROW_SPACING
			_road_rows_placed += 1
		else:
			_extend_road(ROAD_ROW_SPACING)
			_place_finish_line()
			_road_rows_placed += 1
	
func _place_finish_line() -> void:
	
	var finish:RoadRowFinishLine = _finish_line_scene.instantiate()
	finish.racer_crossed.connect(_on_finish_line_crossed)
	_road_parent.add_child(finish)
	finish.position.z = _next_road_row_z
	
	# Disable any traffic vehicles beyond the finish line when it spawns.
	traffic_vehicle_pool.run_cleanup(func (n:Node3D) -> bool:
		return n.global_position.z > finish.global_position.z
	)
	
	_finish_line_placed = true

func _handle_cleanup() -> void:
	
	var order:Array[RacerVehicle] = get_racer_order()
	var last_place_z:float = order[order.size() - 1].position.z
	# Anything at or behind this is eligable to be cleaned up.
	# Some objects may have their own conditions determining if they can be cleaned up.
	var cleanup_z:float = last_place_z - ROAD_CLEANUP_DIST
	
	# Shrink road.
	var asphalt_mesh:PlaneMesh = _road_asphalt.mesh
	var road_back:float = _road_asphalt.position.z - (asphalt_mesh.size.y * 0.5)
	var to_shrink:float = cleanup_z - road_back
	# Purposefully cast float->int->float to ensure our final shrink amount is a multiple of the road row size.
	# This isn't necessary, but I would prefer the road to never have a partial row.
	var num_rows_to_shrink:int = (to_shrink / ROAD_ROW_SPACING) as int
	var to_shrink_final:float = num_rows_to_shrink * ROAD_ROW_SPACING

	_shrink_road(to_shrink_final)
	
	# Cleanup traffic vehicles.
	traffic_vehicle_pool.run_cleanup(func (n:Node3D) -> bool:
		var vehicle:TrafficVehicle = n as TrafficVehicle
		return vehicle.available_for_cleanup && n.position.z < cleanup_z
	)
	
	# Cleanup road objects.
	road_object_pool.run_cleanup(func (n:Node3D) -> bool:
		return n.position.z < cleanup_z
	)

#endregion

#region Race Setup

@onready var _racer_vehicle_spawn_points:Array[Node3D] = [
	$"RacerVehicleSpawnPoints/1",
	$"RacerVehicleSpawnPoints/2",
	$"RacerVehicleSpawnPoints/3",
	$"RacerVehicleSpawnPoints/4",
]

@onready var _opening_animation_player:AnimationPlayer = $OpeningAnimationPlayer
@onready var _sky_text_animation_player:AnimationPlayer = $SkyTextAnimationPlayer

# 1-player viewport objects.
@onready var _viewport_setup_1p:Control = $ViewportSetup1p
@onready var _p1_cam_1p:Camera3D = $ViewportSetup1p/P1SubViewportContainer/SubViewport/P1Cam1p
@onready var _p1_hud_1p:RacePlayerHud = $ViewportSetup1p/P1SubViewportContainer/SubViewport/RacePlayerHud

# 2-player viewport objects.
@onready var _viewport_setup_2p:Control = $ViewportSetup2p
@onready var _p1_cam_2p:Camera3D = $ViewportSetup2p/SplitContainer/P1SubViewportContainer/SubViewport/P1Cam2p
@onready var _p1_hud_2p:RacePlayerHud = $ViewportSetup2p/SplitContainer/P1SubViewportContainer/SubViewport/RacePlayerHud
@onready var _p2_cam_2p:Camera3D = $ViewportSetup2p/SplitContainer/P2SubViewportContainer/SubViewport/P2Cam2p
@onready var _p2_hud_2p:RacePlayerHud = $ViewportSetup2p/SplitContainer/P2SubViewportContainer/SubViewport/RacePlayerHud

# 3-player viewport objects.
@onready var _viewport_setup_3p:Control = $ViewportSetup3p
@onready var _p1_cam_3p:Camera3D = $ViewportSetup3p/SplitContainer/P1SubViewportContainer/SubViewport/P1Cam3p
@onready var _p1_hud_3p:RacePlayerHud = $ViewportSetup3p/SplitContainer/P1SubViewportContainer/SubViewport/RacePlayerHud
@onready var _p2_cam_3p:Camera3D = $ViewportSetup3p/SplitContainer/SplitContainer/P2SubViewportContainer/SubViewport/P2Cam3p
@onready var _p2_hud_3p:RacePlayerHud = $ViewportSetup3p/SplitContainer/SplitContainer/P2SubViewportContainer/SubViewport/RacePlayerHud
@onready var _p3_cam_3p:Camera3D = $ViewportSetup3p/SplitContainer/SplitContainer/P3SubViewportContainer/SubViewport/P3Cam3p
@onready var _p3_hud_3p:RacePlayerHud = $ViewportSetup3p/SplitContainer/SplitContainer/P3SubViewportContainer/SubViewport/RacePlayerHud

# 4-player viewport objects.
@onready var _viewport_setup_4p:Control = $ViewportSetup4p
@onready var _p1_cam_4p:Camera3D = $ViewportSetup4p/SplitContainer/SplitContainerTop/P1SubViewportContainer/SubViewport/P1Cam4p
@onready var _p1_hud_4p:RacePlayerHud = $ViewportSetup4p/SplitContainer/SplitContainerTop/P1SubViewportContainer/SubViewport/RacePlayerHud
@onready var _p2_cam_4p:Camera3D = $ViewportSetup4p/SplitContainer/SplitContainerTop/P2SubViewportContainer/SubViewport/P2Cam4p
@onready var _p2_hud_4p:RacePlayerHud = $ViewportSetup4p/SplitContainer/SplitContainerTop/P2SubViewportContainer/SubViewport/RacePlayerHud
@onready var _p3_cam_4p:Camera3D = $ViewportSetup4p/SplitContainer/SplitContainerBottom/P3SubViewportContainer/SubViewport/P3Cam4p
@onready var _p3_hud_4p:RacePlayerHud = $ViewportSetup4p/SplitContainer/SplitContainerBottom/P3SubViewportContainer/SubViewport/RacePlayerHud
@onready var _p4_cam_4p:Camera3D = $ViewportSetup4p/SplitContainer/SplitContainerBottom/P4SubViewportContainer/SubViewport/P4Cam4p
@onready var _p4_hud_4p:RacePlayerHud = $ViewportSetup4p/SplitContainer/SplitContainerBottom/P4SubViewportContainer/SubViewport/RacePlayerHud

func setup_race() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, setup_race.get_method() + " expects to have a reference to GameState.")
		return
	
	if (traffic_vehicle_pool == null):
		RdrLogger.warn(self, "Traffic vehicle pool is empty. Creating new instance.")
		traffic_vehicle_pool = RandomNodePool.new()
	traffic_vehicle_pool.initialize()
	if (road_object_pool == null):
		RdrLogger.warn(self, "Road object pool is empty. Creating new instance.")
		road_object_pool = RandomNodePool.new()
	road_object_pool.initialize()
	
	_traffic_spawn_cooldowns.resize(NUM_LANES)
	
	# Create unique copies of the asphalt and barrier meshes here since we'll modify them.
	# This keeps their changes from persisting between races.
	_road_asphalt.mesh = _road_asphalt.mesh.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_road_left_barrier.mesh = _road_left_barrier.mesh.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_road_right_barrier.mesh = _road_right_barrier.mesh.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	
	# If ai racers are enabled, fill them into any open racer slots.
	if (game_state.include_ai_racers):
		var profiles:Array[Profile] = Globals.get_random_unique_ai_profiles(4 - game_state.racer_objects.size())
		for i:int in range(game_state.racer_objects.size(), 4):
			var ai_racer:RacerObject = RacerObject.new()
			ai_racer.profile = profiles[profiles.size() - 1]
			profiles.remove_at(profiles.size() - 1)
			game_state.racer_objects.append(ai_racer)
	
	# If any racer has null vehicle data, give them a random vehicle.
	for racer:RacerObject in game_state.racer_objects:
		if (racer.vehicle_data == null):
			racer.vehicle_data = Globals.get_random_racer_vehicle_data()
			
	# If any racer has a null profile, fill it with an empty object.
	for racer:RacerObject in game_state.racer_objects:
		if (racer.profile == null):
			racer.profile = Profile.new()
	
	# DEPRECATED _validate_race_parameters()
	_spawn_racer_vehicles()
	
	# Do one round of road placement to put initial road down in front of the players.
	_handle_road_placement()
	# We also do one round of cleanup since it handles moving the road back.
	_handle_cleanup()
	
	RdrLogger.log(self, "Race setup complete.")

func play_opening_animation() -> void:
	
	_day_night_player.play("RESET")
	_race_intro_player.play()
	
	_opening_animation_player.play("fade_from_black")
	await _opening_animation_player.animation_finished
	
	_sky_text_animation_player.play("base")
	_opening_animation_player.play("scroll_vehicles")
	await _opening_animation_player.animation_finished
	
	_opening_animation_player.play("fade_to_black")
	await _opening_animation_player.animation_finished
	_sky_text_animation_player.play("RESET")
	
	_setup_player_viewports()
	
	# Flip the nameplates on racers, since they will have been facing the opposite direction for the opening animation.
	# Also set layers on the nameplates so they are invisible on a players own viewport.
	for i:int in range(_racer_vehicles.size()):
		_racer_vehicles[i].nameplate.flip()
		_racer_vehicles[i].nameplate.set_player_number(i + 1)
	
	# Shut off the lights that were being used in the opening animation.
	_opening_anim_lights.visible = false
	
	_opening_animation_player.play("fade_from_black")
	await _opening_animation_player.animation_finished
	
	_day_night_player.play("RESET")
	_day_night_player.play("initial_sunrise")
	
	_opening_animation_player.play("countdown")
	await _opening_animation_player.animation_finished
	
	_opening_animation_player.play("go")

func start_race() -> void:
	
	# Enable input for all racers
	for vehicle:RacerVehicle in _racer_vehicles:
		vehicle.input_enabled = true
		# Enable ai controllers for any ai racers.
		if (vehicle.racer.device_index == -2):
			vehicle.ai_controller.enabled = true
	
	_race_in_progress = true
	_race_theme_player.play()
	_day_night_player.play("day_cycle")
	RdrLogger.log(self, "Race started.")

# This function expects there to be 1-4 racer vehicles, with at least one being player controlled.
func _setup_player_viewports() -> void:
	
	RdrLogger.log(self, "Setting up player viewports.")
	
	# Get a list of all player controlled vehicles.
	var player_vehicles:Array[RacerVehicle] = []
	for vehicle:RacerVehicle in _racer_vehicles:
		if (vehicle.racer.device_index == -2):
			continue
		player_vehicles.append(vehicle)
	
	if (player_vehicles.size() == 0):
		RdrLogger.fatal(self, _setup_player_viewports.get_method() + " expects at least one racer to be player controlled.")
	
	# Enable viewport setup that corresponds to the number of players and store sub-viewports that should be used.
	var cameras:Array[Camera3D] = []
	var huds:Array[RacePlayerHud] = []
	match player_vehicles.size():
		1:
			_viewport_setup_1p.visible = true
			cameras.append(_p1_cam_1p)
			huds.append(_p1_hud_1p)
		2:
			_viewport_setup_2p.visible = true
			cameras.append(_p1_cam_2p)
			huds.append(_p1_hud_2p)
			cameras.append(_p2_cam_2p)
			huds.append(_p2_hud_2p)
		3:
			_viewport_setup_3p.visible = true
			cameras.append(_p1_cam_3p)
			huds.append(_p1_hud_3p)
			cameras.append(_p2_cam_3p)
			huds.append(_p2_hud_3p)
			cameras.append(_p3_cam_3p)
			huds.append(_p3_hud_3p)
		4:
			_viewport_setup_4p.visible = true
			cameras.append(_p1_cam_4p)
			huds.append(_p1_hud_4p)
			cameras.append(_p2_cam_4p)
			huds.append(_p2_hud_4p)
			cameras.append(_p3_cam_4p)
			huds.append(_p3_hud_4p)
			cameras.append(_p4_cam_4p)
			huds.append(_p4_hud_4p)
		_:
			RdrLogger.fatal(self, _setup_player_viewports.get_method() + " expects 1-4 racer vehicles to exist.")
	
	# Attach cameras to all sub-viewports and associated camera controllers to all player controlled vehicles.
	for i:int in range(player_vehicles.size()):
		var controller:CameraController = CameraController.new()
		controller.camera = cameras[i]
		player_vehicles[i].set_camera_controller(controller)
		player_vehicles[i].set_hud(huds[i])
		
	RdrLogger.log(self, "Player viewport setup complete.")

# This function expects four racer vehicle spawn points to exist, even if there are not four racers.
func _spawn_racer_vehicles() -> void:
	
	RdrLogger.log(self, "Spawning racer vehicles.")
	
	if (_racer_vehicle_spawn_points.size() != 4):
		RdrLogger.fatal(self, _spawn_racer_vehicles.get_method() + " expects four vehicle spawn points to exist.")
	
	for i:int in range(game_state.racer_objects.size()):
		if (game_state.racer_objects[i] == null):
			continue
		else:
			var racer:RacerVehicle = game_state.racer_objects[i].vehicle_data.scene.instantiate()
			racer.race = self
			racer.racer = game_state.racer_objects[i]
			racer.lane_number = (i + 1) * 2
			_racer_vehicles.append(racer)
			# If this is a player, register them as an audio listener.
			if (game_state.racer_objects[i].device_index != -2):
				AudioSystem3D.register_listener(racer)
			self.add_child(racer)
			# Important for the camera initializing at the correct position.
			racer.set_initial_position(_racer_vehicle_spawn_points[i].global_position)
	
	RdrLogger.log(self, "Racer vehicle spawning complete.")

# DEPRECATED
# Ensure race parameters are set up correctly to be used during race setup.
#func _validate_race_parameters() -> void:
	#
	#RdrLogger.log(self, "Beginning race parameter validation.")
	#
	## Ensure race parameters exist.
	#if (race_parameters == null):
		## If no race parameters are set, try and load the default race parameters.
		#race_parameters = load("res://race/default_race_parameters.tres")
		## If the default race parameters couldn't be found, use an empty resource, which will be handeled below.
		#if (race_parameters == null):
			#race_parameters = RaceParameters.new()
	#
	## If the race parameters show conflicts at this point, they must be resolved so the race can start.
	## We will not back out of a race once it's begun setup.
	#if (!race_parameters.validate_parameters()):
		#RdrLogger.error(self, "Race parameters were invalid. Forcefully resolving conflicts.")
		#race_parameters.force_resolve_conflicts()
		#
	## If all racers are null or AI, replace the first racer with a new one, and give it keyboard controlls.
	## Fully AI races are not supported.
	#var all_racers_null_or_ai:bool = true
	#for racer:RacerObject in race_parameters.racer_objects:
		#if (racer != null && racer.device_index != -2):
			#all_racers_null_or_ai = false
			#break
	#if (all_racers_null_or_ai):
		#RdrLogger.warn(self, "All racers are AI controlled. Replacing first racer with keyboard controlled racer.")
		#var racer:RacerObject = RacerObject.new()
		#racer.device_index = -1
		#race_parameters.racer_objects[0] = racer
		#
	## If any racer has null vehicle data, it should be considered a random selection.
	#for racer:RacerObject in race_parameters.racer_objects:
		#if (racer == null):
			#continue
		#if (racer.vehicle_data == null):
			#var data:RacerVehicleData = Globals.get_random_racer_vehicle_data()
			#var racer_name:String = racer.name
			#var vehicle_name:String = data.scene.get_state().get_node_name(0)
			#RdrLogger.log(self, "Assigning random vehicle to " + racer_name + ": " + vehicle_name + ".")
			#racer.vehicle_data = data
			#
	## If any racer has an empty name, give them a random one.
	#var num_empty_names:int = 0
	#var empty_named_racers:Array[RacerObject]
	#for racer:RacerObject in race_parameters.racer_objects:
		#if (racer.name.is_empty()):
			#num_empty_names += 1
			#empty_named_racers.append(racer)
	#var names:Array[String] = Globals.get_random_unique_names(num_empty_names)
	#for i:int in range(num_empty_names):
		#empty_named_racers[i].name = names[i]
#
	#RdrLogger.log(self, "Race parameter validation finished.")

#endregion

func _physics_process(delta: float) -> void:

	if (!_race_in_progress):
		return

	_move_racers(delta)
	
	# Cleanup first so pool can be filled before placement happens.
	_handle_cleanup()
	_handle_road_placement()
