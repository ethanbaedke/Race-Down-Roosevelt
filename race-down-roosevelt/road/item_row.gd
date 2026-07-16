class_name ItemRow extends Node3D

@onready var _item_scene:PackedScene = preload("res://items/item.tscn")

var _items:Array[Item] = []

func _ready() -> void:
	
	for i:int in range(-4, 5):
		var item:Item = _item_scene.instantiate()
		_items.append(item)
		self.add_child(item)
		item.position.x = i * 3
		
func _enter_tree() -> void:
	
	# Don't process this if _ready hasn't been called yet.
	if (_items.size() != 9):
		return
	
	# When we recycle this row, ensure any items that were previously taken are recreated.
	for i:int in range(-4, 5):
		if (_items[i + 4] == null):
			var item:Item = _item_scene.instantiate()
			_items[i + 4] = item
			self.add_child(item)
			item.position.x = i * 3
