class_name GasRow extends Node3D

const GAS_SPAWN_CHANCE:float = 0.25

@onready var _gas_scene:PackedScene = preload("res://items/gas.tscn")

func _ready() -> void:
	
	var i:int = -4
	while (i <= 4):
		if (randf_range(0.0, 1.0) < GAS_SPAWN_CHANCE):
			var gas:Gas = _gas_scene.instantiate()
			self.add_child(gas)
			gas.position.x = i * 3
			# Do not spawn pads next to each other.
			i += 1
		i += 1
