# This node is not a camera itself. It's purpose is to pose as a camera in the world.
# It holds a camera reference that it updates to match its position and orientation.
# This is so the actual cameras can sit in subviewports to handle splitscreen, but still be controlled within the world.
class_name CameraController extends Node3D

var camera:Camera3D = null

func _sync_camera_position_and_orientation() -> void:
	
	camera.global_position = self.global_position
	camera.global_rotation = self.global_rotation

func _ready() -> void:
	
	# If no camera is given to this controller when it's added to the scene tree, destroy it.
	if (camera == null):
		RdrLogger.error(self, "Camera object not set. Destroying self.")
		self.queue_free()
		return
		
	_sync_camera_position_and_orientation()
	
func _process(delta: float) -> void:
	
	_sync_camera_position_and_orientation()
