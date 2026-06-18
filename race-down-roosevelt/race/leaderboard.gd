class_name Leaderboard extends Control

@onready var _names:Array[Label] = [
	$"MarginContainer/VBoxContainer/1stPlace/PanelContainer/MarginContainer/HBoxContainer/Name",
	$"MarginContainer/VBoxContainer/2ndPlace/PanelContainer/MarginContainer/HBoxContainer/Name",
	$"MarginContainer/VBoxContainer/3rdPlace/PanelContainer/MarginContainer/HBoxContainer/Name",
	$"MarginContainer/VBoxContainer/4thPlace/PanelContainer/MarginContainer/HBoxContainer/Name"
]

@onready var _icons:Array[TextureRect] = [
	$"MarginContainer/VBoxContainer/1stPlace/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/TextureRect",
	$"MarginContainer/VBoxContainer/2ndPlace/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/TextureRect",
	$"MarginContainer/VBoxContainer/3rdPlace/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/TextureRect",
	$"MarginContainer/VBoxContainer/4thPlace/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/TextureRect"
]

@onready var _panels:Array[PanelContainer] = [
	$"MarginContainer/VBoxContainer/1stPlace/PanelContainer",
	$"MarginContainer/VBoxContainer/2ndPlace/PanelContainer",
	$"MarginContainer/VBoxContainer/3rdPlace/PanelContainer",
	$"MarginContainer/VBoxContainer/4thPlace/PanelContainer",
]

func load_data(racers:Array[RacerObject]) -> void:
	
	self.visible = true
	
	var i:int = 0
	while (i < racers.size()):
		_names[i].text = racers[i].profile.name
		_icons[i].texture = racers[i].profile.icon
		i += 1
	while (i < 4):
		_panels[i].visible = false
		i += 1
