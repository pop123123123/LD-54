extends Node

signal memory_added(memory: Dictionary)

var memories: Array = []


func _ready():
	memories = preload("res://data/memories.csv").records


func get_memory(id: String):
	return memories.filter(func(memory): return memory.id == id).front()


func add_memory(id: String):
	var memory = get_memory(id)
	if memory != null:
		print("add memory: ", memory)
		memory_added.emit(memory)
	else:
		printerr("memory not found: ", id)
