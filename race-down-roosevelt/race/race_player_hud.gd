class_name RacePlayerHud extends Control

@onready var _item_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/SizeFitterControl/ItemTextureRect
@onready var _item_progress_bar:ProgressBar = $MarginContainer/VBoxContainer/HBoxContainer/SizeFitterControl/ItemProgressBar
@onready var _jump_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/SizeFitterControl2/JumpForeground
@onready var _item_disabled_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/SizeFitterControl/ItemDisabledTexture
@onready var _jump_disabled_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/SizeFitterControl2/JumpDisabledTexture

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

func update_gas(current_amount:float, max_amount:float) -> void:
	
	var percent:float = current_amount / max_amount
	_jump_texture_rect.material.set_shader_parameter("percent", percent)

func update_item_usable_state(usable:bool) -> void:
	
	_item_disabled_texture_rect.visible = !usable

func update_gas_usable_state(usable:bool) -> void:
	
	_jump_disabled_texture_rect.visible = !usable
