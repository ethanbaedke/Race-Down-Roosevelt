class_name Race extends Node3D

@export var race_parameters:RaceParameters = null

func setup_race() -> void:
	
	RdrLogger.log(self, "Setting up race.")
	
	_validate_race_parameters()
	
	RdrLogger.log(self, "Race setup complete.")

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
