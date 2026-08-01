class_name ItemPlate extends Node3D

@onready var _item_sprite:Sprite3D = $SpriteHolder/ItemSprite

func set_player_number(num:int) -> void:
	
	_item_sprite.set_layer_mask_value(1, false)
	_item_sprite.set_layer_mask_value(num + 1, true)

func set_item(item:ItemData) -> void:
	
	if (item == null):
		_item_sprite.texture = null
	else:
		_item_sprite.texture = item.item_icon

func update_item_time(time:float) -> void:
	
	if (time <= 0.0):
		_item_sprite.modulate.a = 0.0
		set_item(null)
	elif (time <= 2.25):
		_item_sprite.modulate.a = lerp(1.0, 0.0, (cos((time * 4.0 * PI) + PI) * -0.5) + 0.5)
	else:
		_item_sprite.modulate.a = 1.0

func _ready() -> void:
	
	_item_sprite.modulate.a = 0.0
