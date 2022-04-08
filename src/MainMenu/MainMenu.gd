extends Control

signal start_game
signal show_credits
signal quit_game


func _on_Start_pressed():
	emit_signal("start_game")


func _on_Credits_pressed():
	emit_signal("show_credits")


func _on_Quit_pressed():
	emit_signal("quit_game")
