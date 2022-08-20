class_name FuzzyMatching

const FILE_THRESHOLD = 0.6
const PROPERTY_THRESHOLD = 0.6

const FILE_WHOLE_PATH_SUB_STRING_SCORE = 0.2
const FILE_NAME_SUB_STRING_SCORE = 0.1
const PROPERTY_SUB_STRING_SCORE = 0.05
const STRICT_MATCH_CHAR = "!"


static func classify(file: FuzzyFile, search: String) -> bool:
	var search_fragments := search.split(" ")

	if search_fragments[-1].empty():
		search_fragments.remove(search_fragments.size() - 1)

	var valid_fragments := 0
	file.set_score(1.0)

	for search_fragment in search_fragments:
		var strict_mode = search_fragment.begins_with(STRICT_MATCH_CHAR)
		if strict_mode:
			search_fragment.erase(0, 1)

		if (
			file.parsing_result() != null
			and (not search_fragments.size() > 1 or valid_fragments == search_fragments.size() - 1)
			and search_fragment.findn("/") < 0
		):
			var properties = file.parsing_result().enumerate()

			for property in properties:
				var normalized_search = search_fragment.replace("_", "")
				var score: float = min(
					(
						PROPERTY_SUB_STRING_SCORE
						if property.value.findn(search_fragment) >= 0.0
						else 1.0
					),
					min(
						_check_for_underscore_abbreaviation(property.value, normalized_search),
						min(
							_check_for_camel_case_abbreaviation(property.value, normalized_search),
							_levenshtein_distance(property.value, search_fragment, strict_mode)
						)
					)
				)

				if score <= PROPERTY_THRESHOLD:
					property.score = score
					file.append_to_matching_properties(property)

		var score := _fuzzy_match_file(file, search_fragment, strict_mode)
		if (
			score <= FILE_THRESHOLD
			or (file.parsing_result() != null and file.matching_properties().size() > 0)
		):
			file.set_score(min(file.score(), score) if file.score() >= 0.0 else score)
			valid_fragments += 1

	return valid_fragments == search_fragments.size()


static func _fuzzy_match_file(file: FuzzyFile, search: String, strict_mode: bool) -> float:
	if search.findn("/") >= 0:
		# Searching for a path
		return (
			0.0
			if file.whole_path().findn(search) >= 0
			else _levenshtein_distance(file.whole_path(), search, strict_mode)
		)

	var abbreviation_score: float

	abbreviation_score = _check_for_underscore_abbreaviation(file.name(), search)

	if abbreviation_score < 1:
		return abbreviation_score

	abbreviation_score = _check_for_camel_case_abbreaviation(file.name(), search)

	if abbreviation_score < 1:
		return abbreviation_score

	var file_whole_path_substring_score = 1.0
	if file.whole_path().findn(search) >= 0:
		file_whole_path_substring_score = FILE_WHOLE_PATH_SUB_STRING_SCORE

	var file_name_substring_score = 1.0
	if file.full_name().findn(search) >= 0:
		# Favorable in relation to a whole_path substring match
		file_name_substring_score = FILE_NAME_SUB_STRING_SCORE

	if file_whole_path_substring_score < 1.0 or file_name_substring_score < 1.0:
		return min(file_whole_path_substring_score, file_name_substring_score)

	var name_score = _levenshtein_distance(file.full_name(), search, strict_mode)
	var whole_path_score = _levenshtein_distance(file.whole_path(), search, strict_mode)

	return min(
		name_score + (0.01 if name_score < 1 else 0.0),
		whole_path_score + (0.01 if whole_path_score < 1 else 0.0)
	)


static func _levenshtein_distance(this: String, that: String, strict_mode: bool) -> float:
	# If strict matching, no levenshtein distance
	if strict_mode:
		return 1.0

	var _this := this
	var _that := that

	if len(this) > len(that):
		_this = that
		_that = this

	var distances := range(len(_this) + 1)
	var that_index := 0
	for that_char in _that:
		var new_distances := [that_index + 1]

		var this_index := 0
		for this_char in _this:
			if this_char == that_char:
				new_distances.append(distances[this_index])
			else:
				new_distances.append(
					(
						1
						+ min(
							min(distances[this_index], distances[this_index + 1]), new_distances[-1]
						)
					)
				)
			this_index += 1

		distances = [] + new_distances
		that_index += 1

	return float(distances[-1]) / float(len(_that))


static func _check_for_abbreaviation(full_split: PoolStringArray, abbreviation: String) -> float:
	var index := 0
	for piece in full_split:
		if piece.empty():
			continue

		if index == len(abbreviation):
			return 0.0

		if piece[0].to_lower() == abbreviation[index].to_lower():
			index += 1
		else:
			break

	if index == len(abbreviation):
		return 0.0

	return 1.0


static func _check_for_underscore_abbreaviation(full: String, abbreviation: String) -> float:
	if full.begins_with("_"):
		full.erase(0, 1)

	return _check_for_abbreaviation(full.split("_"), abbreviation)


static func _check_for_camel_case_abbreaviation(full: String, abbreviation: String) -> float:
	# start the builder list with the first character
	# enforce upper case
	var builder_list := []
	for c in full:
		if builder_list.empty():
			builder_list.append(c.to_upper())
			continue
		# get the last character in the last element in the builder
		# note that strings can be addressed just like lists
		var previous_character = builder_list[-1][-1]
		if previous_character.to_lower() == previous_character and c.to_upper() == c:
			# start a new element in the list
			builder_list.append(c)
		else:
			# append the character to the last string
			builder_list[-1] += c

	return _check_for_abbreaviation(builder_list, abbreviation)
