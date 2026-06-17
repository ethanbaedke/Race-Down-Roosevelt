class_name Leaderboard extends Control

@onready var _names:Array[Label] = [
	$"MarginContainer/VBoxContainer/1stPlace/1stPlacePanel/HBoxContainer/Name",
	$"MarginContainer/VBoxContainer/2ndPlace/2ndPlacePanel/HBoxContainer/Name",
	$"MarginContainer/VBoxContainer/3rdPlace/3rdPlacePanel/HBoxContainer/Name",
	$"MarginContainer/VBoxContainer/4thPlace/4thPlacePanel/HBoxContainer/Name"
]

@onready var _panels:Array[PanelContainer] = [
	$"MarginContainer/VBoxContainer/1stPlace/1stPlacePanel",
	$"MarginContainer/VBoxContainer/2ndPlace/2ndPlacePanel",
	$"MarginContainer/VBoxContainer/3rdPlace/3rdPlacePanel",
	$"MarginContainer/VBoxContainer/4thPlace/4thPlacePanel",
]

func load_data(racers:Array[RacerObject]) -> void:
	
	self.visible = true
	
	var i:int = 0
	while (i < racers.size()):
		_names[i].text = racers[i].name
		i += 1
	while (i < 4):
		_panels[i].visible = false
		i += 1
