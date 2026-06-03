class_name Race extends Node3D

# Called when the race is ready to be cleaned up.
signal ready_for_cleanup

const NUM_LANES:int = 9
const LANE_SPACING:float = 3.0
# Number of road rows to be placed before the finish line.
const RACE_LENGTH:int = 100
const LEADERBOARD_DISPLAY_TIME:float = 5.0

@onready var _leaderboard:Scoreboard = $Scoreboard

var _racer_vehicles:Array[RacerVehicle] = []

var _leaderboard_data:Array[RacerObject] = []

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
		RdrLogger.spam_log(self, vehicle.racer.name + " z-pos: " + str(vehicle.position.z))

func _on_finish_line_crossed(racer:RacerVehicle) -> void:
	
	# If this racer somehow crossed twice, ignore them.
	if (_leaderboard_data.has(racer.racer)):
		return
	
	racer.input_enabled = false
	
	_leaderboard_data.append(racer.racer)
	
	# All but one racer have finished, append the missing racer and end the race.
	if (_leaderboard_data.size() == _racer_vehicles.size() - 1):
		var last_place:RacerObject = null
		for vehicle:RacerVehicle in _racer_vehicles:
			if (!_leaderboard_data.has(vehicle.racer)):
				last_place = vehicle.racer
				break
		if (last_place == null):
			RdrLogger.warn(self, "Race ending since one racer remains but no racer can be found that isn't already on the leaderboard.")
		else:
			_leaderboard_data.append(last_place)
		_finish_race()
		
	# At least two racers are left.
	else:
		# If all remaining racers are AI, add them to the leaderboard based on position and end the race.
		var all_ai:bool = true
		for vehicle:RacerVehicle in _racer_vehicles:
			if (!_leaderboard_data.has(vehicle.racer) && vehicle.racer.device_index != -2):
				all_ai = false
				break
		if (all_ai):
			var remaining:Array[RacerVehicle] = []
			for vehicle:RacerVehicle in _racer_vehicles:
				if (!_leaderboard_data.has(vehicle.racer)):
					# Keep remaining in order of distance to finish line while adding vehicles.
					var i:int = 0
					while (i < remaining.size() && remaining[i].position.z < vehicle.position.z):
						i += 1
					remaining.insert(i, vehicle)
			for vehicle:RacerVehicle in remaining:
				_leaderboard_data.append(vehicle.racer)
			_finish_race()
	
# Expects leaderboard to be filled out correctly.
func _finish_race() -> void:
	
	RdrLogger.log(self, "Race finished.")
	for i:int in range(_leaderboard_data.size()):
		RdrLogger.log(self, "Position " + str(i + 1) + ": " + _leaderboard_data[i].name + ".")
		
	_leaderboard.load_data(_leaderboard_data)
	await get_tree().create_timer(LEADERBOARD_DISPLAY_TIME).timeout
	ready_for_cleanup.emit()

#region Road/Traffic Management

# Distance in front of the 1st place racer road should be placed up to.
const ROAD_PLACE_DIST:int = 100
# Distance behind the last place racer road needs to be to be cleaned up.
const ROAD_CLEANUP_DIST:int = 100
# Z-distance between road rows.
const ROAD_ROW_SPACING:float = 3.0

const TRAFFIC_VEHICLES:Array[PackedScene] = [
	preload("res://vehicles/traffic_vehicles/delivery_truck.tscn"),
	preload("res://vehicles/traffic_vehicles/garbage_truck.tscn"),
	preload("res://vehicles/traffic_vehicles/hatchback.tscn"),
	preload("res://vehicles/traffic_vehicles/pickup_truck.tscn"),
	preload("res://vehicles/traffic_vehicles/suv.tscn"),
	preload("res://vehicles/traffic_vehicles/tractor.tscn")
]
const TRAFFIC_SPAWN_COOLDOWN:int = 10

@onready var _road_parent:Node3D = $Road
@onready var _traffic_parent:Node3D = $Traffic

@onready var _road_asphalt:MeshInstance3D = $Road/Asphalt
@onready var _road_left_barrier:MeshInstance3D = $Road/LeftBarrier
@onready var _road_right_barrier:MeshInstance3D = $Road/RightBarrier

var traffic_spawn_chance:float = 0.1

var _finish_line_scene:PackedScene = preload("res://road/road_row_finish_line.tscn")

# Tracks how many road rows need to be placed before a lane is allowed to spawn another traffic vehicle.
# Lanes with a value of 0 at their index are allowed to spawn a vehicle.
var _traffic_spawn_cooldowns:Array[int] = []
# Holds arrays of recycled traffic vehicle instances. Each array is a different traffic vehicle type and mimics the traffic vehicles array.
var _traffic_vehicle_pool:Array[Array] = []
var _active_traffic_vehicle_instances:Array[Node3D] = []
var _active_traffic_vehicle_pool_indices:Array[int] = []

