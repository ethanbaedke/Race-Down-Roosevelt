class_name Gas extends Node3D

@onready var _collision_area:Area3D = $Area3D
@onready var _collision_shape:CollisionShape3D = $Area3D/CollisionShape3D
@onready var _animation_player:AnimationPlayer = $AnimationPlayer

func _on_collision_area_entered(area:Area3D) -> void:

	var parent:Node3D = area.get_parent()
	if (parent is RacerVehicle):
		var result:bool = parent.try_give_gas()
		if (result):
			_collision_shape.disabled = true
			parent.give_world_pickup(self)
			_animation_player.play("pickup")
			await _animation_player.animation_finished
			self.queue_free()

func _ready() -> void:
	
	_collision_area.area_entered.connect(_on_collision_area_entered)
	
	_animation_player.play("base")
	var rand_time:float = randf_range(0.0, _animation_player.current_animation_length)
	_animation_player.seek(rand_time)
