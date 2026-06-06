extends Node

@onready var racer_vehicle_data:Array[RacerVehicleData] = [
	preload("res://vehicles/racer_vehicles/ambulance_data.tres"),
	preload("res://vehicles/racer_vehicles/delivery_truck_flat_data.tres"),
	preload("res://vehicles/racer_vehicles/firetruck_data.tres"),
	preload("res://vehicles/racer_vehicles/race_car_data.tres"),
	preload("res://vehicles/racer_vehicles/sedan_data.tres"),
	preload("res://vehicles/racer_vehicles/sports_car_data.tres")
]

func get_random_racer_vehicle_data() -> RacerVehicleData:
	
	var index:int = randi_range(0, racer_vehicle_data.size() - 1)
	return racer_vehicle_data[index]
