@tool
extends DialogicIndexer


func _get_subsystems() -> Array:
	return [{"name": "Inventory", "script": this_folder.path_join("subsystem_inventory.gd")}]


func _get_events() -> Array:
	return [this_folder.path_join("event_new_memory.gd")]
