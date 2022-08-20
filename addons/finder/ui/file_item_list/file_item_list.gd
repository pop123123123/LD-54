tool
extends ScrollContainer

onready var v_box_container: VBoxContainer = $VBoxContainer
onready var empty_label: Label = $VBoxContainer/EmptyLabel
onready var easter_egg_label: Label = $VBoxContainer/EasterEggLabel

var file_item = preload("res://addons/finder/ui/file_item_list/file_item.tscn")
var _editor_interface: EditorInterface
var _previous_focus: Node
var _active := false
var _bold_font: Font
var _smaller_font: Font
var _accent_color: Color
var _base_color: Color
var _icons := {}

signal clicked(file)
signal clicked_property(file, property)


func set_editor_interface(editor_interface: EditorInterface):
	_editor_interface = editor_interface
	set_custom_resources(
		_editor_interface.get_base_control(), _editor_interface.get_editor_settings()
	)


func set_previous_focus(previous_focus: Node):
	_previous_focus = previous_focus


func set_active(active: bool):
	_active = active


func set_custom_resources(gui: Control, editor_settings: EditorSettings):
	var font := gui.get_font("main", "EditorFonts").duplicate()
	if font is DynamicFont:
		font.size *= 0.75
		_smaller_font = font
		easter_egg_label.add_font_override("font", _smaller_font)

	_bold_font = gui.get_font("bold", "EditorFonts")

	_accent_color = editor_settings.get_setting("interface/theme/accent_color")
	_base_color = editor_settings.get_setting("interface/theme/base_color")

	_icons[GDscriptParser.PROPERTY_TYPE.CLASS_NAME] = gui.get_icon("ClassList", "EditorIcons")
	_icons[GDscriptParser.PROPERTY_TYPE.SIGNAL] = gui.get_icon("MemberSignal", "EditorIcons")
	_icons[GDscriptParser.PROPERTY_TYPE.NAMED_ENUM] = gui.get_icon("Enum", "EditorIcons")
	_icons[GDscriptParser.PROPERTY_TYPE.CONSTANT] = gui.get_icon("MemberConstant", "EditorIcons")
	_icons[GDscriptParser.PROPERTY_TYPE.VARIABLE] = gui.get_icon("MemberProperty", "EditorIcons")
	_icons[GDscriptParser.PROPERTY_TYPE.FUNCTION] = gui.get_icon("MemberMethod", "EditorIcons")


func clear():
	for child in v_box_container.get_children():
		if child == empty_label or child == easter_egg_label:
			continue

		if child is FileItem:
			child.disconnect("clicked", self, "_on_clicked")
			child.disconnect("clicked_property", self, "_on_clicked_property")
			if child._file.is_connected("updated", self, "set_file"):
				child._file.disconnect("updated", self, "set_file")

		v_box_container.remove_child(child)
		child.queue_free()

	empty_label.visible = true
	easter_egg_label.visible = true


func add_item(file: FuzzyFile):
	var label: FileItem = file_item.instance()
	v_box_container.add_child(label)
	label.connect("clicked", self, "_on_clicked")
	label.connect("clicked_property", self, "_on_clicked_property")

	var compact_mode = _editor_interface.get_editor_settings().get("finder/compact_mode")
	var base_scale = _editor_interface.get_editor_settings().get(
		"interface/editor/custom_display_scale"
	)
	label.set_file(
		file,
		compact_mode,
		base_scale,
		_bold_font,
		_smaller_font,
		_accent_color,
		_base_color,
		_icons
	)

	# 1 - EmptyLabel
	# 2 - EasterEggLabel
	if v_box_container.get_child_count() == 3:
		label.focus_previous = _previous_focus.get_path()
		v_box_container.add_child(HSeparator.new())
	elif v_box_container.get_child_count() > 3:
		label.focus_neighbour_top = v_box_container.get_child(v_box_container.get_child_count() - 3).get_path()

	if (v_box_container.get_child_count()) % 2 == 0 and v_box_container.get_child_count() > 3:
		v_box_container.add_child(HSeparator.new())

	empty_label.visible = false
	easter_egg_label.visible = false


func _unhandled_key_input(event: InputEventKey):
	if not _active:
		return

	if event.scancode == KEY_PAGEUP:
		_focus_first()
	elif event.scancode == KEY_PAGEDOWN:
		_focus_last()


func _on_clicked(file):
	emit_signal("clicked", file)


func _on_clicked_property(file, property):
	emit_signal("clicked_property", file, property)


func _on_focus_entered():
	_focus_first()


func _focus_first():
	# The zeroth index is the EmptyLabel and the oneth is the EasterEggLabel
	if v_box_container.get_child_count() > 2:
		v_box_container.get_child(2).call_deferred("grab_focus")
		get_v_scrollbar().value = 0


func _focus_last():
	if v_box_container.get_child_count() > 2:
		v_box_container.get_child(v_box_container.get_child_count() - 2).call_deferred("grab_focus")
		get_v_scrollbar().value = get_v_scrollbar().max_value
