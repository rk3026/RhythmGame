class_name ParserFactory
extends RefCounted

# ParserFactory.gd - Factory for creating appropriate parsers based on file type

const ChartParserScript = preload("res://Scripts/Parsers/ChartParser.gd")
const MidiParserScript = preload("res://Scripts/Parsers/MidiParser.gd")
const IniParserScript = preload("res://Scripts/Parsers/IniParser.gd")

func create_parser_for_file(file_path: String):
	var extension = file_path.get_extension().to_lower()
	
	match extension:
		"chart":
			return ChartParserScript.new()
		"mid", "midi":
			return MidiParserScript.new()
		_:
			push_error("Unsupported file type: " + extension)
			return null

func create_metadata_parser():
	return IniParserScript.new()

func get_supported_extensions() -> Array:
	return ["chart", "mid", "midi"]

func is_supported_file(file_path: String) -> bool:
	var extension = file_path.get_extension().to_lower()
	return extension in get_supported_extensions()