extends Node2D

onready var map = get_parent().get_node("TileMap")
onready var game = map.get_parent()


func _ready():
	# Waits for Game.gd to run randomize()
	yield(get_tree(), "idle_frame")
	$SoundFx/SpawnSound.play_sound()
	var lol = Navigation2DServer.map_get_path(map, position, position + Vector2(1, 0), false)
	print(lol)

#func _process(delta):
#	pass
