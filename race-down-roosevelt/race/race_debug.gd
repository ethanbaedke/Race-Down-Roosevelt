extends Node3D

@onready var _race:Race = $Race

func _ready() -> void:
	
	_race.setup_race()
