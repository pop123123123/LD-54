class_name RelevanceSorter


func sort(a: FuzzyFile, b: FuzzyFile):
	return (a.is_recent() and not b.is_recent()) or a.score() < b.score()


func sort_properties(
	a: GDscriptParser.GDScriptParserResultProperty, b: GDscriptParser.GDScriptParserResultProperty
):
	return a.score < b.score
