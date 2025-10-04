extends "res://Scripts/Parsers/ParserInterface.gd"

class_name ChartParser

# ChartParser.gd - Parses .chart files for rhythm game

func load_chart(path: String) -> Dictionary:
	# Check cache first
	var cached = ResourceCache.get_cached_chart(path)
	if not cached.is_empty():
		return cached
	
	if not FileAccess.file_exists(path):
		push_error("Chart file not found: " + path)
		return {}
		
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open chart file: " + path + " Error: " + str(FileAccess.get_open_error()))
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	if content.is_empty():
		push_error("Chart file is empty: " + path)
		return {}
	
	var sections = {}
	var current_section = ""
	var in_section = false
	
	var lines = content.split("\n")
	for line_num in range(lines.size()):
		var line = lines[line_num].strip_edges()
		if line.begins_with("[") and line.ends_with("]"):
			current_section = line.substr(1, line.length() - 2)
			sections[current_section] = []
			in_section = false
		elif line == "{":
			if current_section.is_empty():
				push_warning("Found opening brace without section at line " + str(line_num + 1))
				continue
			in_section = true
		elif line == "}":
			in_section = false
		elif in_section and line != "":
			if current_section.is_empty():
				push_warning("Found content without section at line " + str(line_num + 1))
				continue
			sections[current_section].append(line)
	
	if sections.is_empty():
		push_error("No valid sections found in chart file: " + path)
		return {}
	
	# Cache the result
	ResourceCache.cache_chart(path, sections)
	return sections

func get_resolution(sections: Dictionary) -> int:
	if sections.has("Song"):
		for line in sections["Song"]:
			if line.begins_with("Resolution = "):
				var value_str = line.split(" = ")[1]
				if value_str.is_valid_int():
					var resolution = int(value_str)
					if resolution > 0:
						return resolution
					else:
						push_warning("Invalid resolution value (must be > 0): " + value_str)
				else:
					push_warning("Non-integer resolution value: " + value_str)
	push_warning("No resolution found in chart, using default 192")
	return 192

func get_offset(sections: Dictionary) -> float:
	if sections.has("Song"):
		for line in sections["Song"]:
			if line.begins_with("Offset = "):
				var value_str = line.split(" = ")[1]
				if value_str.is_valid_float():
					return float(value_str) / 1000.0  # Convert milliseconds to seconds
				else:
					push_warning("Invalid offset value: " + value_str)
	return 0.0

func get_music_stream(sections: Dictionary) -> String:
	if sections.has("Song"):
		for line in sections["Song"]:
			if line.begins_with("MusicStream = "):
				var stream = line.split(" = ")[1].strip_edges().replace('"', '')
				# Check if it's an absolute path (starts with drive letter like C:\ or D:\)
				if stream.length() > 2 and stream[1] == ":" and stream[0].is_valid_identifier():
					print("Warning: Absolute path detected in chart MusicStream, ignoring: ", stream)
					return ""  # Return empty to fall back to searching for .ogg files
				return stream
	return ""  # Return empty if not found

func get_tempo_events(sections: Dictionary) -> Array:
	var events = []
	if sections.has("SyncTrack"):
		for line in sections["SyncTrack"]:
			if " = B " in line:
				var parts = line.split(" = B ")
				var tick = int(parts[0])
				var bpm = int(parts[1]) / 1000.0
				events.append({tick = tick, bpm = bpm})
	events.sort_custom(func(a, b): return a.tick < b.tick)
	return events

