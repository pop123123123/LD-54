extends Node

signal room_changed(room: Room)
signal moving_changed(moving: bool)

enum Room {
	LOBBY,
	TOILET,
	GROOMING,
	CORRIDOR,
	SUPPLY_ROOM,
	STAFF_ROOM,
	CEO_OFFICE,
	KENNEL,
	MEAT_ROOM,
	SHERIFF_OFFICE,
}

enum Character {
	SHERIFF,
	PRESIDENT,
	RECEPTIONIST,
	GROOMER,
	JANITOR,
	CUSTOMER,
	NIGHT_GROOMER,
	NIGHT_JANITOR,
	NIGHT_WARDEN,
}

var characters = {
	Character.SHERIFF: load("res://characters/sheriff.dch"),
	Character.PRESIDENT: load("res://characters/president.dch"),
	Character.RECEPTIONIST: load("res://characters/receptionist.dch"),
	Character.GROOMER: load("res://characters/groomer.dch"),
	Character.JANITOR: load("res://characters/janitor.dch"),
	Character.CUSTOMER: load("res://characters/customer.dch"),
	Character.NIGHT_GROOMER: load("res://characters/dark_groomer.dch"),
	Character.NIGHT_JANITOR: load("res://characters/dark_janitor.dch"),
	Character.NIGHT_WARDEN: load("res://characters/night_warden.dch"),
}

var moving: bool = false:
	get:
		return moving
	set(new_moving):
		if moving != new_moving:
			moving = new_moving
			moving_changed.emit(moving)

var current_room: Room = Room.LOBBY:
	get:
		return current_room
	set(room):
		if visited_rooms.has(room):
			visited_rooms[room] += 1
		else:
			visited_rooms[room] = 1
		current_room = room
		moving = false

		var inventory = get_node("/root/DefaultDialogNode/Sidebar/Panel/MarginContainer/VBoxContainer/Inventory")
		if inventory != null:
			inventory.clear_left_panel()
		Dialogic.Backgrounds.update_background('', get_room_background_path(current_room), .5)

		room_changed.emit(room)

var visited_rooms: Dictionary = {}

var last_character: DialogicCharacter = null

var timeline_transitions: Dictionary = {}


func reset_state() -> void:
	print("resetting state")
	print("previously visited rooms: ", visited_rooms)
	moving = false
	current_room = Room.SHERIFF_OFFICE
	visited_rooms = {}
	last_character = null

func has_secret_access() -> bool:
	return Dialogic.VAR.secret_access

func is_first_visit() -> bool:
	return visited_rooms[current_room] == 1


func get_transitions(from: Room = current_room) -> Array:
	return {
		Room.LOBBY:
		[
			Room.TOILET,
			Room.KENNEL,
			Room.GROOMING,
			Room.CORRIDOR,
		],
		Room.TOILET:
		[
			Room.LOBBY,
		],
		Room.GROOMING:
		[
			Room.SUPPLY_ROOM,
			Room.LOBBY,
		],
		Room.CORRIDOR:
		[
			Room.CEO_OFFICE,
			Room.STAFF_ROOM,
			Room.LOBBY,
		],
		Room.SUPPLY_ROOM: [Room.GROOMING],
		Room.STAFF_ROOM: [Room.CORRIDOR],
		Room.CEO_OFFICE: [Room.CORRIDOR],
		Room.KENNEL: [Room.LOBBY, Room.MEAT_ROOM] if has_secret_access() else [Room.LOBBY],
		Room.MEAT_ROOM: [Room.KENNEL],
		Room.SHERIFF_OFFICE: [Room.LOBBY],
	}[from]

var NIGHT_CHARS = {
	Room.LOBBY: [Character.NIGHT_WARDEN],
	Room.TOILET: [],
	Room.GROOMING: [Character.NIGHT_GROOMER],
	Room.CORRIDOR: [],
	Room.SUPPLY_ROOM: [],
	Room.STAFF_ROOM: [],
	Room.CEO_OFFICE: [],
	Room.MEAT_ROOM: [Character.NIGHT_JANITOR],
	Room.SHERIFF_OFFICE: [],
	Room.KENNEL: [Character.NIGHT_JANITOR],
}

var DAY_CHARS = {
	Room.LOBBY: [Character.RECEPTIONIST],
	Room.TOILET: [],
	Room.GROOMING: [Character.GROOMER, Character.CUSTOMER],
	Room.CORRIDOR: [],
	Room.SUPPLY_ROOM: [Character.JANITOR],
	Room.STAFF_ROOM: [],
	Room.CEO_OFFICE: [Character.PRESIDENT],
	Room.MEAT_ROOM: [Character.NIGHT_JANITOR],
	Room.SHERIFF_OFFICE: [Character.SHERIFF],
	Room.KENNEL: [],
}

func is_night() -> bool:
	return Dialogic.VAR.is_night == 1

func get_characters_by_room(room: Room) -> Array:
	if has_secret_access() and room == Room.KENNEL:
		return []
	return (NIGHT_CHARS if is_night() else DAY_CHARS)[room]

func get_room_name(room: Room = current_room) -> String:
	return {
		Room.LOBBY: "Lobby",
		Room.TOILET: "Restroom",
		Room.GROOMING: "Grooming Room",
		Room.CORRIDOR: "Corridor",
		Room.SUPPLY_ROOM: "Supply Room",
		Room.STAFF_ROOM: "Staff Room",
		Room.CEO_OFFICE: "President's Office",
		Room.KENNEL: "Kennel",
		Room.MEAT_ROOM: "Meat Room",
		Room.SHERIFF_OFFICE: "Sheriff's Office",
	}[room]