# What z-coordinate the next road row should be spawned at.
var _next_road_row_z:float = ROAD_ROW_SPACING
var _road_rows_placed:int = 0

func _move_world_back(amount:float) -> void:
	
	for node:Node3D in _road_parent.get_children():
		node.position.z -= amount
	for node:Node3D in _traffic_parent.get_children():
		node.position.z -= amount
	_next_road_row_z -= amount

# Expects traffic spawn cooldowns array to have size equal to the number of lanes.
func _place_traffic_row(z_pos:float) -> void:
	
	if (_traffic_spawn_cooldowns.size() != NUM_LANES):
		RdrLogger.fatal(self, _place_road_row.get_method() + " expects traffic spawn cooldowns array to have size equal to number of lanes.")
	
	# Extend road.
	_road_asphalt.position.z += ROAD_ROW_SPACING / 2
	var asphalt_mesh:PlaneMesh = _road_asphalt.mesh
	asphalt_mesh.size.y += ROAD_ROW_SPACING
	var asphalt_material:StandardMaterial3D = asphalt_mesh.material
	asphalt_material.uv1_scale.y = asphalt_mesh.size.y / 3
	_road_left_barrier.position.z += ROAD_ROW_SPACING / 2
	var left_barrier_mesh:BoxMesh = _road_left_barrier.mesh
	left_barrier_mesh.size.z += ROAD_ROW_SPACING
	_road_right_barrier.position.z += ROAD_ROW_SPACING / 2
	var right_barrier_mesh:BoxMesh = _road_right_barrier.mesh
	right_barrier_mesh.size.z += ROAD_ROW_SPACING
	
	# Spawn traffic.
	for i:int in range(NUM_LANES):
		if (_traffic_spawn_cooldowns[i] == 0):
			# Lane is off cooldown, roll to spawn.
			if (randf_range(0.0, 1.0) <= traffic_spawn_chance):
				var vehicle_ind:int = randi_range(0, TRAFFIC_VEHICLES.size() - 1)
				var vehicle:TrafficVehicle = _get_traffic_vehicle_from_pool(vehicle_ind)
				if (vehicle == null):
					return
				_traffic_spawn_cooldowns[i] = TRAFFIC_SPAWN_COOLDOWN
				vehicle.position.x = ((NUM_LANES - 1 - i) * LANE_SPACING) - (NUM_LANES * LANE_SPACING * 0.5) + (LANE_SPACING * 0.5)
				vehicle.position.z = z_pos
				vehicle.enable_vehicle()
		else:
			# Lane is on cooldown, decrement.
			_traffic_spawn_cooldowns[i] -= 1

# Expects traffic vehicle pool to have size equal to the traffic vehicle array.
func _get_traffic_vehicle_from_pool(index:int) -> TrafficVehicle:
	
	if (_traffic_vehicle_pool.size() != TRAFFIC_VEHICLES.size()):
		RdrLogger.fatal(self, _get_traffic_vehicle_from_pool.get_method() + " expects traffic vehicle pool to have size equal to the traffic vehicle array.")
		return null
		
	if (index < 0 || index >= _traffic_vehicle_pool.size()):
		RdrLogger.error(self, "Attempting to grab instance from traffic vehicle pool, but index " + str(index) + " is outside the range of the pool.")
		return null
	
	# Pool is empty for this traffic vehicle type, create a new instance.
	if (_traffic_vehicle_pool[index].size() == 0):
		RdrLogger.log(self, "Creating new traffic vehicle instance (total = " + str(_active_traffic_vehicle_instances.size()) + ").")
		var instance:TrafficVehicle = TRAFFIC_VEHICLES[index].instantiate()
		_active_traffic_vehicle_instances.append(instance)
		_active_traffic_vehicle_pool_indices.append(index)
		_traffic_parent.add_child(instance)
		return instance
	# Pool contains an entry for this traffic vehicle, remove and return it.
	else:
		RdrLogger.log(self, "Reusing traffic vehicle instance from pool.")
		var end_ind:int = _traffic_vehicle_pool[index].size() - 1
		var instance:TrafficVehicle = _traffic_vehicle_pool[index][end_ind]
		_active_traffic_vehicle_instances.append(instance)
		_active_traffic_vehicle_pool_indices.append(index)
		_traffic_vehicle_pool[index].remove_at(end_ind)
		return instance

func _place_road_row() -> void:
	
	_place_traffic_row(_next_road_row_z)

func _handle_road_placement() -> void:
	
	if (_road_rows_placed == RACE_LENGTH):
		return
	
	var order:Array[RacerVehicle] = get_racer_order()
	
	# Place road in front of first place racer.
	var first_place_z:float = order[0].position.z
	while (_next_road_row_z - first_place_z < ROAD_PLACE_DIST):
		if (_road_rows_placed < RACE_LENGTH):
			_place_road_row()
			_next_road_row_z += ROAD_ROW_SPACING
			_road_rows_placed += 1
			if (_road_rows_placed == RACE_LENGTH):
				_place_finish_line()
				return
		else:
			_place_finish_line()
			return
	
