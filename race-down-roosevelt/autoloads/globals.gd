extends Node

enum DeviceType {
	UNKNOWN,
	KEYBOARD,
	XBOX,
	PLAYSTATION,
	SWITCH
}

const SAVE_DATA_PATH:String = "user://save_data.res"

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

const PROFILE_ICONS:Array[CompressedTexture2D] = [
	preload("res://profiles/skull_and_crossbones_profile_icon.png"),
	preload("res://profiles/gas_mask_profile_icon.png"),
	preload("res://profiles/diamond_profile_icon.png"),
	preload("res://profiles/sword_profile_icon.png"),
	preload("res://profiles/wrench_profile_icon.png"),
	preload("res://profiles/slime_profile_icon.png"),
	preload("res://profiles/fireball_profile_icon.png"),
	preload("res://profiles/flower_profile_icon.png"),
	preload("res://profiles/pizza_profile_icon.png"),
]

@onready var racer_vehicle_data:Array[RacerVehicleData] = [
	preload("res://vehicles/racer_vehicles/honda_civic_data.tres"),
	preload("res://vehicles/racer_vehicles/subaru_forester_data.tres"),
	preload("res://vehicles/racer_vehicles/jeep_wrangler_data.tres"),
	preload("res://vehicles/racer_vehicles/cybertruck_data.tres")
]

func device_type_from_index(device_index:int) -> DeviceType:
	
	match (device_index):
		-2:
			return DeviceType.UNKNOWN
		-1:
			return DeviceType.KEYBOARD
		_:
			for device:int in Input.get_connected_joypads():
				if (device == device_index):
					var device_name:String = Input.get_joy_name(device).to_lower()
					if (device_name.contains("xinput")):
						return DeviceType.XBOX
					elif (device_name.contains("dualsense")):
						return DeviceType.PLAYSTATION
					elif (device_name.contains("nintendo")):
						return DeviceType.SWITCH
					else:
						return DeviceType.UNKNOWN
			return DeviceType.UNKNOWN

func get_random_racer_vehicle_data() -> RacerVehicleData:
	
	var index:int = randi_range(0, racer_vehicle_data.size() - 1)
	return racer_vehicle_data[index]

func get_random_unique_ai_profiles(num:int) -> Array[Profile]:
	
	var name_ind:int = 0
	var shuffled_names:Array[String] = AI_RACER_NAMES.duplicate()
	shuffled_names.shuffle()
	var icon_ind:int = 0
	var shuffled_icons:Array[CompressedTexture2D] = PROFILE_ICONS.duplicate()
	shuffled_icons.shuffle()
	
	var ai_profiles:Array[Profile] = []
	for i:int in range(num):
		var new_profile:Profile = Profile.new()
		
		new_profile.name = shuffled_names[name_ind]
		name_ind = (name_ind + 1) % shuffled_names.size()
		
		new_profile.icon = shuffled_icons[icon_ind]
		icon_ind = (icon_ind + 1) % shuffled_icons.size()
		
		ai_profiles.append(new_profile)

	return ai_profiles
	
