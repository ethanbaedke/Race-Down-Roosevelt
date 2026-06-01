class_name GameManager extends Node

@onready var _race_scene:PackedScene = preload("res://race/race.tscn")

var _race:Race = null

func _ready() -> void:

	_create_race()
	
func _create_race() -> void:

	_race = _race_scene.instantiate()
	_race.ready_for_cleanup.connect(_on_race_ready_for_cleanup)
	self.add_child(_race)
	_race.setup_race()

func _cleanup_race() -> void:
	
	_race.ready_for_cleanup.disconnect(_on_race_ready_for_cleanup)
	_race.queue_free()

func _on_race_ready_for_cleanup() -> void:
	
	_cleanup_race()
	_create_race()
