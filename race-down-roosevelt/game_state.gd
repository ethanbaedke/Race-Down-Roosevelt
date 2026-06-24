class_name GameState extends Resource

@export var save_data:SaveData = null

@export var num_players:int = 0
@export var racer_objects:Array[RacerObject] = []
@export var include_ai_racers:bool = true

@export var profile_to_edit:Profile = null

@export var active_tournement:TournementState = null
