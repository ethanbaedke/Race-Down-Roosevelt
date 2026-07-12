class_name RacePlayerHud extends Control

@onready var _item_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer/SizeFitterControl/ItemTextureRect
@onready var _item_progress_bar:ProgressBar = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer/SizeFitterControl/ItemProgressBar
@onready var _jump_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer2/SizeFitterControl2/JumpForeground
@onready var _item_disabled_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer/SizeFitterControl/ItemDisabledTexture
@onready var _jump_disabled_texture_rect:TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer2/SizeFitterControl2/JumpDisabledTexture
@onready var _name_label:Label = $MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/NameLabel
@onready var _item_input_glyph:InputGlyph = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer/Control/InputGlyph
@onready var _jump_input_glyph:InputGlyph = $MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer2/Control/InputGlyph

func update_item(data:ItemData) -> void:
	
	if (data == null):
		_item_texture_rect.texture = null
		_item_input_glyph.visible = false
		return
	
	_item_texture_rect.texture = data.item_icon
	if (_item_disabled_texture_rect.visible == false):
		_item_input_glyph.visible = true

func update_item_time(current_time:float, total_time:float) -> void:
	
	if (current_time == 0.0 || current_time == total_time):
		_item_progress_bar.visible = false
		return
	
	_item_progress_bar.visible = true
	_item_progress_bar.value = (current_time / total_time) * 100.0
	_item_input_glyph.visible = false

func update_gas(current_amount:float, max_amount:float) -> void:
	
	var percent:float = current_amount / max_amount
	_jump_texture_rect.material.set_shader_parameter("percent", percent)
	if (percent == 1.0 && _jump_disabled_texture_rect.visible == false):
		_jump_input_glyph.visible = true
	else:
		_jump_input_glyph.visible = false

func update_item_usable_state(usable:bool) -> void:
	
	if (usable && _item_disabled_texture_rect.visible == true):
		_item_disabled_texture_rect.visible = false
		if (_item_texture_rect.texture != null):
			_item_input_glyph.visible = true
	elif (!usable && _item_disabled_texture_rect.visible == false):
		_item_disabled_texture_rect.visible = true
		_item_input_glyph.visible = false

func update_gas_usable_state(usable:bool) -> void:
	
	if (usable && _jump_disabled_texture_rect.visible == true):
		_jump_disabled_texture_rect.visible = false
		if (_jump_texture_rect.material.get_shader_parameter("percent") == 1.0):
			_jump_input_glyph.visible = true
	elif (!usable && _jump_disabled_texture_rect.visible == false):
		_jump_disabled_texture_rect.visible = true
		_jump_input_glyph.visible = false

func update_name(new_name:String) -> void:
	
	_name_label.text = new_name

func update_device_type(device_type:Globals.DeviceType) -> void:
	
	_item_input_glyph.set_glyph(device_type, InputGlyph.ActionType.ITEM)
	_jump_input_glyph.set_glyph(device_type, InputGlyph.ActionType.JUMP)

func _ready() -> void:
	
	_item_input_glyph.visible = false
	_jump_input_glyph.visible = false
