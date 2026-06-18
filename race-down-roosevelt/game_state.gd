class_name GameState extends Resource

@export var num_players:int = 0
@export var racer_objects:Array[RacerObject] = []
@export var include_ai_racers:bool = true

@export var profiles:Array[Profile] = []
@export var profile_to_edit:Profile = null
