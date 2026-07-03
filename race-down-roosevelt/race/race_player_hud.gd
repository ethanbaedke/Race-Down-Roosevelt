class_name RacePlayerHud extends Control

@onready var _item_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/ItemTextureRect

func update_item(data:ItemData) -> void:
	
	if (data == null):
		_item_texture_rect.texture = null
		return
	
	_item_texture_rect.texture = data.item_icon
