class_name BoostPadRow extends Node3D

const BOOST_PAD_SPAWN_CHANCE:float = 0.25

@onready var _boost_pad_scene:PackedScene = preload("res://road/boost_pad.tscn")

func _ready() -> void:
	
	var i:int = -4
	while (i <= 4):
		if (randf_range(0.0, 1.0) < BOOST_PAD_SPAWN_CHANCE):
			var pad:BoostPad = _boost_pad_scene.instantiate()
			self.add_child(pad)
			pad.position.x = i * 3
			# Do not spawn pads next to each other.
			i += 1
		i += 1
