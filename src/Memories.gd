extends Node

signal memory_added(memory: Dictionary)
signal active_memory_added(memory_id: String, x: int, y: int)
signal active_memory_removed(memory_id: String)

var memories: Array = []
var active_memories: Array = []


func _ready():
	memories = preload("res://data/memories.csv").records


func get_memory(id: String):
	return memories.filter(func(memory): return memory.id == id).front()


func add_memory(id: String, active = false, x = 0, y = 0):
	var memory = get_memory(id)
	if memory != null:
		if active:
			print("add memory active: ", memory, " x:", x, " y:", y)
			add_active_memory(id, x, y)
		else:
			print("add memory: ", memory)
			memory_added.emit(memory)
	else:
		printerr("memory not found: ", id)

func add_active_memory(id: String, x: int, y: int):
	var memory = get_memory(id)
	if memory != null:
		if not active_memories.has(id):
			active_memories.append(id)
			active_memory_added.emit(memory, x, y)
	else:
		printerr("memory not found: ", id)

func remove_active_memory(id: String):
	if active_memories.has(id):
		active_memories.erase(id)
		active_memory_removed.emit(id)

func get_short_title(memory: Dictionary):
	var short_title = memory.short_title
	if short_title == null or short_title.length() == 0:
		return memory.title
	return short_title
