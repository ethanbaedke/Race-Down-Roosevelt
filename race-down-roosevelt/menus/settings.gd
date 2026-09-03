class_name Settings extends Control

signal back_requested

var game_state:GameState = null

@onready var _music_volume:HSlider = $MarginContainer/VBoxContainer/MusicVolume/HSlider
@onready var _sfx_volume:HSlider = $MarginContainer/VBoxContainer/SfxVolume/HSlider
@onready var _graphics_quality:OptionButton = $MarginContainer/VBoxContainer/GraphicsQuality/Control/OptionButton
@onready var _ai_difficulty:OptionButton = $MarginContainer/VBoxContainer/AiDifficulty/Control/OptionButton

func _ready() -> void:
	
	if (game_state == null):
		RdrLogger.fatal(self, _ready.get_method() + " expects class to have a reference to GameState.")
		return
	
	_music_volume.value = _music_volume.max_value * game_state.save_data.music_volume
	_sfx_volume.value = _sfx_volume.max_value * game_state.save_data.sfx_volume
	_graphics_quality.selected = game_state.save_data.graphics_quality
	_ai_difficulty.selected = game_state.save_data.ai_difficulty
	
	_music_volume.value_changed.connect(func(value:float) -> void:
		game_state.save_data.set_music_volume(value / _music_volume.max_value))
	_sfx_volume.value_changed.connect(func(value:float) -> void:
		game_state.save_data.set_sfx_volume(value / _sfx_volume.max_value))
	_graphics_quality.item_selected.connect(func(index:int) -> void:
		if (index != game_state.save_data.graphics_quality as int):
			game_state.save_data.set_graphics_quality(index))
	_ai_difficulty.item_selected.connect(func(index:int) -> void:
		if (index != game_state.save_data.ai_difficulty as int):
			game_state.save_data.set_ai_difficulty(index))

func _unhandled_input(event: InputEvent) -> void:
	
	# Ignore holding and releases.
	if (event.is_echo() || !event.is_pressed()):
		return
		
	if (event is InputEventKey):
		
		if (event.keycode == KEY_ESCAPE):
			back_requested.emit()
			get_viewport().set_input_as_handled()
			
	elif (event is InputEventJoypadButton):
		
		if (event.button_index == JOY_BUTTON_B):
			back_requested.emit()
			get_viewport().set_input_as_handled()
