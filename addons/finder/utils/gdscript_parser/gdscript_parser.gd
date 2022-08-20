class_name GDscriptParser

enum PROPERTY_TYPE { CLASS_NAME, SIGNAL, NAMED_ENUM, CONSTANT, VARIABLE, FUNCTION }

const PARSED_RESULT_CACHE_PATH = "res://addons/finder/.tmp"

const CLASS_NAME_EXPR_PATTERN = "^(class_name\\s*|class\\s*)(?<class>[\\w]+)"
const SIGNAl_EXPR_PATTERN = "^signal\\s*(?<name>[\\w]+)"
const NAMED_ENUM_EXPR_PATTERN = "^enum\\s*(?<name>[\\w]+)"
const CONSTANT_EXPR_PATTERN = "^const\\s*(?<name>[\\w]+)"
const VARIABLE_EXPR_PATTERN = "^(var|onready\\s*var|export\\s*var|export\\(.*\\)\\s*var)\\s*(?<name>[\\w]+)"
const FUNCTION_EXPR_PATTERN = "(^func|^static\\s*func)\\s*(?<name>[\\w]+)"

var _class_name_expr := RegEx.new()
var _signal_expr := RegEx.new()
var _named_enum_expr := RegEx.new()
var _constant_expr := RegEx.new()
var _variable_expr := RegEx.new()
var _function_expr := RegEx.new()
var _cache_dir_path := Directory.new()
var _parsed_scripts := {}
var _dir_walker: DirWalker


class GDScriptParserResultProperty:
	var value: String
	var row: int
	var column: int
	var type: int
	# Used when matching against a search
	var score: float

	func _init(_value, _row, _column, _type):
		value = _value
		row = _row
		column = _column
		type = _type

	func serialize():
		return {value = value, row = row, column = column, type = type}

	static func deserialize(from) -> GDScriptParserResultProperty:
		if not "value" in from or not from["value"] is String:
			return null
		elif not "row" in from or not from["row"] is float:
			return null
		elif not "column" in from or not from["column"] is float:
			return null
		elif not "type" in from or not from["type"] is float:
			return null

		return GDScriptParserResultProperty.new(
			from["value"], int(from["row"]), int(from["column"]), int(from["type"])
		)


class GDScriptParserResultPropertyArray:
	var values: Dictionary

	func has(property: String):
		return values.has(property)

	func get(property: String):
		return values[property]

	func set(property: String, value: GDScriptParserResultProperty):
		values[property] = value

	func serialize():
		var result := {}

		for key in values.keys():
			result[key] = values[key].serialize()

		return result

	func enumerate() -> Array:
		return values.values()

	static func deserialize(from) -> GDScriptParserResultPropertyArray:
		if not from is Dictionary:
			return null

		var _self := GDScriptParserResultPropertyArray.new()

		for key in from.keys():
			var result := GDScriptParserResultProperty.deserialize(from[key])

			if result == null:
				return null

			_self.set(key, result)

		return _self


class GDScriptParserResult:
	var _class_name: GDScriptParserResultProperty
	var _signals := GDScriptParserResultPropertyArray.new()
	var _named_enums := GDScriptParserResultPropertyArray.new()
	var _constants := GDScriptParserResultPropertyArray.new()
	var _variables := GDScriptParserResultPropertyArray.new()
	var _functions := GDScriptParserResultPropertyArray.new()

	func serialize():
		return {
			"class_name": _class_name.serialize() if _class_name != null else null,
			signals = _signals.serialize(),
			named_enums = _named_enums.serialize(),
			constants = _constants.serialize(),
			variables = _variables.serialize(),
			functions = _functions.serialize()
		}

	func enumerate() -> Array:
		var arr := []

		if _class_name != null:
			arr.append(_class_name)

		arr.append_array(_signals.enumerate())
		arr.append_array(_named_enums.enumerate())
		arr.append_array(_constants.enumerate())
		arr.append_array(_variables.enumerate())
		arr.append_array(_functions.enumerate())

		return arr

	static func deserialize(json: String) -> GDScriptParserResult:
		var parsed := JSON.parse(json)

		if parsed.error != OK and parsed.result is Dictionary:
			return null

		var result = parsed.result

		var _class_name = GDScriptParserResultProperty.deserialize(result["class_name"])
		if _class_name == null:
			return null

		var _signals = GDScriptParserResultPropertyArray.deserialize(result["signals"])
		if _signals == null:
			return null

		var _named_enums = GDScriptParserResultPropertyArray.deserialize(result["named_enums"])
		if _named_enums == null:
			return null

		var _constants = GDScriptParserResultPropertyArray.deserialize(result["constants"])
		if _constants == null:
			return null

		var _variables = GDScriptParserResultPropertyArray.deserialize(result["variables"])
		if _variables == null:
			return null

		var _functions = GDScriptParserResultPropertyArray.deserialize(result["functions"])
		if _functions == null:
			return null

		return GDScriptParserResult.new()


