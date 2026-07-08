extends Node3D

var _listeners:Array[Node3D] = []

func register_listener(node:Node3D) -> void:
	
	_listeners.append(node)

func clear_listeners() -> void:
	
	_listeners.clear()

func play_source(source:AudioStreamPlayer3D) -> void:
	
	if (_listeners.size() == 0):
		return
	
	if (source.stream == null):
		return
	
	# Calculate which listener is closest to the source.
	var closest_listener:Node3D = _listeners[0]
	var closest_dist:float = (_listeners[0].global_position - source.global_position).length_squared()
	var i:int = 1
	while (i < _listeners.size()):
		var dist:float = (_listeners[i].global_position - source.global_position).length_squared()
		if (dist < closest_dist):
			closest_listener = _listeners[i]
			closest_dist = dist
		i += 1
	
	# Get the audio players position from the listener and make a copy with that as its position from the actual current listener (on this object at (0,0)).
	var listener_to_source:Vector3 = source.global_position - closest_listener.global_position
	var copy:AudioStreamPlayer3D = source.duplicate()
	self.add_child(copy)
	copy.global_position = listener_to_source
	
	# Ensure the copy is cleaned up when it finished playing.
	copy.finished.connect(func() -> void:
		copy.queue_free())
	copy.play()

func _ready() -> void:
	
	var true_listener:AudioListener3D = AudioListener3D.new()
	true_listener.rotation.y = 180.0
	self.add_child(true_listener)
