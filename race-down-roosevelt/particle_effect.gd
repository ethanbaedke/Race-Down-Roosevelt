class_name ParticleEffect extends Node3D

@export var _gpu_particles:Array[GPUParticles3D] = []

func play() -> void:
	
	for particles:GPUParticles3D in _gpu_particles:
		particles.emitting = true