func _init():
	_class_name_expr.compile(CLASS_NAME_EXPR_PATTERN)
	_signal_expr.compile(SIGNAl_EXPR_PATTERN)
	_named_enum_expr.compile(NAMED_ENUM_EXPR_PATTERN)
	_constant_expr.compile(CONSTANT_EXPR_PATTERN)
	_variable_expr.compile(VARIABLE_EXPR_PATTERN)
	_function_expr.compile(FUNCTION_EXPR_PATTERN)
	_dir_walker = DirWalker.new(PARSED_RESULT_CACHE_PATH)

	if not _cache_dir_path.dir_exists(PARSED_RESULT_CACHE_PATH):
		if _cache_dir_path.make_dir(PARSED_RESULT_CACHE_PATH) != OK:
			printerr("[Finder] Could not create cache directory for parsed scripts")
			return

		if not _dir_walker.walk(funcref(self, "_load_cached_parsed_scripts")):
			print_debug("[Finder] Failed to open cache directory")
			return


func parse(file_path: String) -> GDScriptParserResult:
	if not ResourceLoader.exists(file_path) or file_path.get_extension() != "gd":
		print_debug("Tried to parse non-script")
		return null

	var file := File.new()
	file.open(file_path, File.READ)
	var checksum := file.get_md5(file_path)
	var file_identifier := _get_file_identifier(file_path, checksum)

	if _parsed_scripts.has(file_identifier):
		return _parsed_scripts[file_identifier]

	if file.open(file_path, File.READ) != OK:
		print_debug("[Finder] Couldn't open script for reading")
		return null

	var parser_result := GDScriptParserResult.new()

	# So it starts at zero for the parsers
	var idx := -1
	while file.get_position() < file.get_len():
		idx += 1

		var line := file.get_line()

		if _parse_class_name(idx, line, file, parser_result):
			continue

		if _parse_signal(idx, line, file, parser_result):
			continue

		if _parse_constant(idx, line, file, parser_result):
			continue

		if _parse_named_enum(idx, line, file, parser_result):
			continue

		if _parse_variable(idx, line, file, parser_result):
			continue

		if _parse_function(idx, line, file, parser_result):
			continue

	_cache_parsed_script(file_path, checksum, parser_result)

	return parser_result


func purge_cache() -> void:
	_dir_walker.walk(funcref(DirWalker, "delete_every_file"))
	_parsed_scripts = {}


func _parse_class_name(
	idx: int, line: String, file: File, parser_result: GDScriptParserResult
) -> bool:
	if parser_result._class_name:
		return false

	var expr_result := _class_name_expr.search(line)
	if expr_result != null:
		var result := expr_result.get_string("class")
		parser_result._class_name = GDScriptParserResultProperty.new(
			result, idx, expr_result.get_start("class"), PROPERTY_TYPE.CLASS_NAME
		)
		return true

	return false


