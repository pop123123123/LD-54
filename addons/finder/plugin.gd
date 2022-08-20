tool
extends EditorPlugin

const ACTIVATION_SHORTCUT = KEY_SHIFT
const ACTIVATION_LEEWAY = 250
const RELOADING_DELAY := 5  # seconds

var _last_valid_key_event = null
var _finder: Finder
var _parser: GDscriptParser
var _excluded_paths := PoolStringArray()
var _smart_suggestions := false
var _compact_mode := false
var _last_reloaded := 0


func _enter_tree():
	_finder = preload("res://addons/finder/finder.tscn").instance()
	_finder.connect("clicked", self, "_on_clicked")
	_finder.connect("clicked_property", self, "_on_clicked_property")
	_finder.connect("rebuild", self, "_build_file_tree", [true])
	_finder.set_editor_interface(get_editor_interface())

	_parser = GDscriptParser.new()

	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, _finder)

	get_editor_interface().get_resource_filesystem().connect(
		"filesystem_changed", self, "_build_file_tree"
	)

	get_editor_interface().get_editor_settings().connect(
		"settings_changed", self, "_update_preferences"
	)

	_build_file_tree()

	_build_editor_settings()

	_finder.prepare()

	_update_preferences(true)


func _unhandled_key_input(event: InputEventKey):
	if event.scancode == ACTIVATION_SHORTCUT and not event.is_pressed():
		var current_time = OS.get_ticks_msec()

		if _last_valid_key_event == null:
			_last_valid_key_event = {event = event, time = current_time}
		else:
			if current_time - _last_valid_key_event.time <= ACTIVATION_LEEWAY:
				# Because Godot does some behind the scenes changes when an Editor Setting
				# is changed, we gotta wait a little bit before showing the finder,
				# else we gonna get some nasty errors.
				var remaing_time_due_reloading := (
					RELOADING_DELAY
					- (OS.get_unix_time() - _last_reloaded)
				)
				if remaing_time_due_reloading > 0:
					var wait: WaitDialog = load("res://addons/finder/ui/wait_dialog/wait_dialog.tscn").instance()
					add_child(wait)
					wait.popup()
					yield(get_tree().create_timer(remaing_time_due_reloading), "timeout")
					wait.queue_free()

				_finder.popup_centered()

			_last_valid_key_event = {event = event, time = current_time}


func _update_preferences(first_time: bool = false):
	var excluded_paths: PoolStringArray = get_editor_interface().get_editor_settings().get(
		"finder/excluded_paths"
	)
	var compact_mode: bool = get_editor_interface().get_editor_settings().get("finder/compact_mode")
	var smart_suggestions: bool = get_editor_interface().get_editor_settings().get(
		"finder/smart_suggestions"
	)
	var preferences_changed := false

	if excluded_paths != _excluded_paths:
		_excluded_paths = excluded_paths
		preferences_changed = true

	if compact_mode != _compact_mode:
		_compact_mode = compact_mode
		preferences_changed = true

	if smart_suggestions != _smart_suggestions:
		_smart_suggestions = smart_suggestions
		preferences_changed = true

	if preferences_changed:
		if not first_time:
			_exit_tree()
			_enter_tree()
			_last_reloaded = OS.get_unix_time()

		_build_file_tree(true)


func _build_file_tree(ignore_cache: bool = false):
	var files := []  # accumulated png paths to return
	var dir_queue := ["res://"]  # directories remaining to be traversed
	var dir: Directory  # current directory being traversed
	var gui := get_editor_interface().get_base_control()

	if ignore_cache:
		_parser.purge_cache()

	var file: String  # current file being examined
	while file or not dir_queue.empty():
		# continue looping until there are no files or directories left
		if file:
			# there is another file in this directory
			if dir.current_is_dir():
				var ok = true
				var dir_path = "%s/%s" % [dir.get_current_dir(), file]
				# Godot < 3.5 does not have the 'has' method in the PoolStringArray
				for excluded_path in _excluded_paths:
					if dir_path.replace("res:///", "res://").begins_with(excluded_path):
						ok = false
						break

				if ok:
					# found a directory, append it to the queue.
					dir_queue.append(dir_path)
			else:
				var whole_path = "%s/%s" % [dir.get_current_dir(), file]

				if ResourceLoader.exists(whole_path):
					var fuzzy_file = FuzzyFile.new(
						file.get_basename(),
						file.get_extension(),
						dir.get_current_dir(),
						-1,
						ImageTexture.new(),
						ImageTexture.new()
					)

					if not _compact_mode:
						_queue_file_preview(fuzzy_file)

					_find_best_icon_for_file_extension(gui, fuzzy_file)

					if _smart_suggestions and fuzzy_file.extension() == "gd":
						var parsing_result := _parser.parse(fuzzy_file.whole_path())
						if parsing_result != null:
							fuzzy_file.set_parsing_result(parsing_result)

					files.append(fuzzy_file)
		else:
			# there are no more files in this directory
			if dir:
				# close the current directory
				dir.list_dir_end()

			if dir_queue.empty():
				# there are no more directories. terminate the loop
				break

			# there are more directories. open the next directory
			dir = Directory.new()
			dir.open(dir_queue.pop_front())
			dir.list_dir_begin(true, true)
		file = dir.get_next()

	_finder.set_files(files)


