class_name VehicleModelController extends Node3D

const CAMERA_CONTROLLER_POSITION:Vector3 = Vector3(0.0, 2.0, -4.0)
const CAMERA_CONTROLLER_ROTATION:Vector3 = Vector3(deg_to_rad(-10.0), deg_to_rad(180.0), 0.0)

const ROTATIONAL_VELOCITY:float = 4.0
const PULSE_TIME:float = 0.5

# This is the node that should be rotated, holds all the models. Created at runtime.
var _rotation_parent:Node3D = null

var _target_x:float = 0.0
var _x_velocity:float = 0.0
var _desired_y_rotation:float = 0.0

var _target_x_on_pulse_start:float = 0.0
var _pulse_target_x:float = 0.0
var _is_in_pulse:bool = false

# Doesn't need a camera controller, only for player vehicles.
func set_camera_controller(controller:CameraController) -> void:
	
	self.add_child(controller)
	controller.position = CAMERA_CONTROLLER_POSITION
	controller.rotation = CAMERA_CONTROLLER_ROTATION

func pulse_right() -> void:
	
	_start_pulse(-1)
	
func pulse_left() -> void:
	
	_start_pulse(1)

func _start_pulse(direction:int) -> void:
	
	_target_x_on_pulse_start = _target_x
	_is_in_pulse = true
	
	# Set the target in the direction we are pulsing.
	_pulse_target_x = _target_x + (direction * 2)
	
	# Wait a moment, and if we're still pulsing afterword, set the target back.
	await get_tree().create_timer(0.1).timeout
	# Here, we also ensure we are still pulsing in the same direction. We could have initiated a pulse in the other direction.
	if (_is_in_pulse && sign(_pulse_target_x - _target_x) == sign(direction)):
		_pulse_target_x = _target_x_on_pulse_start

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

func _handle_movement(delta:float, target_x:float) -> void:
	
	var to_target_x:float = target_x - self.global_position.x
	_x_velocity = max(abs(to_target_x) * 8.0, 2.0) * sign(to_target_x)
	var final_pos:float = self.global_position.x + (_x_velocity * delta)
	
	# If we pass our target doing this movement, snap to our target.
	var final_to_target:float = target_x - final_pos
	if (sign(to_target_x) != sign(final_to_target)):
		# Reached target.
		final_pos = target_x
	
	self.global_position.x = final_pos

func _handle_rotation(delta:float, target_x:float) -> void:
	
	if (_rotation_parent == null):
		return
	
	# Put the rotation target way in front of our movement target.
	var _rotation_target:Vector3 = Vector3(target_x, 0.0, self.global_position.z - 6.0)
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
		
		if (_is_in_pulse):
			# Stop the pulse if the vehicle moved to a different lane.
			if (_is_in_pulse && _target_x_on_pulse_start != _target_x):
				_is_in_pulse = false
			else:
				_handle_movement(delta, _pulse_target_x)
				_handle_rotation(delta, _pulse_target_x)
		else:
			_handle_movement(delta, _target_x)
			_handle_rotation(delta, _target_x)
