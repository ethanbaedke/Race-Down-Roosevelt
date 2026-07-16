class_name InputGlyph extends TextureRect

enum ActionType {
	JUMP,
	ITEM,
	NAVIGATE_HORIZONTAL
}

const ANIMATION_SPEED:float = 4

@onready var _kb_jump:Texture2D = preload("res://input_glyphs/keyboard_c.png")
@onready var _kb_item:Texture2D = preload("res://input_glyphs/keyboard_x.png")
@onready var _kb_horizontal:Texture2D = preload("res://input_glyphs/keyboard_horizontal.png")

@onready var _ps_jump:Texture2D = preload("res://input_glyphs/playstation_cross.png")
@onready var _ps_item:Texture2D = preload("res://input_glyphs/playstation_square.png")
@onready var _ps_horizontal:Texture2D = preload("res://input_glyphs/playstation_left_stick.png")

@onready var _xb_jump:Texture2D = preload("res://input_glyphs/xbox_a.png")
@onready var _xb_item:Texture2D = preload("res://input_glyphs/xbox_x.png")
@onready var _xb_horizontal:Texture2D = preload("res://input_glyphs/xbox_left_stick.png")

@onready var _ns_jump:Texture2D = preload("res://input_glyphs/switch_b.png")
@onready var _ns_item:Texture2D = preload("res://input_glyphs/switch_y.png")
@onready var _ns_horizontal:Texture2D = preload("res://input_glyphs/switch_left_stick.png")

var _atlas_texture:AtlasTexture = self.texture
var _anim_time:float = 0.0
var _frame:int = 0
var _rect_width:int = 16

func set_glyph(device_type:Globals.DeviceType, action_type:ActionType) -> void:
	
	match (device_type):
		Globals.DeviceType.KEYBOARD:
			match (action_type):
				ActionType.JUMP:
					_atlas_texture.atlas = _kb_jump
					_rect_width = 16
				ActionType.ITEM:
					_atlas_texture.atlas = _kb_item
					_rect_width = 16
				ActionType.NAVIGATE_HORIZONTAL:
					_atlas_texture.atlas = _kb_horizontal
					_rect_width = 33
		Globals.DeviceType.XBOX:
			match (action_type):
				ActionType.JUMP:
					_atlas_texture.atlas = _xb_jump
					_rect_width = 16
				ActionType.ITEM:
					_atlas_texture.atlas = _xb_item
					_rect_width = 16
				ActionType.NAVIGATE_HORIZONTAL:
					_atlas_texture.atlas = _xb_horizontal
					_rect_width = 20
		Globals.DeviceType.PLAYSTATION:
			match (action_type):
				ActionType.JUMP:
					_atlas_texture.atlas = _ps_jump
					_rect_width = 16
				ActionType.ITEM:
					_atlas_texture.atlas = _ps_item
					_rect_width = 16
				ActionType.NAVIGATE_HORIZONTAL:
					_atlas_texture.atlas = _ps_horizontal
					_rect_width = 20
		Globals.DeviceType.SWITCH:
			match (action_type):
				ActionType.JUMP:
					_atlas_texture.atlas = _ns_jump
					_rect_width = 16
				ActionType.ITEM:
					_atlas_texture.atlas = _ns_item
					_rect_width = 16
				ActionType.NAVIGATE_HORIZONTAL:
					_atlas_texture.atlas = _ns_horizontal
					_rect_width = 20
		_:
			_atlas_texture.atlas = null
	
func _process(delta: float) -> void:

	_anim_time += ANIMATION_SPEED * delta
	if (_anim_time >= 4.0):
		_anim_time -= 4.0
	_frame = _anim_time as int
	_atlas_texture.region = Rect2(_rect_width * _frame, 0, _rect_width, 16)