func _queue_file_preview(file: FuzzyFile):
	var whole_path = file.whole_path()

	get_editor_interface().get_resource_previewer().queue_edited_resource_preview(
		load(whole_path), self, "_on_resource_preview_ready", file
	)


func _find_best_icon_for_file_extension(gui, file: FuzzyFile) -> void:
	file.set_icon(gui.get_icon("Object", "EditorIcons"))

	match file.extension():
		"gd":
			file.set_icon(gui.get_icon("Script", "EditorIcons"))
		"tscn":
			file.set_icon(gui.get_icon("PlayScene", "EditorIcons"))


func _on_resource_preview_ready(
	path: String, preview: Texture, thumbnail_preview: Texture, file: FuzzyFile
):
	file.set_preview(preview)


func _on_clicked(file: FuzzyFile):
	# Hack so we don't accidently transfer a "ui_accept" to the editor
	yield(get_tree().create_timer(0.1), "timeout")

	var whole_path = file.whole_path()

	_finder.hide()

	get_editor_interface().call_deferred("select_file", whole_path)
	get_editor_interface().get_file_system_dock().call_deferred("navigate_to_path", whole_path)

	if file.extension() == "tscn":
		get_editor_interface().call_deferred("open_scene_from_path", whole_path)
	else:
		get_editor_interface().call_deferred("edit_resource", load(whole_path))


func _on_clicked_property(file: FuzzyFile, property: GDscriptParser.GDScriptParserResultProperty):
	yield(get_tree().create_timer(0.1), "timeout")

	var whole_path = file.whole_path()

	_finder.hide()

	get_editor_interface().call_deferred("select_file", whole_path)

	get_editor_interface().call_deferred("edit_resource", load(whole_path))
	var script_editor := get_editor_interface().get_script_editor()
	# Yeah, another hack, but blame Godot for not exposing gotocolumn from the script_editor itself
	yield(get_tree().create_timer(0.1), "timeout")
	var script_text_editor_container := script_editor.get_child(0).get_child(1).get_child(1)

	var idx := 0
	var open_scripts := script_editor.get_open_scripts()
	for script_text_editor in script_text_editor_container.get_children():
		if script_text_editor.get_class() != "ScriptTextEditor":
			continue

		var script = open_scripts[idx]

		if script.resource_path == whole_path:
			var text_edit: TextEdit = script_text_editor.find_node("TextEdit", true, false)
			yield(get_tree().create_timer(0.1), "timeout")
			text_edit.call_deferred("cursor_set_column", property.column)
			text_edit.call_deferred("cursor_set_line", property.row, false)
			text_edit.call_deferred(
				"select",
				property.row,
				property.column,
				property.row,
				property.column + len(property.value)
			)

			# Godot 3.3 doesn't have get_tree().create_tween()
			var tween := Tween.new()
			add_child(tween)
			tween.interpolate_property(
				text_edit,
				"scroll_vertical",
				text_edit.scroll_vertical,
				float(property.row) - 10.0,
				# Godot 3.3 doesn't have "get_visible_rows", so we use an arbitrary delay
				1.5,
				Tween.TRANS_CUBIC,
				Tween.EASE_OUT
			)
			tween.start()
			return

		idx += 1


func _build_editor_settings():
	var editor_settings := get_editor_interface().get_editor_settings()

	if not editor_settings.has_setting("finder/excluded_paths"):
		editor_settings.set("finder/excluded_paths", [])

		editor_settings.add_property_info(
			{
				"name": "finder/excluded_paths",
				"type": TYPE_STRING_ARRAY,
			}
		)

	if not editor_settings.has_setting("finder/compact_mode"):
		editor_settings.set("finder/compact_mode", false)

		editor_settings.add_property_info(
			{
				"name": "finder/compact_mode",
				"type": TYPE_BOOL,
			}
		)

	if not editor_settings.has_setting("finder/smart_suggestions"):
		editor_settings.set("finder/smart_suggestions", true)

		editor_settings.add_property_info(
			{
				"name": "finder/smart_suggestions",
				"type": TYPE_BOOL,
			}
		)


func _exit_tree():
	_last_valid_key_event = null
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, _finder)
	_finder.queue_free()

	get_editor_interface().get_resource_filesystem().disconnect(
		"filesystem_changed", self, "_build_file_tree"
	)

	get_editor_interface().get_editor_settings().disconnect(
		"settings_changed", self, "_update_preferences"
	)