func dialogic_default_action():
	var new_event = InputEventAction.new()
	new_event.action = "dialogic_default_action"
	new_event.pressed = true
	Input.parse_input_event(new_event)


func get_room_timeline_id(room: Room) -> String:
	return (
		"res://story/arrival_"
		+ {
			Room.LOBBY: "lobby",
			Room.TOILET: "toilet",
			Room.GROOMING: "grooming",
			Room.CORRIDOR: "corridor",
			Room.SUPPLY_ROOM: "supply_room",
			Room.STAFF_ROOM: "staff_room",
			Room.CEO_OFFICE: "ceo_office",
			Room.KENNEL: "kennel",
			Room.MEAT_ROOM: "meat_room",
			Room.SHERIFF_OFFICE: "sheriff_office",
		}[room]
		+ ".dtl"
	)


func get_room_background_path(room: Room) -> String:
	return "res://assets/background/" + {
		Room.LOBBY: "reception",
		Room.TOILET: "restroom",
		Room.GROOMING: "generic_room",
		Room.CORRIDOR: "corridor",
		Room.SUPPLY_ROOM: "supply",
		Room.STAFF_ROOM: "staff_room",
		Room.CEO_OFFICE: "ceo_office",
		Room.KENNEL: "generic_room_2",
		Room.MEAT_ROOM: "meat_factory",
		Room.SHERIFF_OFFICE: "sheriff_office",
	}[room] + ".webp"

func get_memory_timeline_id(character_id: String, memory_id: String) -> String:
	var timeline_id = timeline_transitions.get([character_id, memory_id, has_secret_access()])
	
	if timeline_id == null and has_secret_access():
		timeline_id = timeline_transitions.get([character_id, memory_id, false])
	if timeline_id == null:
		timeline_id = "nothing_" + character_id
		#timeline_id = timeline_transitions.get([character_id, "", has_secret_access()])
	if timeline_id == null and has_secret_access():
		timeline_id = timeline_transitions.get([character_id, "", false])
	if timeline_id == null:
		return ""
	return "res://story/" + timeline_id + ".dtl"

func update_room_characters(room: Room):
	await Dialogic.Portraits.leave_all_characters()
	var i = 1
	for character in get_characters_by_room(room):
		await Dialogic.Portraits.join_character(characters[character], "base", i)
		i += 2

func move_to_room(room: Room):
	moving = true
	var events = Dialogic.current_timeline_events
	var has_bye = events.any(
		func(event: DialogicEvent): return event is DialogicLabelEvent and event.name == "bye"
	)
	if has_bye:
		Dialogic.Jump.jump_to_label("bye")
		dialogic_default_action()
		await Dialogic.timeline_ended
	Dialogic.Choices.hide_all_choices()

	current_room = room
	await update_room_characters(room)
	Dialogic.end_timeline()
	Dialogic.start_timeline(get_room_timeline_id(room))

func _ready():
	Dialogic.event_handled.connect(Callable(self, "_on_event_handled"))
	Dialogic.signal_event.connect(Callable(self, "_on_signal"))
	Dialogic.timeline_started.connect(Callable(self, "_on_timeline_started"))
	Dialogic.timeline_ended.connect(Callable(self, "_on_timeline_ended"))
	_init_timelines()

func setDialogicVisibility(mode: bool):
	var nodes = get_node("/root/DefaultDialogNode").get_children()
	for node in nodes:
		node.visible = mode

func _on_event_handled(event: DialogicEvent):
	if event is DialogicCharacterEvent:
		last_character = event.character
	if event is DialogicTextEvent and event.character:
		last_character = event.character

func get_blackscreen():
	return get_node("/root/DefaultDialogNode/Blackscreen/ColorRect")

func get_sidebar():
	return get_node("/root/DefaultDialogNode/Sidebar")

func _on_signal(signal_type: String):
	if signal_type == "hide_sidebar":
		get_sidebar().visible = false
	if signal_type == "end":
		get_tree().change_scene_to_file("res://src/HUD/credits.tscn")
	if signal_type == "nap":
		current_room = Room.STAFF_ROOM
		get_tree().root.get_node("MainScene/DJ")._transition_night_music()

func trigger_ending(ending_name: String):
	# TODO: fondu au noir
	get_sidebar().visible = false

	await create_tween().tween_property(get_blackscreen(), "color:a", 1.0, 1.0).finished
	create_tween().tween_interval(0.5)
	await create_tween().tween_property(get_blackscreen(), "color:a", 0.0, 1.0).finished

	Dialogic.start("res://story/" + ending_name + ".dtl")

var previous_room: Room = Room.CEO_OFFICE
func _on_timeline_started():
	Dialogic.Choices.hide_all_choices()

func _on_timeline_ended():
	Dialogic.Choices.hide_all_choices()

func select_memory(memory_id: String):
	Dialogic.end_timeline()
	Dialogic.start_timeline(get_memory_timeline_id(last_character.get_character_name(), memory_id))


func _init_timelines() -> void:
	var transitions: Dictionary = {}
	var data = preload("res://data/timelines.csv").records
	var characters = [
		"president",
		"receptionist",
		"groomer",
		"janitor",
		"customer",
		"dark_groomer",
		"dark_janitor",
		"night_warden",
	]
	for row in data:
		for character in characters:
			var dest: String = row[character]
			if dest.length() > 0:
				transitions[[character, row.memory_id, row.suspicious == "true"]] = dest
	timeline_transitions = transitions
