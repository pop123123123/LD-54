class_name FuzzyFile

var _name: String
var _extension: String
var _path: String
var _score: float
var _icon: Texture
var _preview: Texture
# Specific to scripts
var _parsing_result: GDscriptParser.GDScriptParserResult
var _matching_properties := []  # of GDscriptParser.GDScriptParserResultProperty

var _is_recent := false

signal updated(file)


func _init(
	name: String, extension: String, path: String, score: float, icon: Texture, preview: Texture
):
	_name = name
	_extension = extension
	_path = path.replace("res:///", "res://")
	_score = score
	_icon = icon
	_preview = preview


func name() -> String:
	return _name


func extension() -> String:
	return _extension


func full_name() -> String:
	return "%s.%s" % [name(), extension()]


func path() -> String:
	return _path


func score() -> float:
	return _score


func icon() -> Texture:
	return _icon


func preview() -> Texture:
	return _preview


func is_recent() -> bool:
	return _is_recent


func whole_path() -> String:
	return ("%s/%s.%s" % [path(), name(), extension()]).replace("res:///", "res://")


func parsing_result() -> GDscriptParser.GDScriptParserResult:
	return _parsing_result


func matching_properties() -> Array:
	return _matching_properties


func set_score(score: float) -> void:
	_score = score
	emit_signal("updated", self)


func set_icon(icon: Texture) -> void:
	_icon = icon
	emit_signal("updated", self)


func set_preview(preview: Texture) -> void:
	_preview = preview
	emit_signal("updated", self)


func set_is_recent(is_recent: bool) -> void:
	_is_recent = is_recent
	emit_signal("updated", self)


func set_parsing_result(parsing_result: GDscriptParser.GDScriptParserResult):
	_parsing_result = parsing_result
	emit_signal("updated", self)


func append_to_matching_properties(property: GDscriptParser.GDScriptParserResultProperty):
	_matching_properties.append(property)
	emit_signal("updated", self)


func clear_matching_properties():
	_matching_properties = []
	emit_signal("updated", self)


func sort_properties(sorter) -> void:
	_matching_properties.sort_custom(sorter, "sort_properties")
