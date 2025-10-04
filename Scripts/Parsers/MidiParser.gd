class_name MidiParser
extends ParserInterface

var cached_data = {}

func load_chart(path: String) -> Dictionary:
	if cached_data.has(path):
		var data = cached_data[path]
		if not data.has("path"):
			data["path"] = path
		return data

	var midi_parser = MidiFileParser.load_file(path)
	if not midi_parser or midi_parser.state == MidiFileParser.MIDI_PARSER_ERROR:
		push_error("Failed to parse MIDI file: " + path)
		return {}

	var data = _convert_midi_data(midi_parser)

	# Store the path for music stream lookup
	data["path"] = path
	cached_data[path] = data
	return data

func _convert_midi_data(midi_parser: MidiFileParser) -> Dictionary:
	var tracks = []
	for track in midi_parser.tracks:
		var events = []
		for event in track.events:
			var event_data = {
				"delta_time": event.delta_ticks,
				"absolute_ticks": event.absolute_ticks
			}
			if event is MidiFileParser.Midi:
				event_data["type"] = "midi"
				event_data["status"] = event.status
				event_data["channel"] = event.channel
				event_data["param1"] = event.param1
				event_data["param2"] = event.param2
				if event.status == MidiFileParser.Midi.Status.NOTE_ON:
					event_data["type"] = "note_on"
				elif event.status == MidiFileParser.Midi.Status.NOTE_OFF:
					event_data["type"] = "note_off"
			elif event is MidiFileParser.Meta:
				if event.type == MidiFileParser.Meta.Type.SET_TEMPO:
					event_data["type"] = "tempo"
					event_data["tempo"] = event.value  # microseconds per quarter note
				elif event.type == MidiFileParser.Meta.Type.TIME_SIGNATURE:
					event_data["type"] = "time_signature"
					event_data["numerator"] = event.bytes[0] if event.bytes.size() > 0 else 4
					event_data["denominator"] = event.bytes[1] if event.bytes.size() > 1 else 4
			events.append(event_data)
		tracks.append({"events": events})

	return {
		"format": midi_parser.header.format,
		"num_tracks": midi_parser.header.tracks,
		"division": midi_parser.header.time_division,
		"tracks": tracks
	}

func get_resolution(sections: Dictionary) -> int:
	# MIDI division can be in ticks per quarter note or SMPTE format
	# For now, assume ticks per quarter note (positive values)
	var division = sections.get("division", 96)
	if division & 0x8000:  # Negative values indicate SMPTE format
		push_error("SMPTE time division not supported")
		return 96
	return division

func get_offset(sections: Dictionary) -> float:
	# MIDI doesn't typically have an offset like .chart files
	# Could be added as a custom meta event in the future
	return 0.0

func get_music_stream(sections: Dictionary) -> String:
	# MIDI files don't contain embedded audio
	# Look for associated audio file in the same directory
	var midi_path = sections.get("path", "")
	if midi_path.is_empty():
		return ""

	var dir = midi_path.get_base_dir()

	# Try common audio file names first
	var common_names = ["song.ogg", "music.ogg", "audio.ogg", "track.ogg", "song.opus", "music.opus", "audio.opus", "track.opus"]
	for name in common_names:
		var full_path = dir + "/" + name
		var global_path = ProjectSettings.globalize_path(full_path)
		if FileAccess.file_exists(global_path):
			return name

	# Fall back to searching for any supported audio file
	var global_dir = ProjectSettings.globalize_path(dir)
	var dir_access = DirAccess.open(global_dir)
	if not dir_access:
		return ""

	# Look for common audio file extensions
	var extensions = ["ogg", "mp3", "wav", "flac", "opus"]
	for ext in extensions:
		dir_access.list_dir_begin()
		var file_name = dir_access.get_next()
		while file_name != "":
			if file_name.get_extension().to_lower() == ext:
				var full_path = dir + "/" + file_name
				var global_path = ProjectSettings.globalize_path(full_path)
				if FileAccess.file_exists(global_path):
					return file_name
			file_name = dir_access.get_next()

	return ""

func get_tempo_events(sections: Dictionary) -> Array:
	var tempo_events = []
	var current_time = 0

	for track in sections.get("tracks", []):
		current_time = 0
		for event in track.get("events", []):
			current_time += event.get("delta_time", 0)
			if event.get("type") == "tempo":
				var tempo_us = event.get("tempo", 500000)  # microseconds per quarter note
				var bpm = 60000000.0 / tempo_us  # Convert to BPM
				tempo_events.append({
					"tick": current_time,
					"bpm": bpm
				})

	# Sort by tick position
	tempo_events.sort_custom(func(a, b): return a.tick < b.tick)
	return tempo_events

func get_notes(sections: Dictionary, instrument: String, resolution: int) -> Array:
	var notes = []
	var current_time = 0
	var active_notes = {}  # note -> start_time

	for track in sections.get("tracks", []):
		current_time = 0
		for event in track.get("events", []):
			current_time += event.get("delta_time", 0)

			if event.get("type") == "note_on" and event.get("param2", 0) > 0:  # velocity > 0
				active_notes[event.param1] = current_time
			elif event.get("type") == "note_off" or (event.get("type") == "note_on" and event.get("param2", 0) == 0):
				if active_notes.has(event.param1):
					var start_time = active_notes[event.param1]
					var length = current_time - start_time

					notes.append({
						"pos": start_time,
						"fret": _midi_note_to_fret(event.param1),
						"length": length,
						"is_hopo": false,  # MIDI doesn't have HOPO markers, default to false
						"is_tap": false    # MIDI doesn't have TAP markers, default to false
					})

					active_notes.erase(event.param1)

	# Sort by position
	notes.sort_custom(func(a, b): return a.pos < b.pos)
	return notes

func _midi_note_to_fret(note: int) -> int:
	# Map MIDI notes to guitar frets
	# Standard guitar tuning: E2(40), A2(45), D3(50), G3(55), B3(59), E4(64)
	# Map to frets 0-4, with 5+ being special notes
	var guitar_notes = [40, 45, 50, 55, 59, 64]  # E, A, D, G, B, E

	for i in range(guitar_notes.size()):
		if note == guitar_notes[i]:
			return i

	# For notes not in standard tuning, find closest string
	var min_diff = 127
	var closest_fret = 0

	for i in range(guitar_notes.size()):
		var diff = abs(note - guitar_notes[i])
		if diff < min_diff:
			min_diff = diff
			closest_fret = i

	return closest_fret

func get_note_times(notes: Array, resolution: int, tempo_events: Array) -> Array:
	var note_times = []
	var division = resolution  # resolution parameter is actually division in MIDI context

	for note in notes:
		var hit_time = ticks_to_time(note.pos, division, tempo_events)
		note_times.append({
			"hit_time": hit_time,
			"lane": note.fret,
			"note_type": 0,  # Regular note
			"is_sustain": note.length > 0,
			"sustain_length": ticks_to_time(note.length, division, tempo_events) if note.length > 0 else 0.0
		})

	return note_times

func get_available_instruments(sections: Dictionary) -> Dictionary:
	# MIDI files typically have one instrument per track
	# For now, return a single "MIDI" instrument
	var instruments = {}

	for track_idx in range(sections.get("tracks", []).size()):
		var track_name = "Track%d" % track_idx
		instruments[track_name] = {
			"name": track_name,
			"difficulty": 0  # Could be enhanced to detect difficulty
		}

	return instruments
