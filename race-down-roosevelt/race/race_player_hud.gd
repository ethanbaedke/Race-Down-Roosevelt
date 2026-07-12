class_name RacePlayerHud extends Control

@onready var _item_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer/SizeFitterControl/ItemTextureRect
@onready var _item_progress_bar:ProgressBar = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer/SizeFitterControl/ItemProgressBar
@onready var _jump_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer2/SizeFitterControl2/JumpForeground
@onready var _item_disabled_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer/SizeFitterControl/ItemDisabledTexture
@onready var _jump_disabled_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer2/SizeFitterControl2/JumpDisabledTexture
@onready var _name_label:Label = $MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/NameLabel
@onready var _item_input_glyph:InputGlyph = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer/InputGlyph
@onready var _jump_input_glyph:InputGlyph = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer2/InputGlyph

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

func update_name(new_name:String) -> void:
	
	_name_label.text = new_name

func update_device_type(device_type:Globals.DeviceType) -> void:
	
	_item_input_glyph.set_glyph(device_type, InputGlyph.ActionType.ITEM)
	_jump_input_glyph.set_glyph(device_type, InputGlyph.ActionType.JUMP)
