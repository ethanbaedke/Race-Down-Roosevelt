class_name RacerVehicleData extends Resource

@export var scene:PackedScene = null

@warning_ignore("narrowing_conversion")
@export_range(RacerVehicle.MIN_TOP_SPEED, RacerVehicle.MAX_TOP_SPEED) var top_speed:int = (RacerVehicle.MIN_TOP_SPEED + RacerVehicle.MAX_TOP_SPEED) * 0.5
@warning_ignore("narrowing_conversion")
@export_range(RacerVehicle.MIN_ACCELERATION, RacerVehicle.MAX_ACCELERATION) var acceleration:int = (RacerVehicle.MIN_ACCELERATION + RacerVehicle.MAX_ACCELERATION) * 0.5
@warning_ignore("narrowing_conversion")
@export_range(RacerVehicle.MIN_DURABILITY, RacerVehicle.MAX_DURABILITY) var durability:int = (RacerVehicle.MIN_DURABILITY + RacerVehicle.MAX_DURABILITY) * 0.5
@warning_ignore("narrowing_conversion")
@export_range(RacerVehicle.MIN_WEIGHT, RacerVehicle.MAX_WEIGHT) var weight:int = (RacerVehicle.MIN_WEIGHT + RacerVehicle.MAX_WEIGHT) * 0.5
