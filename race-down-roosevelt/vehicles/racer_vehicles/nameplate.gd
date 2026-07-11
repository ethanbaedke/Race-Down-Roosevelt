class_name Nameplate extends Node3D

@onready var _name_sprite_holder:Node3D = $SpriteHolder
@onready var _name_label:Label = $SubViewport/NameLabel
@onready var _spin_animator:AnimationPlayer = $SpinAnimator

func flip() -> void:
	
	_name_sprite_holder.rotation.y += deg_to_rad(180.0)

func set_display_name(display_name:String) -> void:
	
	_name_label.text = display_name

func spin() -> void:
	
	_spin_animator.play("base")
