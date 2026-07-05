@tool
class_name SizeFitterControl extends Control

func _ready() -> void:
	resized.connect(_update_slot_sizes)
	_update_slot_sizes()

func _update_slot_sizes() -> void:
	self.custom_minimum_size = Vector2(size.y, 0.0)
