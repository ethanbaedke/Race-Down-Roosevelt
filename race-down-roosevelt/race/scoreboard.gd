class_name Scoreboard extends Control

@onready var _names:Array[Label] = [
	$"MarginContainer/VBoxContainer/1stPlace/PanelContainer/HBoxContainer/Name",
	$"MarginContainer/VBoxContainer/2ndPlace/PanelContainer/HBoxContainer/Name",
	$"MarginContainer/VBoxContainer/3rdPlace/PanelContainer/HBoxContainer/Name",
	$"MarginContainer/VBoxContainer/4thPlace/PanelContainer/HBoxContainer/Name"
]

func load_data(racers:Array[RacerObject]) -> void:
	
	self.visible = true
	
	for i:int in range(racers.size()):
		_names[i].text = racers[i].name
