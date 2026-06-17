class_name MainMenu extends Control

signal single_race_selected
signal manage_profiles_selected

@onready var _single_race_button:Button = $MarginContainer/HBoxContainer/SingleRaceButton
@onready var _manage_profiles_button:Button = $MarginContainer/HBoxContainer/ManageProfilesButton

func _ready() -> void:
	
	_single_race_button.grab_focus()
	
	_single_race_button.pressed.connect(func() -> void:
		single_race_selected.emit())
	_manage_profiles_button.pressed.connect(func() -> void:
		manage_profiles_selected.emit())
