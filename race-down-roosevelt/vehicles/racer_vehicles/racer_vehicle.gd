class_name RacerVehicle extends Node3D

# This must be set when a racer vehicle is instantiated.
var racer:RacerObject = null

func _ready() -> void:
	
	if (racer == null):
		RdrLogger.warn(self, "Racer object not set. Creating default instance.")
		racer = RacerObject.new()