func _parse_signal(idx: int, line: String, file: File, parser_result: GDScriptParserResult) -> bool:
	var expr_result := _signal_expr.search(line)
	if expr_result != null:
		var signal_name := expr_result.get_string("name")

		if parser_result._signals.has(signal_name):
			return true

		parser_result._signals.set(
			signal_name,
			GDScriptParserResultProperty.new(
				signal_name, idx, expr_result.get_start("name"), PROPERTY_TYPE.SIGNAL
			)
		)

		return true

	return false


func _parse_named_enum(
	idx: int, line: String, file: File, parser_result: GDScriptParserResult
) -> bool:
	var expr_result := _named_enum_expr.search(line)
	if expr_result != null:
		var enum_name := expr_result.get_string("name")

		if parser_result._named_enums.has(enum_name):
			return true

		parser_result._named_enums.set(
			enum_name,
			GDScriptParserResultProperty.new(
				enum_name, idx, expr_result.get_start("name"), PROPERTY_TYPE.NAMED_ENUM
			)
		)

		return true

	return false


func _parse_constant(
	idx: int, line: String, file: File, parser_result: GDScriptParserResult
) -> bool:
	var expr_result := _constant_expr.search(line)
	if expr_result != null:
		var constant_name := expr_result.get_string("name")

		if parser_result._constants.has(constant_name):
			return true

		parser_result._constants.set(
			constant_name,
			GDScriptParserResultProperty.new(
				constant_name, idx, expr_result.get_start("name"), PROPERTY_TYPE.CONSTANT
			)
		)

		return true

	return false


func _parse_variable(
	idx: int, line: String, file: File, parser_result: GDScriptParserResult
) -> bool:
	var expr_result := _variable_expr.search(line)
	if expr_result != null:
		var variable_name := expr_result.get_string("name")

		if parser_result._variables.has(variable_name):
			return true

		parser_result._variables.set(
			variable_name,
			GDScriptParserResultProperty.new(
				variable_name, idx, expr_result.get_start("name"), PROPERTY_TYPE.VARIABLE
			)
		)

		return true

	return false


func _parse_function(
	idx: int, line: String, file: File, parser_result: GDScriptParserResult
) -> bool:
	var expr_result := _function_expr.search(line)
	if expr_result != null:
		var function_name := expr_result.get_string("name")

		if parser_result._functions.has(function_name):
			return true

		parser_result._functions.set(
			function_name,
			GDScriptParserResultProperty.new(
				function_name, idx, expr_result.get_start("name"), PROPERTY_TYPE.FUNCTION
			)
		)

		return true

	return false


func _get_file_identifier(file_path: String, checksum: String) -> String:
	return "%s_%s.json" % [file_path.md5_text(), checksum]


func _load_cached_parsed_scripts(dir: Directory, file: File) -> void:
	if OS.get_unix_time() - file.get_modified_time(file.get_path_absolute()) > 86400:
		_cache_dir_path.remove(file.get_path_absolute())
		return

	var content := file.get_as_text()

	var parsed_script := GDScriptParserResult.deserialize(content)
	if parsed_script == null:
		return

	var file_identifier = _get_file_identifier(
		file.get_path_absolute(), file.get_md5(file.get_path_absolute())
	)
	_parsed_scripts[file_identifier] = parsed_script


func _cache_parsed_script(
	file_path: String, checksum: String, parsed_script: GDScriptParserResult
) -> void:
	var file_identifier := _get_file_identifier(file_path, checksum)
	var file := File.new()

	_dir_walker.walk(funcref(self, "_delete_old_parsed_script"), [file_identifier])

	_parsed_scripts[file_identifier] = parsed_script
	if file.open("%s/%s" % [PARSED_RESULT_CACHE_PATH, file_identifier], File.WRITE) != OK:
		print_debug("[Finder] Could not save parsed script cache")
		return
	file.store_string(JSON.print(parsed_script.serialize()))
	file.close()


func _delete_old_parsed_script(dir: Directory, file: File, file_identifier):
	# Because the file identifier is composed of the MD5 of the file path
	# We can check it to see if we are overriding a previously cached
	# file, in which case we delete the old one.
	if file.get_path().get_file().begins_with(file_identifier.split("_")[0]):
		dir.remove(file.get_path_absolute())
