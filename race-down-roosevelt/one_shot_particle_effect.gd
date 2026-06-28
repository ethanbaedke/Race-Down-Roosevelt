class_name OneShotParticleEffect extends Node3D

signal effect_finished

var _one_shot_particles:Array[GPUParticles3D] = []
var _finished_count:int = 0

func _ready() -> void:
	
	for child:Node in self.get_children():
		if (child is GPUParticles3D):
			if (child.one_shot):
				_one_shot_particles.append(child)
				child.finished.connect(_on_one_shot_particle_finished)
				child.emitting = true

func _on_one_shot_particle_finished() -> void:
	
	_finished_count += 1
	if (_finished_count == _one_shot_particles.size()):
		effect_finished.emit()
		queue_free()
