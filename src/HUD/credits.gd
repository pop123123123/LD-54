extends Control

func _ready():
	await get_tree().process_frame
	Globals.setDialogicVisibility(false)

func _on_retry_button_down():
	get_tree().change_scene_to_file("res://src/MainScene/MainScene.tscn")
