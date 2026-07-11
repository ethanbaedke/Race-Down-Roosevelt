class_name Nameplate extends Node3D

@onready var _name_sprite_holder:Node3D = $SpriteHolder
@onready var _name_sprite:Sprite3D = $SpriteHolder/NameSprite
@onready var _name_label:Label = $SubViewport/NameLabel
@onready var _spin_animator:AnimationPlayer = $SpinAnimator

func set_player_number(num:int) -> void:
	
	_name_sprite.set_layer_mask_value(1, false)
	match (num):
		1:
			_name_sprite.set_layer_mask_value(3, true)
			_name_sprite.set_layer_mask_value(4, true)
			_name_sprite.set_layer_mask_value(5, true)
		2:
			_name_sprite.set_layer_mask_value(2, true)
			_name_sprite.set_layer_mask_value(4, true)
			_name_sprite.set_layer_mask_value(5, true)
		3:
			_name_sprite.set_layer_mask_value(2, true)
			_name_sprite.set_layer_mask_value(3, true)
			_name_sprite.set_layer_mask_value(5, true)
		4:
			_name_sprite.set_layer_mask_value(2, true)
			_name_sprite.set_layer_mask_value(3, true)
			_name_sprite.set_layer_mask_value(4, true)

func flip() -> void:
	
	_name_sprite_holder.rotation.y += deg_to_rad(180.0)

func set_display_name(display_name:String) -> void:
	
	_name_label.text = display_name

func spin() -> void:
	
	_spin_animator.play("base")
