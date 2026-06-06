class_name RandomNodePool extends Resource

@export var entries:Array[RandomNodePoolEntry] = []
@export var debug_name:String = "Unkown"

# Holds arrays of recycled traffic vehicle instances. Each array is a different traffic vehicle node_ind and mimics the traffic vehicles array.
var _pool:Array[Array] = []
var _active_instances:Array[Node] = []
var _active_instance_indices:Array[int] = []

func initialize() -> void:
	
	# Cleanup any existing data. Will only matter if pool is initialized more than once.
	_pool.clear()
	_active_instances.clear()
	_active_instance_indices.clear()
	
	_pool.resize(entries.size())

# Returns a random instantiated node from entries, and null if entries is empty or an unexpected error occurs.
func get_node() -> Node:
	
	if (_pool.size() != entries.size()):
		RdrLogger.fatal(self, get_node.get_method() + " expects pool to have size equal to the entries array.")
		return null
	
	if (_pool.size() == 0):
		RdrLogger.warn(self, "No packed scenes exist in the entries array. Returning null.")
		return null
	
	var total_weight:float = 0.0
	for entry:RandomNodePoolEntry in entries:
		total_weight += entry.weight
	var rand_target:float = randf_range(0.0, total_weight)
	var current:float = 0.0
	var i:int = 0
	while (i < entries.size() && current < rand_target):
		current += entries[i].weight
		i += 1
	var node_ind:int = i - 1
	
	# Pool is empty for this node_ind, create a new instance.
	if (_pool[node_ind].size() == 0):
		RdrLogger.log(self, "Creating new " + debug_name + " instance (total = " + str(_active_instances.size()) + ").")
		var instance:Node = entries[node_ind].scene.instantiate()
		_active_instances.append(instance)
		_active_instance_indices.append(node_ind)
		return instance
	# Pool contains an entry for this traffic vehicle, remove and return it.
	else:
		RdrLogger.log(self, "Reusing " + debug_name + " instance from pool.")
		var end_ind:int = _pool[node_ind].size() - 1
		var instance:Node = _pool[node_ind][end_ind]
		_active_instances.append(instance)
		_active_instance_indices.append(node_ind)
		_pool[node_ind].remove_at(end_ind)
		return instance

# Pass a function that takes in a node from the pool and returns a boolean representing whether or not it is ready to be cleaned up.
func run_cleanup(is_ready_for_cleanup:Callable) -> void:
	
	var i:int = 0
	while (i < _active_instances.size()):
		if (is_ready_for_cleanup.call(_active_instances[i])):
			RdrLogger.log(self, "Recycling " + debug_name + " instance.")
			var parent:Node = _active_instances[i].get_parent()
			if (parent != null):
				parent.remove_child(_active_instances[i])
			_pool[_active_instance_indices[i]].append(_active_instances[i])
			_active_instances.remove_at(i)
			_active_instance_indices.remove_at(i)
		else:
			i += 1
