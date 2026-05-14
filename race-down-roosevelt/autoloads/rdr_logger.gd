extends Node

func log(source:Object, contents:String) -> void:
	
	var prefix:String = _get_prefix(source)
	print(prefix + " " + contents)

func warn(source:Object, contents:String) -> void:
	
	var prefix:String = _get_prefix(source)
	print_rich("[color=GOLDENROD]" + prefix + " " + contents + "[/color]")

func error(source:Object, contents:String) -> void:
	
	var prefix:String = _get_prefix(source)
	print_rich("[color=SALMON]" + prefix + " " + contents + "[/color]")

func _get_prefix(source:Object) -> String:
	
	var script_type:String = source.get_script().get_global_name()
	var instance:String = str(source.get_instance_id())
	return script_type + " (" + instance + "):"
