class_name OpeningCutscene extends Node3D

signal finished

@onready var _animator:AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	
	_animator.animation_finished.connect(func(anim_name:StringName) -> void:
		finished.emit())
