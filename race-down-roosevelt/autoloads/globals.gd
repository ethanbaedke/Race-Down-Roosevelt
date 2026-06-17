extends Node

const PRESET_NAMES:Array[String] = [
	"Turbo Tim",
	"Nitro Nikki",
	"Speedy Steve",
	"Drift King Dave",
	"Brake Check Bob",
	"Donut Dan",
	"Tommy Torque",
	#"Quick Quinn",
	#"Fast Freddie",
	"Zach Zoom",
	#"Hasty Hank",
	"Blazing Ben",
	"Reckless Rex",
	"Powerslide Paige",
	"Steve Skid",
	"Apex Andy",
	#"Wild Wendy",
	"Gearbox Gary",
	"Piston Pete",
	"Redline Ruby",
	"Downshift Danielle",
	"Rocket Rachel",
	"Lightning Lily",
	"Bullet Bella"
]

@onready var racer_vehicle_data:Array[RacerVehicleData] = [
	preload("res://vehicles/racer_vehicles/honda_civic_data.tres"),
	preload("res://vehicles/racer_vehicles/subaru_forester_data.tres"),
]

func get_random_racer_vehicle_data() -> RacerVehicleData:
	
	var index:int = randi_range(0, racer_vehicle_data.size() - 1)
	return racer_vehicle_data[index]

func get_random_unique_names(num:int) -> Array[String]:
	
	var names:Array[String] = PRESET_NAMES.duplicate()
	names.shuffle()
	var selected:Array[String] = []
	for i:int in range(num):
		if (i < names.size()):
			selected.append(names[i])
		else:
			selected.append("Racer")
	return selected
