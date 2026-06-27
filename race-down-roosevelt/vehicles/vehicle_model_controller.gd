class_name VehicleModelController extends Node3D

const CAMERA_CONTROLLER_POSITION:Vector3 = Vector3(0.0, 2.0, -4.0)
const CAMERA_CONTROLLER_ROTATION:Vector3 = Vector3(deg_to_rad(-10.0), deg_to_rad(180.0), 0.0)

const ROTATIONAL_VELOCITY:float = 4.0

# This is the node that should be rotated, holds all the models. Created at runtime.
var _rotation_parent:Node3D = null

var _target_x:float = 0.0
var _x_velocity:float = 0.0
var _desired_y_rotation:float = 0.0

# Doesn't need a camera controller, only for player vehicles.
func set_camera_controller(controller:CameraController) -> void:
	
	self.add_child(controller)
	controller.position = CAMERA_CONTROLLER_POSITION
	controller.rotation = CAMERA_CONTROLLER_ROTATION

func _ready() -> void:
	
	# Move all child objects under a common rotation parent.
	if (get_child_count() != 0):
		var children:Array[Node] = []
		for child:Node in self.get_children():
			children.append(child)
		_rotation_parent = Node3D.new()
		self.add_child(_rotation_parent)
		for child:Node in children:
			child.reparent(_rotation_parent)

func _handle_movement(delta:float) -> void:
	
	var to_target_x:float = _target_x - self.global_position.x
	_x_velocity = max(abs(to_target_x) * 8.0, 2.0) * sign(to_target_x)
	var final_pos:float = self.global_position.x + (_x_velocity * delta)
	
	# If we pass our target doing this movement, snap to our target.
	var final_to_target:float = _target_x - final_pos
	if (sign(to_target_x) != sign(final_to_target)):
		# Reached target.
		final_pos = _target_x
	
	self.global_position.x = final_pos

func _handle_rotation(delta:float) -> void:
	
	if (_rotation_parent == null):
		return
	
	# Put the rotation target way in front of our movement target.
	var _rotation_target:Vector3 = Vector3(_target_x, 0.0, self.global_position.z - 6.0)
	var _to_rotation_target:Vector3 = _rotation_target - self.global_position
	
	# Set the desired angle of rotation.
	_desired_y_rotation = (Vector3.FORWARD.angle_to(_to_rotation_target) * sign(_to_rotation_target.x))

	_rotation_parent.global_rotation.y = move_toward(_rotation_parent.global_rotation.y, _desired_y_rotation, ROTATIONAL_VELOCITY * delta)

func _process(delta: float) -> void:
	
	var parent:Node = self.get_parent()
	if (parent is Node3D):
		
		# Always snap to the parents y and z.
		self.global_position.y = parent.global_position.y
		self.global_position.z = parent.global_position.z
		
		_target_x = parent.global_position.x
		
		_handle_movement(delta)
		_handle_rotation(delta)
