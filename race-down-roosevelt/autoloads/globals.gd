extends Node

@onready var racer_vehicle_scenes:Array[PackedScene] = [
	preload("res://vehicles/racer_vehicles/ambulance.tscn"),
	preload("res://vehicles/racer_vehicles/deliver_truck_flat.tscn"),
	preload("res://vehicles/racer_vehicles/firetruck.tscn"),
	preload("res://vehicles/racer_vehicles/race_car.tscn"),
	preload("res://vehicles/racer_vehicles/sedan.tscn"),
	preload("res://vehicles/racer_vehicles/sports_car.tscn")
]

func get_random_racer_vehicle() -> PackedScene:
	
	var index:int = randi_range(0, racer_vehicle_scenes.size() - 1)
	return racer_vehicle_scenes[index]
