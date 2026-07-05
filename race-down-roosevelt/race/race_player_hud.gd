class_name RacePlayerHud extends Control

@onready var _item_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/SizeFitterControl/ItemTextureRect
@onready var _item_progress_bar:ProgressBar = $MarginContainer/VBoxContainer/HBoxContainer/SizeFitterControl/ItemProgressBar
@onready var _jump_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/SizeFitterControl2/JumpForeground

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

func update_jump_progress(percent:float) -> void:
	
	_jump_texture_rect.set_shader_parameter("percent", percent)
