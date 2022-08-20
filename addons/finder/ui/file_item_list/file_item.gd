tool
extends Control
class_name FileItem

onready var texture_rect: TextureRect = $MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/MarginContainer/CenterContainer/TextureRect
onready var color_rect = $ColorRect
onready var texture_rect_preview = $MarginContainer/HBoxContainer/CenterContainer2/TextureRect
onready var margin_container = $MarginContainer
onready var accent_color_rect = $AccentColorRect
onready var file_name: Label = $"MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/FileName"
onready var file_path: Label = $"MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/FilePath"
onready var item_list: ItemList = $MarginContainer/HBoxContainer/VBoxContainer/ItemList

var _file: FuzzyFile
var _focused := false
var _item_list_focused := false
var _accent_color: Color
var _base_color: Color

signal clicked(file)
signal clicked_property(file, property)


func set_file(
	file: FuzzyFile,
	compact_mode: bool,
	base_scale: float,
	bold_font: Font,
	smaller_font: Font,
	accent_color: Color,
	base_color: Color,
	icons: Dictionary
) -> void:
	if not file.is_connected("updated", self, "set_file"):
		file.connect(
			"updated",
			self,
			"set_file",
			[compact_mode, base_scale, bold_font, smaller_font, accent_color, base_color, icons]
		)

	_file = file
	_accent_color = accent_color
	_base_color = base_color

	self.rect_scale *= base_scale

	file_name.set("custom_fonts/font", bold_font)
	file_name.text = "%s.%s" % [file.name(), file.extension()]
	file_name.hint_tooltip = file_name.text

	file_path.text = file.path()
	file_path.hint_tooltip = file_path.text
	file_path.set("custom_fonts/font", smaller_font)

	texture_rect.texture = file.icon()
	texture_rect.modulate = accent_color
	texture_rect_preview.get_parent().rect_min_size *= base_scale
	texture_rect_preview.rect_min_size *= base_scale

	texture_rect_preview.texture = file.preview()
	# Modulate the icon so it always have contrast with the background
	var constrasted = base_color.contrasted()
	texture_rect_preview.modulate = Color.white.blend(constrasted * 0.25)

	if compact_mode:
		texture_rect_preview.get_parent().visible = false

	var matching_properties := file.matching_properties()
	item_list.clear()
	item_list.visible = matching_properties.size() > 0
	item_list.rect_min_size = (
		(Vector2(0, 48) if matching_properties.size() >= 2 else item_list.rect_min_size)
		* base_scale
	)
	if matching_properties.size() > 0:
		# File is a parsed script with matching properties
		for property in matching_properties:
			item_list.add_item(property.value, icons[property.type])


func _on_mouse_entered():
	_focused = true
	color_rect.color = _base_color
	accent_color_rect.visible = true
	accent_color_rect.color = _accent_color


func _on_mouse_exited():
	_focused = false
	color_rect.color = Color.transparent
	accent_color_rect.visible = false


func _on_gui_input(event: InputEvent):
	if (
		event is InputEventMouseButton
		and event.is_pressed()
		and event.button_index == BUTTON_LEFT
		and not _item_list_focused
	):
		emit_signal("clicked", _file)
		_on_mouse_exited()


func _input(event: InputEvent):
	if (
		event is InputEventKey
		and event.scancode == KEY_ENTER
		and _focused
		and not _item_list_focused
	):
		emit_signal("clicked", _file)
		_on_mouse_exited()


func _process(_delta):
	if _file != null and _file.is_recent():
		file_name.modulate = Color(0.8, 0.8, 0.8)
		file_path.modulate = Color(0.8, 0.8, 0.8)


func _on_focus_entered():
	_on_mouse_entered()


func _on_focus_exited():
	_on_mouse_exited()


func _on_item_list_focus_entered():
	_item_list_focused = true
	item_list.select(0)
	_on_mouse_entered()


func _on_item_list_focus_exited():
	_item_list_focused = false
	_on_mouse_entered()


func _on_item_activated(index):
	_item_list_focused = false
	_on_mouse_exited()
	emit_signal("clicked_property", _file, _file.matching_properties()[index])
