class_name ItemRow extends Node3D

@onready var _item_scene:PackedScene = preload("res://items/item.tscn")
@onready var _item_data_resources:Array[ItemData] = [
	#preload("res://items/boost_item_data.tres"),
	#preload("res://items/invincibility_item_data.tres"),
	preload("res://items/ai_item_data.tres"),
	#preload("res://items/speed_item_data.tres"),
]

var _items:Array[Item] = []

func _create_random_item() -> Item:
	
	var item:Item = _item_scene.instantiate()
	var item_ind:int = randi_range(0, _item_data_resources.size() - 1)
	item.item_data = _item_data_resources[item_ind]
	return item

func _ready() -> void:
	
	for i:int in range(-4, 5):
		var item:Item = _create_random_item()
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
			var item:Item = _create_random_item()
			_items[i + 4] = item
			self.add_child(item)
			item.position.x = i * 3
