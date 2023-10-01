@tool
class_name DialogicNewMemoryEvent
extends DialogicEvent

# Define properties of the event here
var id: String = ""


func _execute() -> void:
	Memories.add_memory(id)
	finish()


################################################################################
## 						INITIALIZE
################################################################################


# Set fixed settings of this event
func _init() -> void:
	event_name = "New Memory"
	event_category = "Inventory"


################################################################################
## 						SAVING/LOADING
################################################################################
func get_shortcode() -> String:
	return "new_memory"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"id": {"property": "id", "default": ""},
	}


# You can alternatively overwrite these 3 functions: to_text(), from_text(), is_valid_event()

################################################################################
## 						EDITOR REPRESENTATION
################################################################################


func build_event_editor() -> void:
	add_header_edit(
		"id", ValueType.SINGLELINE_TEXT, {"left_text": "NEW MEMORY:", "autofocus": true}
	)