func _place_finish_line() -> void:
	
	var finish:RoadRowFinishLine = _finish_line_scene.instantiate()
	finish.racer_crossed.connect(_on_finish_line_crossed)
	_road_parent.add_child(finish)
	finish.position.z = _next_road_row_z
	
	# Disable any traffic vehicles beyond the finish line when it spawns.
	for vehicle:TrafficVehicle in _active_traffic_vehicle_instances:
		if (vehicle.global_position.z > finish.global_position.z):
			vehicle.disable_vehicle()

func _handle_cleanup() -> void:
	
	var order:Array[RacerVehicle] = get_racer_order()
	var last_place_z:float = order[order.size() - 1].position.z
	# Anything at or behind this can be cleaned up.
	var cleanup_z:float = last_place_z - ROAD_CLEANUP_DIST
	
	# TODO: Shrink road.
	
	# Pool traffic.
	var i:int = 0
	while (i < _active_traffic_vehicle_instances.size()):
		if (_active_traffic_vehicle_instances[i].position.z < cleanup_z):
			RdrLogger.log(self, "Recycling traffic vehicle instance.")
			_traffic_vehicle_pool[_active_traffic_vehicle_pool_indices[i]].append(_active_traffic_vehicle_instances[i])
			_active_traffic_vehicle_instances.remove_at(i)
			_active_traffic_vehicle_pool_indices.remove_at(i)
		else:
			i += 1
	
#endregion

#region Race Setup

const CAMERA_CONTROLLER_POSITION:Vector3 = Vector3(0.0, 2.0, -4.0)
const CAMERA_CONTROLLER_ROTATION:Vector3 = Vector3(deg_to_rad(-10.0), deg_to_rad(180.0), 0.0)

@export var race_parameters:RaceParameters = null

@onready var _racer_vehicle_spawn_points:Array[Node3D] = [
	$"RacerVehicleSpawnPoints/1",
	$"RacerVehicleSpawnPoints/2",
	$"RacerVehicleSpawnPoints/3",
	$"RacerVehicleSpawnPoints/4",
]

# 1-player viewport objects.
@onready var _viewport_setup_1p:Control = $ViewportSetup1p
@onready var _p1_cam_1p:Camera3D = $ViewportSetup1p/P1SubViewportContainer/SubViewport/P1Cam1p

# 2-player viewport objects.
@onready var _viewport_setup_2p:Control = $ViewportSetup2p
@onready var _p1_cam_2p:Camera3D = $ViewportSetup2p/SplitContainer/P1SubViewportContainer/SubViewport/P1Cam2p
@onready var _p2_cam_2p:Camera3D = $ViewportSetup2p/SplitContainer/P2SubViewportContainer/SubViewport/P2Cam2p

# 3-player viewport objects.
@onready var _viewport_setup_3p:Control = $ViewportSetup3p
@onready var _p1_cam_3p:Camera3D = $ViewportSetup3p/SplitContainer/P1SubViewportContainer/SubViewport/P1Cam3p
@onready var _p2_cam_3p:Camera3D = $ViewportSetup3p/SplitContainer/SplitContainer/P2SubViewportContainer/SubViewport/P2Cam3p
@onready var _p3_cam_3p:Camera3D = $ViewportSetup3p/SplitContainer/SplitContainer/P3SubViewportContainer/SubViewport/P3Cam3p

# 4-player viewport objects.
@onready var _viewport_setup_4p:Control = $ViewportSetup4p
@onready var _p1_cam_4p:Camera3D = $ViewportSetup4p/SplitContainer/SplitContainerTop/P1SubViewportContainer/SubViewport/P1Cam4p
@onready var _p2_cam_4p:Camera3D = $ViewportSetup4p/SplitContainer/SplitContainerTop/P2SubViewportContainer/SubViewport/P2Cam4p
@onready var _p3_cam_4p:Camera3D = $ViewportSetup4p/SplitContainer/SplitContainerBottom/P3SubViewportContainer/SubViewport/P3Cam4p
@onready var _p4_cam_4p:Camera3D = $ViewportSetup4p/SplitContainer/SplitContainerBottom/P4SubViewportContainer/SubViewport/P4Cam4p

