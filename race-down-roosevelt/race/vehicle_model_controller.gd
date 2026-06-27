class_name VehicleModelController extends Node3D

const CAMERA_CONTROLLER_POSITION:Vector3 = Vector3(0.0, 2.0, -4.0)
const CAMERA_CONTROLLER_ROTATION:Vector3 = Vector3(deg_to_rad(-10.0), deg_to_rad(180.0), 0.0)

const ROTATIONAL_VELOCITY:float = 1.0

var _target:Vector3 = Vector3.ZERO
var _velocity:float = 0.0
var _desired_rotation:float = 0.0

# Doesn't need a camera controller, only for player vehicles.
func set_camera_controller(controller:CameraController) -> void:
	
	self.add_child(controller)
	controller.position = CAMERA_CONTROLLER_POSITION
	controller.rotation = CAMERA_CONTROLLER_ROTATION

func _handle_movement(delta:float) -> void:
	
	var to_target:Vector3 = _target - self.global_position
	_velocity = max(to_target.length_squared() * 8.0, 4.0)
	var final_pos:Vector3 = self.global_position + to_target.normalized() * _velocity * delta
	
	# If we pass our target doing this movement, snap to our target.
	var final_to_target:Vector3 = _target - final_pos
	if (to_target.dot(final_to_target) < 0.0):
		final_pos = _target
	
	self.global_position = final_pos

func _handle_rotation(delta:float) -> void:
	
	# Only rotate a mesh under this object.
	if (get_child_count() != 0):
		var child:Node = self.get_child(0)
		if (child is Node3D):
		
			# Put the rotation target way in front of our movement target.
			var _rotation_target:Vector3 = _target + Vector3(0.0, 0.0, -10.0)
			var _to_rotation_target:Vector3 = _rotation_target - self.global_position
			
			# Set the desired angle of rotation.
			_desired_rotation = (Vector3.FORWARD.angle_to(_to_rotation_target) * sign(_to_rotation_target.x)) + (PI * 0.5)

			child.global_rotation.y = move_toward(child.global_rotation.y, _desired_rotation, ROTATIONAL_VELOCITY * delta)

func _process(delta: float) -> void:
	
	var parent:Node = self.get_parent()
	if (parent is Node3D):
		_target = parent.global_position
		
	_handle_movement(delta)
	_handle_rotation(delta)
