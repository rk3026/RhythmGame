class_name StringFormatter
extends RefCounted

## StringFormatter - Static utility methods for string formatting operations
## Eliminates duplicate formatting code across UI scripts

## Format an integer score with comma separators for readability
## @param score: The score value to format (e.g., 123456)
## @return: Formatted string with commas (e.g., "123,456")
static func format_score(score: int) -> String:
	var score_str = str(score)
	var formatted = ""
	var count = 0
	
	for i in range(score_str.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = score_str[i] + formatted
		count += 1
	
	return formatted

## Format accuracy as a percentage with one decimal place
## @param accuracy: The accuracy value (0.0 to 100.0)
## @return: Formatted percentage string (e.g., "98.5%")
static func format_accuracy(accuracy: float) -> String:
	return ("%.1f" % accuracy) + "%"

## Format time in seconds as MM:SS
## @param total_seconds: Time in seconds
## @return: Formatted time string (e.g., "3:45")
static func format_time(total_seconds: float) -> String:
	var total_int = int(total_seconds)
	@warning_ignore("integer_division")
	var minutes = total_int / 60
	var seconds = total_int % 60
	return "%d:%02d" % [minutes, seconds]

## Convert HTML-style color tags to Godot BBCode format
## Converts <color=#HEX> to [color=#HEX] and </color> to [/color]
## Also normalizes missing '#' in hex color values
## @param text: Text containing HTML-style color tags
## @return: Text with Godot BBCode color tags
static func convert_color_tags_to_bbcode(text: String) -> String:
	var result := text

	# 1) Convert open tags: <color=#aabbcc> or <color=aabbcc>
	var re_open := RegEx.new()
	# Capture any value up to '>' allowing optional '#'
	re_open.compile("<color=([^>]+)>")
	result = re_open.sub(result, "[color=$1]", true)

	# 2) Convert close tags: </color>
	var re_close := RegEx.new()
	re_close.compile("</color>")
	result = re_close.sub(result, "[/color]", true)

	# 3) Ensure [color=HEX] has a leading '#'
	var re_missing_hash := RegEx.new()
	re_missing_hash.compile("\\[color=([0-9a-fA-F]{3,8})\\]")
	result = re_missing_hash.sub(result, "[color=#$1]", true)

	return result

## Format a large number with appropriate suffix (K, M, B)
## @param value: The number to format
## @return: Formatted string with suffix (e.g., "1.2K", "3.5M")
static func format_large_number(value: float) -> String:
	if value >= 1_000_000_000:
		return "%.1fB" % (value / 1_000_000_000)
	elif value >= 1_000_000:
		return "%.1fM" % (value / 1_000_000)
	elif value >= 1_000:
		return "%.1fK" % (value / 1_000)
	else:
		return str(int(value))
