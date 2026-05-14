class_name Race extends Node3D

@export var race_parameters:RaceParameters = null

@onready var _racer_vehicle_spawn_points:Array[Node3D] = [
	$"RacerVehicleSpawnPoints/1",
	$"RacerVehicleSpawnPoints/2",
	$"RacerVehicleSpawnPoints/3",
	$"RacerVehicleSpawnPoints/4",
]

func setup_race() -> void:
	
	RdrLogger.log(self, "Setting up race.")
	
	_validate_race_parameters()
	_spawn_racer_vehicles()
	
	RdrLogger.log(self, "Race setup complete.")

# This function expects race parameters to be valid, and four racer vehicle spawn points to exist.
func _spawn_racer_vehicles() -> void:
	
	RdrLogger.log(self, "Spawning racer vehicles.")
	
	for i:int in range(4):
		if (race_parameters.racer_objects[i] == null):
			continue
		else:
			var racer:RacerVehicle = race_parameters.racer_objects[i].vehicle.instantiate()
			self.add_child(racer)
			racer.global_position = _racer_vehicle_spawn_points[i].global_position
	
	RdrLogger.log(self, "Racer vehicle spawning complete.")

# Ensure race parameters are set up correctly to be used during race setup.
func _validate_race_parameters() -> void:
	
	if (race_parameters == null):
		# If no race parameters are set, try and load the default race parameters.
		race_parameters = load("res://race/default_race_parameters.tres")
		# If the default race parameters couldn't be found, use an empty resource, which will be handeled below.
		if (race_parameters == null):
			race_parameters = RaceParameters.new()
	
	# If the race parameters show conflicts at this point, they must be resolved so the race can start.
	# We will not back out of a race once it's begun setup.
	if (!race_parameters.validate_parameters()):
		RdrLogger.error(self, "Race parameters were invalid while setting up the race. Forcefully resolving conflicts.")
		race_parameters.force_resolve_conflicts()

func _ready() -> void:
	
	# NOTE: This is temporary. Should be called by whoever creates the race.
	setup_race()
