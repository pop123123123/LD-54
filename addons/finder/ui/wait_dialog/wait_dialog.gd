tool
extends Control
class_name WaitDialog

onready var popup_panel = $PopupPanel
onready var animation_player = $AnimationPlayer
onready var label = $PopupPanel/Label


func _ready():
	label.grab_focus()
	animation_player.play("tree_dots")


func popup():
	popup_panel.popup_centered(Vector2(500, 200))
