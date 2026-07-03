class_name ItemRow extends Node3D

@onready var _item_scene:PackedScene = preload("res://items/item.tscn")
@onready var _item_data_resources:Array[ItemData] = [
	preload("res://items/boost_item_data.tres")
]

func _ready() -> void:
	
	for i:int in range(-4, 5):
		var item_ind:int = randi_range(0, _item_data_resources.size() - 1)
		var item:Item = _item_scene.instantiate()
		item.item_data = _item_data_resources[item_ind]
		self.add_child(item)
		item.position.x = i * 3
