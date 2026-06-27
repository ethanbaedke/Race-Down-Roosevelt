class_name VehicleModelController extends Node3D

const CAMERA_CONTROLLER_POSITION:Vector3 = Vector3(0.0, 2.0, -4.0)
const CAMERA_CONTROLLER_ROTATION:Vector3 = Vector3(deg_to_rad(-10.0), deg_to_rad(180.0), 0.0)

var _velocity:float = 0.0

# Doesn't need a camera controller, only for player vehicles.
func set_camera_controller(controller:CameraController) -> void:
	
	self.add_child(controller)
	controller.position = CAMERA_CONTROLLER_POSITION
	controller.rotation = CAMERA_CONTROLLER_ROTATION

func _process(delta: float) -> void:
	
	var parent:Node = self.get_parent()
	if (parent is Node3D):
		
		var to_target:Vector3 = parent.global_position - self.global_position
		_velocity = max(to_target.length_squared() * 8.0, 8.0)
		var final_pos:Vector3 = self.global_position + to_target.normalized() * _velocity * delta
		
		# If we pass our target doing this movement, snap to our target.
		var final_to_target:Vector3 = parent.global_position - final_pos
		if (to_target.dot(final_to_target) < 0.0):
			final_pos = parent.global_position
		
		self.global_position = final_pos