func setup_race() -> void:
	
	RdrLogger.log(self, "Setting up race.")
	
	_traffic_spawn_cooldowns.resize(NUM_LANES)
	_traffic_vehicle_pool.resize(TRAFFIC_VEHICLES.size())
	
	# TODO: Reset asphalt/barrier mesh and material properties here.
	
	_validate_race_parameters()
	_spawn_racer_vehicles()
	_setup_player_viewports()
	
	# Enable input for all racers
	for vehicle:RacerVehicle in _racer_vehicles:
		vehicle.input_enabled = true
	
	RdrLogger.log(self, "Race setup complete.")

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
	match player_vehicles.size():
		1:
			_viewport_setup_1p.visible = true
			cameras.append(_p1_cam_1p)
		2:
			_viewport_setup_2p.visible = true
			cameras.append(_p1_cam_2p)
			cameras.append(_p2_cam_2p)
		3:
			_viewport_setup_3p.visible = true
			cameras.append(_p1_cam_3p)
			cameras.append(_p2_cam_3p)
			cameras.append(_p3_cam_3p)
		4:
			_viewport_setup_4p.visible = true
			cameras.append(_p1_cam_4p)
			cameras.append(_p2_cam_4p)
			cameras.append(_p3_cam_4p)
			cameras.append(_p4_cam_4p)
		_:
			RdrLogger.fatal(self, _setup_player_viewports.get_method() + " expects 1-4 racer vehicles to exist.")
	
	# Attach cameras to all sub-viewports and associated camera controllers to all player controlled vehicles.
	for i:int in range(player_vehicles.size()):
		var controller:CameraController = CameraController.new()
		controller.camera = cameras[i]
		player_vehicles[i].add_child(controller)
		controller.position = CAMERA_CONTROLLER_POSITION
		controller.rotation = CAMERA_CONTROLLER_ROTATION
		
	RdrLogger.log(self, "Player viewport setup complete.")

# This function expects race parameters to be valid, and four racer vehicle spawn points to exist.
func _spawn_racer_vehicles() -> void:
	
	RdrLogger.log(self, "Spawning racer vehicles.")
	
	if (!race_parameters.validate_parameters()):
		RdrLogger.fatal(self, _spawn_racer_vehicles.get_method() + " expects race parameters to be valid.")
	if (_racer_vehicle_spawn_points.size() != 4):
		RdrLogger.fatal(self, _spawn_racer_vehicles.get_method() + " expects four vehicle spawn points to exist.")
	
	for i:int in range(4):
		if (race_parameters.racer_objects[i] == null):
			continue
		else:
			var racer:RacerVehicle = race_parameters.racer_objects[i].vehicle.instantiate()
			racer.race = self
			racer.racer = race_parameters.racer_objects[i]
			racer.lane_number = (i + 1) * 2
			_racer_vehicles.append(racer)
			self.add_child(racer)
			racer.global_position = _racer_vehicle_spawn_points[i].global_position
	
	RdrLogger.log(self, "Racer vehicle spawning complete.")

# Ensure race parameters are set up correctly to be used during race setup.
func _validate_race_parameters() -> void:
	
	RdrLogger.log(self, "Beginning race parameter validation.")
	
	# Ensure race parameters exist.
	if (race_parameters == null):
		# If no race parameters are set, try and load the default race parameters.
		race_parameters = load("res://race/default_race_parameters.tres")
		# If the default race parameters couldn't be found, use an empty resource, which will be handeled below.
		if (race_parameters == null):
			race_parameters = RaceParameters.new()
	
	# If the race parameters show conflicts at this point, they must be resolved so the race can start.
	# We will not back out of a race once it's begun setup.
	if (!race_parameters.validate_parameters()):
		RdrLogger.error(self, "Race parameters were invalid. Forcefully resolving conflicts.")
		race_parameters.force_resolve_conflicts()
		
	# If all racers are null or AI, replace the first racer with a new one, and give it keyboard controlls.
	# Fully AI races are not supported.
	var all_racers_null_or_ai:bool = true
	for racer:RacerObject in race_parameters.racer_objects:
		if (racer != null && racer.device_index != -2):
			all_racers_null_or_ai = false
			break
	if (all_racers_null_or_ai):
		var racer:RacerObject = RacerObject.new()
		racer.device_index = -1
		race_parameters.racer_objects[0] = racer
		
	# If any racer has a null vehicle, it should be considered a random selection.
	for racer:RacerObject in race_parameters.racer_objects:
		if (racer == null):
			continue
		if (racer.vehicle == null):
			var vehicle_scene:PackedScene = Globals.get_random_racer_vehicle()
			var racer_name:String = racer.name
			var vehicle_name:String = vehicle_scene.get_state().get_node_name(0)
			RdrLogger.log(self, "Assigning random vehicle to " + racer_name + ": " + vehicle_name + ".")
			racer.vehicle = vehicle_scene

	RdrLogger.log(self, "Race parameter validation finished.")

#endregion

func _physics_process(delta: float) -> void:

	_move_racers(delta)
	
	# Cleanup first so pool can be filled before placement happens.
	_handle_cleanup()
	_handle_road_placement()
