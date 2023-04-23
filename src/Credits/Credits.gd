extends Control

signal back

var back_button_visible

@onready var back_button = $CenterContainer/VBoxContainer/CenterContainer4/Back


func _ready():
	assert(back_button_visible != null) #,"set_back must be called before creating Credits scene")
	if back_button_visible:
		back_button.show()
	else:
		back_button.hide()


func set_back(value):
	back_button_visible = value


func _on_Back_pressed():
	emit_signal("back")
