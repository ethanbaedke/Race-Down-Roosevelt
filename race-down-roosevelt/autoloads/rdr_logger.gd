extends Node

const SPAM_LOGGING_ENABLED:bool = false

var _ignored_classes:Dictionary[String, bool] = {
	(Race as GDScript).get_global_name(): true,
}

func log(source:Object, contents:String) -> void:
	
	if (_is_ignored(source)):
		return
	
	var prefix:String = _get_prefix(source)
	print(prefix + " " + contents)

# Same as log, but for messages that will be printed extremely often (~every frame).
func spam_log(source:Object, contents:String) -> void:

	if (!SPAM_LOGGING_ENABLED):
		return
		
	if (_is_ignored(source)):
		return

	var prefix:String = _get_prefix(source)
	print(prefix + " " + contents)
	
func warn(source:Object, contents:String) -> void:
	
	if (_is_ignored(source)):
		return
	
	var prefix:String = _get_prefix(source)
	print_rich("[color=GOLDENROD]" + prefix + " " + contents + "[/color]")

func error(source:Object, contents:String) -> void:
	
	if (_is_ignored(source)):
		return
	
	var prefix:String = _get_prefix(source)
	print_rich("[color=SALMON]" + prefix + " " + contents + "[/color]")

# A fatal log will crash the game.
func fatal(source:Object, contents:String) -> void:
	
	if (_is_ignored(source)):
		return
	
	var prefix:String = _get_prefix(source)
	print_rich("[color=FUCHSIA]" + prefix + " " + contents + "[/color]")
	get_tree().quit(1)

func _is_ignored(source:Object) -> bool:
	
	var script_type:String = source.get_script().get_global_name()
	return _ignored_classes.has(script_type)

func _get_prefix(source:Object) -> String:
	
	var script_type:String = source.get_script().get_global_name()
	var instance:String = str(source.get_instance_id())
	return script_type + " (" + instance + "):"
