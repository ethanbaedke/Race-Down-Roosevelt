class_name RaceProgressTracker extends PanelContainer

@onready var _my_texture:TextureRect = $Control/MyProgressTexture
@onready var _other_textures:Array[TextureRect] = [
	$Control/OtherProgressTexture,
	$Control/OtherProgressTexture2,
	$Control/OtherProgressTexture3,
]

var _race:Race = null
var _owning_vehicle:RacerVehicle = null
var _other_vehicles:Array[RacerVehicle] = []

func initialize(race:Race, owning_vehicle:RacerVehicle) -> void:
	
	# Set references to race and racers.
	_race = race
	_owning_vehicle = owning_vehicle
	for vehicle:RacerVehicle in _race.racer_vehicles:
		if (vehicle != _owning_vehicle):
			_other_vehicles.append(vehicle)
	
	# Load textures.
	_my_texture.texture = _owning_vehicle.racer.profile.icon
	for i:int in range(_other_textures.size()):
		if (i < _other_vehicles.size()):
			_other_textures[i].texture = _other_vehicles[i].racer.profile.icon
		else:
			_other_textures[i].visible = false

func _update_texture_positions() -> void:
	
	var owner_percent:float = _race.get_vehicle_progress(_owning_vehicle)
	_update_texture_position(_my_texture, owner_percent)
	
	for i:int in range(_other_vehicles.size()):
		var other_percent:float = _race.get_vehicle_progress(_other_vehicles[i])
		_update_texture_position(_other_textures[i], other_percent)

func _update_texture_position(texture:TextureRect, percent:float) -> void:
	
	texture.position.x = lerp(0.0, self.size.x, percent) - 10.0

func _process(delta: float) -> void:
	
	if (_race == null || _race.race_in_progress == false):
		return
	
	_update_texture_positions()
