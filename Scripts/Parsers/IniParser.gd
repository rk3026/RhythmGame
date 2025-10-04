extends RefCounted

# IniParser.gd - Parses song.ini files for rhythm game metadata

func parse_ini_file(ini_path: String) -> Dictionary:
	var file = FileAccess.open(ini_path, FileAccess.READ)
	if not file:
		push_error("Failed to open INI file: " + ini_path)
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	if content.is_empty():
		push_error("INI file is empty: " + ini_path)
		return {}
	
	var data = {}
	var current_section = ""
	var lines = content.split("\n")
	
	for line in lines:
		line = line.strip_edges()
		if line.begins_with("[") and line.ends_with("]"):
			current_section = line.substr(1, line.length() - 2)
			data[current_section] = {}
		elif "=" in line and current_section != "":
			var parts = line.split("=", false, 1)
			if parts.size() == 2:
				var key = parts[0].strip_edges()
				var value = parts[1].strip_edges()
				data[current_section][key] = value
	
	return data

func get_song_info_from_ini(chart_path: String) -> Dictionary:
	var ini_path = chart_path.get_base_dir() + "/song.ini"
	var ini_data = parse_ini_file(ini_path)
	
	if not ini_data.has("song"):
		return {}
	
	var song_section = ini_data["song"]
	var info = {}
	
	# Basic song information
	info["name"] = song_section.get("name", "")
	info["artist"] = song_section.get("artist", "")
	info["album"] = song_section.get("album", "")
	info["genre"] = song_section.get("genre", "")
	info["year"] = song_section.get("year", "")
	
	# Technical information
	info["diff_guitar"] = song_section.get("diff_guitar", "")
	info["icon"] = song_section.get("icon", "")
	info["album_track"] = song_section.get("album_track", "")
	info["playlist_track"] = song_section.get("playlist_track", "")
	info["charter"] = song_section.get("charter", "")
	
	# Timing information
	if song_section.has("preview_start_time") and song_section["preview_start_time"].is_valid_int():
		info["preview_start_time"] = float(song_section["preview_start_time"]) / 1000.0  # Convert ms to seconds
	else:
		info["preview_start_time"] = -1.0
	
	if song_section.has("song_length") and song_section["song_length"].is_valid_int():
		var length_ms = int(song_section["song_length"])
		var minutes = length_ms / 60000.0
		var seconds = (length_ms % 60000) / 1000.0
		info["song_length_formatted"] = "%d:%02d" % [int(minutes), int(seconds)]
		info["song_length_seconds"] = float(length_ms) / 1000.0
	else:
		info["song_length_formatted"] = ""
		info["song_length_seconds"] = 0.0
	
	# Loading phrase
	info["loading_phrase"] = song_section.get("loading_phrase", "")
	
	return info

func get_music_stream_from_ini(chart_path: String) -> String:
	var ini_path = chart_path.get_base_dir() + "/song.ini"
	var ini_data = parse_ini_file(ini_path)
	
	if ini_data.has("song") and ini_data["song"].has("MusicStream"):
		var music_path = ini_data["song"]["MusicStream"]
		# Check if it's an absolute path (starts with drive letter like C:\ or D:\)
		if music_path.length() > 2 and music_path[1] == ":" and music_path[0].is_valid_identifier():
			print("Warning: Absolute path detected in MusicStream, ignoring: ", music_path)
			return ""  # Return empty to fall back to searching for .ogg files
		return music_path
	
	return ""