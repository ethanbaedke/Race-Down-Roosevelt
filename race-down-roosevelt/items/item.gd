class_name Item extends Node3D

@onready var _collision_area:Area3D = $Area3D

var item_data:ItemData = null

func _on_collision_area_entered(area:Area3D) -> void:

	if (item_data == null):
		RdrLogger.error(self, "Item hit but item data is null.")
		return

	var parent:Node3D = area.get_parent()
	if (parent is RacerVehicle):
		var result:bool = parent.try_give_item(item_data)
		if (result):
			self.queue_free()

func _ready() -> void:
	
	_collision_area.area_entered.connect(_on_collision_area_entered)
