class_name RacePlayerHud extends Control

@onready var _item_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/AspectRatioContainer/ItemTextureRect
@onready var _item_progress_bar:ProgressBar = $MarginContainer/VBoxContainer/HBoxContainer/AspectRatioContainer/ItemProgressBar

func update_item(data:ItemData) -> void:
	
	if (data == null):
		_item_texture_rect.texture = null
		return
	
	_item_texture_rect.texture = data.item_icon

func update_item_time(current_time:float, total_time:float) -> void:
	
	if (current_time == 0.0 || current_time == total_time):
		_item_progress_bar.visible = false
		return
	
	_item_progress_bar.visible = true
	_item_progress_bar.value = (current_time / total_time) * 100.0
