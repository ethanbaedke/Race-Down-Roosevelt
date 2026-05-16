class_name RacerVehicle extends Node3D

# This must be set when a racer vehicle is instantiated.
var racer:RacerObject = null

var speed:float = 0

func calculate_speed() -> float:
	
	return speed

func _ready() -> void:
	
	if (racer == null):
		RdrLogger.warn(self, "Racer object not set. Creating default instance.")
		racer = RacerObject.new()
		
	# NOTE: Testing only.
	speed = randi_range(1, 4)
