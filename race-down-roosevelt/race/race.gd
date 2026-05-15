class_name Race extends Node3D

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

var _racer_vehicles:Array[RacerVehicle] = []

func setup_race() -> void:
	
	RdrLogger.log(self, "Setting up race.")
	
	_validate_race_parameters()
	_spawn_racer_vehicles()
	_setup_player_viewports()
	
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
		RdrLogger.error(self, _setup_player_viewports.get_method() + " expects at least one racer to be player controlled.")
		get_tree().quit(1)
	
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
			RdrLogger.error(self, _setup_player_viewports.get_method() + " expects 1-4 racer vehicles to exist.")
			get_tree().quit(1)
	
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
	
	for i:int in range(4):
		if (race_parameters.racer_objects[i] == null):
			continue
		else:
			var racer:RacerVehicle = race_parameters.racer_objects[i].vehicle.instantiate()
			racer.racer = race_parameters.racer_objects[i]
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

func _ready() -> void:
	
	# NOTE: This is temporary. Should be called by whoever creates the race.
	setup_race()
