extends Node

const AI_RACER_NAMES:Array[String] = [
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

const PROFILE_PICTURES:Array[CompressedTexture2D] = [
	preload("res://profiles/skull_and_crossbones_profile_picture.png")
]

@onready var racer_vehicle_data:Array[RacerVehicleData] = [
	preload("res://vehicles/racer_vehicles/honda_civic_data.tres"),
	preload("res://vehicles/racer_vehicles/subaru_forester_data.tres"),
]

var _ai_profiles:Array[Profile] = []

func get_random_racer_vehicle_data() -> RacerVehicleData:
	
	var index:int = randi_range(0, racer_vehicle_data.size() - 1)
	return racer_vehicle_data[index]

func get_random_unique_ai_profiles(num:int) -> Array[Profile]:
	
	var profiles:Array[Profile] = _ai_profiles.duplicate()
	profiles.shuffle()
	var selected:Array[Profile] = []
	for i:int in range(num):
		if (i < profiles.size()):
			selected.append(profiles[i])
		else:
			selected.append(Profile.new())
	return selected

func _create_ai_profiles() -> void:
	
	if (PROFILE_PICTURES.size() == 0):
		RdrLogger.warn(self, "No profile picture references have been set.")
		return
	
	var pic_ind:int = 0
	for ai_name:String in AI_RACER_NAMES:
		var profile:Profile = Profile.new()
		profile.name = ai_name
		profile.picture = PROFILE_PICTURES[pic_ind]
		pic_ind = (pic_ind + 1) % PROFILE_PICTURES.size()
		_ai_profiles.append(profile)

func _ready() -> void:
	
	_create_ai_profiles()
	
