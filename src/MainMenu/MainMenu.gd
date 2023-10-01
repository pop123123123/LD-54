extends Control

@onready var quit_button: Button = $CenterContainer/VBoxContainer/Quit

func _ready() -> void:
	if (OS.has_feature("web")):
		quit_button.hide()

func _on_Start_pressed():
	get_tree().change_scene_to_file("res://src/Credits/Credits.tscn")

func _on_Credits_pressed():
	get_tree().change_scene_to_file("res://src/Credits/Credits.tscn")

func _on_Quit_pressed():
	get_tree().quit()