func get_notes(sections: Dictionary, instrument: String, resolution: int) -> Array:
	var notes = []
	var specials = {}  # pos -> {hopo_flip: bool, tap_flip: bool}
	# We'll collect raw notes first, then deduplicate by (pos,fret) to avoid overlapping duplicates
	
	if sections.has(instrument):
		for line in sections[instrument]:
			if " = N " in line:
				var parts = line.split(" = N ")
				var pos = int(parts[0])
				var vals = parts[1].split(" ")
				var fret = int(vals[0])
				var length = int(vals[1]) if vals.size() > 1 else 0
				
				if fret >= 0 and fret <= 4:
					notes.append({pos = pos, fret = fret, length = length})
				elif fret == 5:
					if not specials.has(pos):
						specials[pos] = {hopo_flip = false, tap_flip = false}
					specials[pos].hopo_flip = true
				elif fret == 6:
					if not specials.has(pos):
						specials[pos] = {hopo_flip = false, tap_flip = false}
					specials[pos].tap_flip = true
				elif fret == 7:
					# Open note, treat as fret 5
					notes.append({pos = pos, fret = 5, length = length})
	
	# Sort notes by position
	notes.sort_custom(func(a, b): return a.pos < b.pos)

	# Deduplicate any exact (pos,fret) collisions (can happen if chart has duplicated lines or parser invoked twice on same data)
	var deduped: Array = []
	var seen = {}
	for n in notes:
		var key = str(n.pos) + ":" + str(n.fret)
		if not seen.has(key):
			seen[key] = true
			deduped.append(n)
		else:
			# Prefer longer sustain if duplicate appears with different length
			for existing in deduped:
				if existing.pos == n.pos and existing.fret == n.fret:
					if n.length > existing.length:
						existing.length = n.length
					break
	if deduped.size() != notes.size():
		print("ChartParser: Removed ", notes.size() - deduped.size(), " duplicate note(s) for instrument ", instrument)
	notes = deduped
	
	# Determine HOPO and tap
	for i in range(notes.size()):
		var note = notes[i]
		var pos = note.pos
		
		# Natural HOPO: if previous note is different fret and within 16th note (resolution / 4)
		var is_natural_hopo = false
		if i > 0:
			var prev = notes[i - 1]
			var diff_ticks = pos - prev.pos
			var threshold = resolution / 4.0
			if diff_ticks <= threshold and prev.fret != note.fret:
				is_natural_hopo = true
		
		note.is_hopo = is_natural_hopo
		if specials.has(pos) and specials[pos].hopo_flip:
			note.is_hopo = !note.is_hopo
		
		note.is_tap = specials.has(pos) and specials[pos].tap_flip
	
	return notes

func get_note_times(notes: Array, resolution: int, tempo_events: Array) -> Array:
	var times = []
	var current_bpm = 120.0
	var last_tick = 0
	var accumulated_time = 0.0
	var event_index = 0
	for note in notes:
		var note_tick = note.pos
		while event_index < tempo_events.size() and tempo_events[event_index].tick <= note_tick:
			var event = tempo_events[event_index]
			var ticks_elapsed = event.tick - last_tick
			var time_elapsed = (ticks_elapsed / resolution) * (60.0 / current_bpm)
			accumulated_time += time_elapsed
			current_bpm = event.bpm
			last_tick = event.tick
			event_index += 1
		var ticks_from_last = note_tick - last_tick
		var time_from_last = (ticks_from_last / resolution) * (60.0 / current_bpm)
		var hit_time = accumulated_time + time_from_last
		times.append(hit_time)
	return times

func get_available_instruments(sections: Dictionary) -> Dictionary:
	var instruments = {}
	for section_name in sections.keys():
		if section_name != "Song" and section_name != "SyncTrack" and section_name != "Events":
			# Check if this instrument section actually has notes (N events)
			if sections.has(section_name) and has_notes_in_section(sections[section_name]):
				# Parse section name: e.g., "EasySingle" -> instrument="Single", difficulty="Easy"
				var instrument = ""
				var difficulty = ""
				if section_name.ends_with("Single"):
					instrument = "Single"
					difficulty = section_name.substr(0, section_name.length() - 6)
				elif section_name.ends_with("Drums"):
					instrument = "Drums"
					difficulty = section_name.substr(0, section_name.length() - 5)
				elif section_name.ends_with("Bass"):
					instrument = "Bass"
					difficulty = section_name.substr(0, section_name.length() - 4)
				elif section_name.ends_with("Guitar"):
					instrument = "Guitar"
					difficulty = section_name.substr(0, section_name.length() - 6)
				else:
					# Unknown instrument, skip or treat as is
					continue
				
				if not instruments.has(instrument):
					instruments[instrument] = []
				if not instruments[instrument].has(difficulty):
					instruments[instrument].append(difficulty)
	
	# Sort difficulties
	for inst in instruments.keys():
		instruments[inst].sort_custom(func(a, b): 
			var order = {"Easy": 0, "Medium": 1, "Hard": 2, "Expert": 3}
			return order.get(a, 99) < order.get(b, 99)
		)
	
	return instruments

func has_notes_in_section(section_lines: Array) -> bool:
	for line in section_lines:
		if " = N " in line:
			return true
	return false