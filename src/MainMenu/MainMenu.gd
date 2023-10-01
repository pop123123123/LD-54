extends Control

@onready var quit_button: Button = $Menu/VBoxContainer/Quit
@onready var menu: CenterContainer = $Menu
@onready var credits: CenterContainer = $Credits

func _ready() -> void:
	if (OS.has_feature("web")):
		quit_button.hide()

func _on_Start_pressed():
	get_tree().change_scene_to_file("res://src/Credits/Credits.tscn")

func _on_Credits_pressed():
	menu.hide()
	credits.show()

func _on_Quit_pressed():
	get_tree().quit()

func _on_back_pressed():
	credits.hide()
	menu.show()
