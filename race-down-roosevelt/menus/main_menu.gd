class_name MainMenu extends Control

signal single_race_selected

@onready var _single_race_button:Button = $SingleRaceButton

func _ready() -> void:
	
	_single_race_button.grab_focus()
	
	_single_race_button.pressed.connect(func() -> void:
		single_race_selected.emit())
